import Foundation

@main struct CollectorChecks {
    static func require(_ condition: @autoclosure () throws -> Bool, _ message: String) throws {
        if try !condition() { throw MonitorError.message("Check failed: " + message) }
    }

    static func main() async throws {
        let fixture = """
        cpu=18.25
        temperature=47.1
        memory_total=8000000000
        memory_used=2100000000
        disk_total=59000000000
        disk_used=24000000000
        uptime=345600
        gpu=57.25
        process=321|python3|12.50|104857600|1.31
        process=322|sshd|0.00|8192|0.00
        """
        let snapshot = try MonitorSnapshot.parse(fixture, host: "fixture.local")
        try require(snapshot.cpu == 18.25 && snapshot.temperature == 47.1, "preserve numeric readings")
        try require(snapshot.gpu == 57.25, "parse GPU utilization")
        try require(snapshot.memoryFraction == 0.2625, "memory uses available memory, not free memory")
        try require(snapshot.diskFraction > 0.40 && snapshot.diskFraction < 0.41, "disk ratio")
        try require(snapshot.processes.count == 2, "parse process rows")
        try require(snapshot.processes[0].pid == 321 && snapshot.processes[0].name == "python3", "preserve process identity")
        try require(snapshot.processes[0].cpuPercent == 12.5 && snapshot.processes[0].memoryUsed == 104_857_600, "parse process CPU and resident memory")
        try require(snapshot.processes[0].memoryPercent == 1.31, "parse process RAM percentage")
        let boundedRows = (1...120).map { "process=\($0)|worker\($0)|0.50|4096|0.01" }.joined(separator: "\n")
        let boundedSnapshot = try MonitorSnapshot.parse(fixture + "\n" + boundedRows, host: "fixture.local")
        try require(boundedSnapshot.processes.count == RemoteProcess.maximumCount, "bound decoded process rows")
        try require(!snapshot.isStale(at: snapshot.sampledAt.addingTimeInterval(44)), "fresh reading")
        try require(snapshot.isStale(at: snapshot.sampledAt.addingTimeInterval(46)), "stale reading")
        var warm = snapshot
        warm.temperature = 79.9
        try require(!warm.hasHighTemperature, "below thermal warning range")
        warm.temperature = 80
        try require(warm.hasHighTemperature, "thermal warning range")
        let withoutTemperature = fixture.replacingOccurrences(of: "temperature=47.1\n", with: "")
        try require(try MonitorSnapshot.parse(withoutTemperature, host: "fixture.local").temperature == nil, "missing sensor stays unavailable")
        let withoutGPU = fixture.replacingOccurrences(of: "gpu=57.25\n", with: "")
        try require(try MonitorSnapshot.parse(withoutGPU, host: "fixture.local").gpu == nil, "missing GPU sensor stays unavailable")
        for bounded in [("gpu=0", 0.0), ("gpu=100", 100.0)] {
            let boundedGPU = try MonitorSnapshot.parse(fixture.replacingOccurrences(of: "gpu=57.25", with: bounded.0), host: "fixture.local")
            try require(boundedGPU.gpu == bounded.1, "accept GPU utilization at valid bounds")
        }
        for invalidGPU in ["gpu=-0.1", "gpu=100.1", "gpu=nan", "gpu=inf", "gpu=unavailable"] {
            let invalidSnapshot = try MonitorSnapshot.parse(fixture.replacingOccurrences(of: "gpu=57.25", with: invalidGPU), host: "fixture.local")
            try require(invalidSnapshot.gpu == nil, "invalid GPU utilization stays unavailable")
        }
        for invalid in ["cpu=nan", fixture.replacingOccurrences(of: "memory_used=2100000000", with: "memory_used=9000000000"), fixture.replacingOccurrences(of: "disk_total=59000000000", with: "disk_total=0")] {
            do { _ = try MonitorSnapshot.parse(invalid, host: "fixture.local"); throw MonitorError.message("Invalid metrics were accepted") }
            catch MonitorError.message(let text) { try require(text != "Invalid metrics were accepted", "reject incomplete and impossible readings") }
        }
        let encoded = try JSONEncoder().encode(snapshot)
        try require(try JSONDecoder().decode(MonitorSnapshot.self, from: encoded) == snapshot, "snapshot round trip")
        var legacyObject = try JSONSerialization.jsonObject(with: encoded) as? [String: Any] ?? [:]
        try require(!legacyObject.isEmpty, "snapshot JSON object exists")
        legacyObject.removeValue(forKey: "processes")
        legacyObject.removeValue(forKey: "gpu")
        let legacyData = try JSONSerialization.data(withJSONObject: legacyObject)
        let legacySnapshot = try JSONDecoder().decode(MonitorSnapshot.self, from: legacyData)
        try require(legacySnapshot.processes.isEmpty, "old cached snapshots decode with an empty process list")
        try require(legacySnapshot.gpu == nil, "old cached snapshots decode without GPU utilization")
        legacyObject["gpu"] = "invalid"
        let invalidGPUCache = try JSONSerialization.data(withJSONObject: legacyObject)
        try require(try JSONDecoder().decode(MonitorSnapshot.self, from: invalidGPUCache).gpu == nil, "invalid cached GPU utilization decodes as unavailable")
        let json = String(decoding: encoded, as: UTF8.self)
        try require(!json.contains("password") && !json.contains("passphrase") && !json.contains("privateKey"), "widget cache has no credentials")

        var connection = Connection(host: "pi5.local", username: "pi", password: "fixture-only")
        try require(connection.validationError == nil, "valid connection")
        connection.host = "-oProxyCommand=bad"
        try require(connection.validationError != nil, "reject option-like hosts")
        connection.host = "2001:db8::1"
        connection.port = 2222
        try require(connection.validationError == nil && connection.knownHostName == "[2001:db8::1]:2222", "IPv6 and alternate port")
        connection.port = 70000
        try require(connection.validationError != nil, "reject invalid port")
        let hostPath = "/Users/example/Library/Application Support/RemoteStatsMonitor/SSH/known_hosts"
        let config = try await ProcessRunner.run("/usr/bin/ssh", arguments: ["-G", "-F", "/dev/null", "-o", "UserKnownHostsFile=" + SSHArguments.quotedPath(hostPath), "fixture.local"])
        try require(config.status == 0 && config.text.contains("userknownhostsfile \(hostPath)"), "OpenSSH accepts the quoted path")
        try require(SSHArguments.quotedPath("a\"b\\c") == "\"a\\\"b\\\\c\"", "escape quotes and backslashes in SSH config paths")

        let output = try await ProcessRunner.run("/usr/bin/printf", arguments: ["collector-ok"])
        try require(output.status == 0 && output.text == "collector-ok", "process captures output")
        let largeOutput = try await ProcessRunner.run("/usr/bin/head", arguments: ["-c", "65537", "/dev/zero"])
        try require(largeOutput.status == 0 && largeOutput.text.utf8.count == 65_537, "drain process output larger than a pipe buffer")
        let sleeper = Task { try await ProcessRunner.run("/bin/sleep", arguments: ["10"]) }
        try await Task.sleep(for: .milliseconds(100))
        sleeper.cancel()
        do { _ = try await sleeper.value; throw MonitorError.message("Cancelled process completed normally") }
        catch is CancellationError { }
        print("Collector checks passed: parsing, process metrics and bounds, backward-compatible cache decoding, stale state, missing sensors, invalid data, credential-free cache, connection validation, process output and cancellation.")
    }
}
