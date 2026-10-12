import Foundation
import Darwin

enum SSHAskpass {
    static func handleIfRequested() {
        let environment = ProcessInfo.processInfo.environment
        guard environment["REMOTE_STATS_MONITOR_ASKPASS"] == "1" else { return }
        // Reject direct invocations. Only ssh spawned by this app may request
        // credentials; another same-user process cannot use this as a password CLI.
        let parent = getppid()
        var info = proc_bsdinfo()
        guard let expectedOwner = environment["REMOTE_STATS_MONITOR_OWNER_PID"].flatMap(UInt32.init),
              let connectionID = environment["REMOTE_STATS_MONITOR_CONNECTION_ID"].flatMap(UUID.init(uuidString:)),
              proc_pidinfo(parent, PROC_PIDTBSDINFO, 0, &info, Int32(MemoryLayout<proc_bsdinfo>.size)) > 0,
              info.pbi_ppid == expectedOwner,
              path(of: parent) == "/usr/bin/ssh",
              path(of: pid_t(expectedOwner)) == Bundle.main.executableURL?.path else { exit(1) }
        do {
            guard let connection = try KeychainStore.load(id: connectionID) else { exit(1) }
            let prompt = CommandLine.arguments.dropFirst().joined(separator: " ").lowercased()
            let secret: String
            if prompt.contains("passphrase") { secret = connection.passphrase }
            else if prompt.contains("password") { secret = connection.password }
            else { exit(1) }
            guard !secret.isEmpty else { exit(1) }
            FileHandle.standardOutput.write(Data((secret + "\n").utf8))
            exit(0)
        } catch { exit(1) }
    }

    private static func path(of pid: pid_t) -> String? {
        // libproc's PROC_PIDPATHINFO_MAXSIZE is 4 * MAXPATHLEN (4096).
        var buffer = [CChar](repeating: 0, count: 4096)
        let count = proc_pidpath(pid, &buffer, UInt32(buffer.count))
        guard count > 0 else { return nil }
        return String(decoding: buffer.prefix(Int(count)).map { UInt8(bitPattern: $0) }.prefix(while: { $0 != 0 }), as: UTF8.self)
    }
}
