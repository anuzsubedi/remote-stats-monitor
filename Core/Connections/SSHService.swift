import Foundation

actor SSHService {
    private let directory: URL
    private let knownHosts: URL
    private let controlPath: URL

    init() {
        directory = URL.applicationSupportDirectory.appending(path: "RemoteStatsMonitor/SSH", directoryHint: .isDirectory)
        knownHosts = directory.appending(path: "known_hosts")
        // Keep socket paths comfortably below the Unix socket path limit.
        controlPath = URL.temporaryDirectory.appending(path: "pim-\(UUID().uuidString.prefix(8))")
    }

    func proposedKey(for connection: Connection) async throws -> HostKeyProposal? {
        try prepareDirectory()
        let configuration = try await effectiveConfiguration(for: connection)
        let hostKeyName = connection.knownHostName(port: configuration.port)
        if FileManager.default.fileExists(atPath: knownHosts.path) {
            let existing = try await ProcessRunner.run("/usr/bin/ssh-keygen", arguments: ["-F", hostKeyName, "-f", knownHosts.path])
            if existing.status == 0 { return nil }
            guard existing.status == 1 else { throw MonitorError.message("Could not read the saved SSH host keys.") }
        }

        // Use OpenSSH itself for host-key discovery so HostName, Port, ProxyJump,
        // and other supported ssh_config routing settings are applied. The key
        // goes to a temporary file, and no credentials are offered until the user
        // verifies the fingerprint and explicitly trusts it.
        let candidateHosts = directory.appending(path: "candidate-hosts-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: candidateHosts) }
        var scanArguments = ["-T"] + SSHArguments.targetOptions(for: connection)
        scanArguments += ["-o", "ConnectTimeout=8", "-o", "ConnectionAttempts=1",
                          "-o", "BatchMode=yes", "-o", "PreferredAuthentications=none",
                          "-o", "PubkeyAuthentication=no", "-o", "PasswordAuthentication=no",
                          "-o", "KbdInteractiveAuthentication=no", "-o", "UpdateHostKeys=no",
                          "-o", "ControlMaster=no", "-o", "ControlPath=none",
                          "-o", "ClearAllForwardings=yes", "-o", "RemoteCommand=none",
                          "-o", "RequestTTY=no", "-o", "ForkAfterAuthentication=no",
                          "-o", "KnownHostsCommand=none", "-o", "HashKnownHosts=no",
                          "-o", "StrictHostKeyChecking=accept-new",
                          "-o", "HostKeyAlias=\(hostKeyName)",
                          "-o", "UserKnownHostsFile=\(SSHArguments.quotedPath(candidateHosts.path))",
                          "-o", "GlobalKnownHostsFile=/dev/null", "--", connection.host, "true"]
        let scanned = try await ProcessRunner.run("/usr/bin/ssh", arguments: scanArguments)
        guard let scannedData = try? Data(contentsOf: candidateHosts),
              let scannedText = String(data: scannedData, encoding: .utf8),
              let line = scannedText.split(whereSeparator: \.isNewline).first(where: {
                  !$0.hasPrefix("#") && $0.split(separator: " ").first == Substring(hostKeyName)
              }) else {
            let detail = scanned.error.isEmpty ? scanned.text : scanned.error
            throw Self.friendlyError(detail.isEmpty ? "Could not retrieve the server's SSH host key." : detail)
        }
        let parts = line.split(separator: " ")
        guard parts.count >= 3,
              parts[1].hasPrefix("ssh-") || parts[1].hasPrefix("ecdsa-") || parts[1].hasPrefix("sk-") else {
            throw MonitorError.message("The server did not provide a supported SSH host key.")
        }
        let trustedLine = "\(hostKeyName) \(parts[1]) \(parts[2])\n"
        let candidate = directory.appending(path: "candidate-\(UUID().uuidString).pub")
        try Data(trustedLine.utf8).write(to: candidate)
        defer { try? FileManager.default.removeItem(at: candidate) }
        let fingerprint = try await ProcessRunner.run("/usr/bin/ssh-keygen", arguments: ["-l", "-E", "sha256", "-f", candidate.path])
        guard fingerprint.status == 0 else { throw MonitorError.message("Could not read the server's host key fingerprint.") }
        return HostKeyProposal(line: trustedLine, fingerprint: fingerprint.text.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    func trust(_ proposal: HostKeyProposal) throws {
        try prepareDirectory()
        var data = (try? Data(contentsOf: knownHosts)) ?? Data()
        let existingLines = String(decoding: data, as: UTF8.self).split(whereSeparator: \.isNewline)
        let line = proposal.line.trimmingCharacters(in: .newlines)
        if existingLines.contains(Substring(line)) { return }
        if !data.isEmpty, data.last != 0x0A { data.append(0x0A) }
        data.append(Data((line + "\n").utf8))
        try data.write(to: knownHosts, options: .atomic)
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: knownHosts.path)
    }

    func collect(_ connection: Connection, helperURL: URL) async throws -> MonitorSnapshot {
        try prepareDirectory()
        let configuration = try await effectiveConfiguration(for: connection)
        let hostKeyName = connection.knownHostName(port: configuration.port)
        var arguments = ["-T"] + SSHArguments.targetOptions(for: connection)
        arguments += ["-o", "ConnectTimeout=8", "-o", "ConnectionAttempts=1",
                         "-o", "ServerAliveInterval=5", "-o", "ServerAliveCountMax=1",
                         "-o", "NumberOfPasswordPrompts=1", "-o", "StrictHostKeyChecking=yes",
                         "-o", "ClearAllForwardings=yes", "-o", "RemoteCommand=none",
                         "-o", "RequestTTY=no", "-o", "ForkAfterAuthentication=no",
                         "-o", "HostKeyAlias=\(hostKeyName)", "-o", "KnownHostsCommand=none",
                         "-o", "UserKnownHostsFile=\(SSHArguments.quotedPath(knownHosts.path))", "-o", "GlobalKnownHostsFile=/dev/null",
                         "-o", "ControlMaster=auto", "-o", "ControlPersist=30",
                         "-o", "ControlPath=\(SSHArguments.quotedPath(controlPath.path))"]
        if connection.authentication == .privateKey {
            arguments += ["-i", connection.privateKeyPath, "-o", "PubkeyAuthentication=yes",
                          "-o", "IdentitiesOnly=yes", "-o", "PreferredAuthentications=publickey"]
        } else if connection.authentication == .password {
            arguments += ["-o", "PubkeyAuthentication=no", "-o", "PasswordAuthentication=yes",
                          "-o", "KbdInteractiveAuthentication=yes",
                          "-o", "PreferredAuthentications=password,keyboard-interactive"]
        }
        arguments += ["--", connection.host, "collect_gpu=\(connection.collectGPU ? 1 : 0)\n" + Self.metricsCommand]
        var environment = ProcessInfo.processInfo.environment
        environment["SSH_ASKPASS"] = helperURL.path
        environment["SSH_ASKPASS_REQUIRE"] = "force"
        environment["DISPLAY"] = ":0"
        environment["REMOTE_STATS_MONITOR_ASKPASS"] = "1"
        environment["REMOTE_STATS_MONITOR_OWNER_PID"] = String(ProcessInfo.processInfo.processIdentifier)
        environment["REMOTE_STATS_MONITOR_CONNECTION_ID"] = connection.id.uuidString
        let result = try await ProcessRunner.run("/usr/bin/ssh", arguments: arguments, environment: environment)
        guard result.status == 0 else { throw Self.friendlyError(result.error) }
        return try MonitorSnapshot.parse(result.text, host: connection.displayName)
    }

    func close(_ connection: Connection) async {
        _ = try? await ProcessRunner.run("/usr/bin/ssh", arguments: ["-S", controlPath.path, "-O", "exit"] + SSHArguments.targetOptions(for: connection) + ["--", connection.host])
    }

    private func prepareDirectory() throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: directory.path)
    }

    private func effectiveConfiguration(for connection: Connection) async throws -> SSHArguments.EffectiveConfiguration {
        let result = try await ProcessRunner.run("/usr/bin/ssh", arguments: SSHArguments.configurationQuery(for: connection))
        guard result.status == 0,
              let configuration = SSHArguments.parseEffectiveConfiguration(result.text) else {
            let detail = result.error.isEmpty ? result.text : result.error
            throw Self.friendlyError(detail.isEmpty ? "Could not read the effective SSH configuration." : detail)
        }
        return configuration
    }

    private static func friendlyError(_ error: String) -> MonitorError {
        if error.contains("REMOTE HOST IDENTIFICATION HAS CHANGED") { return .message("The server's host key changed. Connection stopped. Verify the server's identity before removing its saved entry in known_hosts.") }
        if error.contains("Permission denied") { return .authentication }
        if error.contains("Could not resolve hostname") { return .message("This hostname could not be found. Check the address and your network.") }
        if error.contains("Connection refused") { return .message("The server refused the connection. Check that SSH is enabled and the port is correct.") }
        if error.contains("timed out") || error.contains("No route to host") { return .message("The server is unreachable. Check that it is on and connected to your network.") }
        return .message(error.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "SSH connection failed. Review your connection details." : error.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    // Read-only Linux metrics; no agent, package installation, or sudo required.
    static let metricsCommand = GPUCollector.shellFunction + #"""
    export LC_ALL=C

    process_snapshot() {
        for stat_file in /proc/[0-9]*/stat; do
            [ -r "$stat_file" ] || continue
            line=
            IFS= read -r line < "$stat_file" 2>/dev/null || continue
            pid=${stat_file#/proc/}
            pid=${pid%/stat}
            rest=${line##*) }
            set -- $rest
            [ "$#" -ge 20 ] || continue
            utime=${12}
            stime=${13}
            starttime=${20}

            statm_file="/proc/$pid/statm"
            comm_file="/proc/$pid/comm"
            [ -r "$statm_file" ] && [ -r "$comm_file" ] || continue
            read -r _ resident_pages _ < "$statm_file" 2>/dev/null || continue
            name=
            IFS= read -r name < "$comm_file" 2>/dev/null || continue

            valid=1
            for number in "$pid" "$utime" "$stime" "$starttime" "$resident_pages"; do
                case "$number" in ''|*[!0-9]*) valid=0;; esac
            done
            [ "$valid" -eq 1 ] || continue

            # Keep the line protocol bounded and prevent process names from
            # injecting fields or extra collector records.
            case "$name" in ''|*[!A-Za-z0-9_.:/+@=\ -]*) name=process;; esac
            printf '%s|%s|%s|%s|%s|%s\n' "$pid" "$utime" "$stime" "$starttime" "$resident_pages" "$name"
        done
    }

    temp_dir=$(mktemp -d "${TMPDIR:-/tmp}/remote-stats-monitor.XXXXXX" 2>/dev/null) || temp_dir=
    if [ -n "$temp_dir" ]; then
        trap 'rm -rf "$temp_dir"' 0 HUP INT TERM
        process_snapshot > "$temp_dir/before"
        if [ "$collect_gpu" = 1 ] && command -v python3 >/dev/null 2>&1; then gpu_sample capture "$temp_dir/gpu-before"; fi
    fi
    read -r before_uptime _ < /proc/uptime
    first=$(head -n 1 /proc/stat)
    sleep 0.4
    second=$(head -n 1 /proc/stat)
    if [ -n "$temp_dir" ]; then process_snapshot > "$temp_dir/after"; fi
    read -r after_uptime _ < /proc/uptime
    printf '%s\n%s\n' "$first" "$second" | awk 'NR==1 {for(i=2;i<=9;i++) a+=$i; b=$5+$6} NR==2 {for(i=2;i<=9;i++) c+=$i; d=$5+$6; if(c>a) printf "cpu=%.2f\n", 100*(1-(d-b)/(c-a)); else print "cpu=0"}'
    awk '/^MemTotal:/ {total=$2} /^MemAvailable:/ {available=$2} END {printf "memory_total=%.0f\nmemory_used=%.0f\n", total*1024, (total-available)*1024}' /proc/meminfo
    if [ -r /sys/class/thermal/thermal_zone0/temp ]; then awk '{printf "temperature=%.1f\n", $1/1000}' /sys/class/thermal/thermal_zone0/temp; fi
    df -Pk / | awk 'NR==2 {printf "disk_total=%.0f\ndisk_used=%.0f\n", $2*1024, $3*1024}'
    awk '{print "uptime=" $1}' /proc/uptime

    if [ "$collect_gpu" = 1 ]; then
    gpu_readings=
    if [ -n "$temp_dir" ] && [ -r "$temp_dir/gpu-before" ]; then
        gpu_readings=$(gpu_sample sample "$temp_dir/gpu-before")
        gpu_readings="${gpu_readings}
    "
    fi
    for gpu_sensor in /sys/class/drm/card*/device/gpu_busy_percent; do
        [ -r "$gpu_sensor" ] || continue
        gpu_reading=
        IFS= read -r gpu_reading < "$gpu_sensor" 2>/dev/null || continue
        case "$gpu_reading" in ''|*[!0-9]*) continue;; esac
        gpu_readings="${gpu_readings}${gpu_reading}
    "
    done
    nvidia_readings=
    if command -v timeout >/dev/null 2>&1 && command -v nvidia-smi >/dev/null 2>&1; then
        nvidia_readings=$(timeout -s KILL 1 nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null) || nvidia_readings=
    fi
    gpu_max=$(printf '%s\n%s\n' "$gpu_readings" "$nvidia_readings" | awk '
        /^[0-9]+([.][0-9]+)?$/ {
            value = $0 + 0
            if (value >= 0 && value <= 100 && (!found || value > maximum)) {
                maximum = value
                found = 1
            }
        }
        END { if (found) printf "%.2f", maximum }
    ')
    if [ -n "$gpu_max" ]; then printf 'gpu=%s\n' "$gpu_max"; fi
    fi

    if [ -n "$temp_dir" ]; then
        clock_ticks=$(getconf CLK_TCK 2>/dev/null)
        cpu_count=$(getconf _NPROCESSORS_ONLN 2>/dev/null)
        page_size=$(getconf PAGE_SIZE 2>/dev/null)
        memory_total=$(awk '/^MemTotal:/ {printf "%.0f", $2 * 1024; exit}' /proc/meminfo)
        valid=1
        for number in "$clock_ticks" "$cpu_count" "$page_size" "$memory_total"; do
            case "$number" in ''|*[!0-9]*) valid=0;; esac
        done
        case "$clock_ticks:$cpu_count:$page_size:$memory_total" in *::* ) valid=0;; esac
        if [ "${valid:-0}" -eq 1 ] && [ "$clock_ticks" -gt 0 ] && [ "$cpu_count" -gt 0 ] && [ "$page_size" -gt 0 ] && [ "$memory_total" -gt 0 ]; then
            elapsed=$(awk -v before="$before_uptime" -v after="$after_uptime" 'BEGIN {print after-before}')
            awk -F '|' -v elapsed="$elapsed" -v ticks="$clock_ticks" -v cores="$cpu_count" -v page_size="$page_size" -v memory_total="$memory_total" '
                function insert_cpu(pid, record, cpu, rss,     i, position) {
                    position = cpu_count + 1
                    for (i = 1; i <= cpu_count; i++) {
                        if (cpu > cpu_values[i] || (cpu == cpu_values[i] && rss > cpu_rss[i])) { position = i; break }
                    }
                    if (position > 50) return
                    if (cpu_count < 50) cpu_count++
                    for (i = cpu_count; i > position; i--) {
                        cpu_pids[i] = cpu_pids[i - 1]
                        cpu_records[i] = cpu_records[i - 1]
                        cpu_values[i] = cpu_values[i - 1]
                        cpu_rss[i] = cpu_rss[i - 1]
                    }
                    cpu_pids[position] = pid
                    cpu_records[position] = record
                    cpu_values[position] = cpu
                    cpu_rss[position] = rss
                }
                function insert_memory(pid, record, rss, cpu,     i, position) {
                    position = memory_count + 1
                    for (i = 1; i <= memory_count; i++) {
                        if (rss > memory_values[i] || (rss == memory_values[i] && cpu > memory_cpu[i])) { position = i; break }
                    }
                    if (position > 50) return
                    if (memory_count < 50) memory_count++
                    for (i = memory_count; i > position; i--) {
                        memory_pids[i] = memory_pids[i - 1]
                        memory_records[i] = memory_records[i - 1]
                        memory_values[i] = memory_values[i - 1]
                        memory_cpu[i] = memory_cpu[i - 1]
                    }
                    memory_pids[position] = pid
                    memory_records[position] = record
                    memory_values[position] = rss
                    memory_cpu[position] = cpu
                }
                FNR == NR {
                    old_user[$1] = $2
                    old_system[$1] = $3
                    old_start[$1] = $4
                    next
                }
                {
                    pid = $1
                    if (!(pid in old_user) || old_start[pid] != $4 || elapsed <= 0) next
                    delta = ($2 + $3) - (old_user[pid] + old_system[pid])
                    if (delta < 0) next
                    cpu = 100 * delta / (elapsed * ticks * cores)
                    if (cpu > 100) cpu = 100
                    rss = $5 * page_size
                    memory = 100 * rss / memory_total
                    if (memory > 100) memory = 100
                    record = sprintf("%s|%s|%.2f|%.0f|%.2f", pid, $6, cpu, rss, memory)
                    insert_cpu(pid, record, cpu, rss)
                    insert_memory(pid, record, rss, cpu)
                }
                END {
                    for (i = 1; i <= cpu_count; i++) {
                        if (!emitted[cpu_pids[i]]++) printf "process=%s\n", cpu_records[i]
                    }
                    for (i = 1; i <= memory_count; i++) {
                        if (!emitted[memory_pids[i]]++) printf "process=%s\n", memory_records[i]
                    }
                }
            ' "$temp_dir/before" "$temp_dir/after"
        fi
    fi
    """#
}
