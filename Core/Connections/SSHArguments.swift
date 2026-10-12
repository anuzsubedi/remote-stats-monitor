import Foundation

enum SSHArguments {
    struct EffectiveConfiguration: Equatable, Sendable {
        let hostName: String
        let user: String
        let port: Int
    }

    /// `-o` values are parsed again as ssh_config syntax, even though Process
    /// passes each argument separately. Quote paths to preserve spaces.
    static func quotedPath(_ path: String) -> String {
        let escaped = path.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        return "\"\(escaped)\""
    }

    static func targetOptions(for connection: Connection) -> [String] {
        var arguments: [String] = []
        if connection.usesExplicitPort { arguments += ["-p", String(connection.port)] }
        if !connection.username.isEmpty { arguments += ["-l", connection.username] }
        return arguments
    }

    /// Query the user's real OpenSSH configuration. A blank port and username
    /// remain absent from the command line so `Host` settings can supply them.
    static func configurationQuery(for connection: Connection) -> [String] {
        ["-G"] + targetOptions(for: connection) + ["--", connection.host]
    }

    static func parseEffectiveConfiguration(_ output: String) -> EffectiveConfiguration? {
        var values: [String: String] = [:]
        for line in output.split(whereSeparator: \.isNewline) {
            let parts = line.split(maxSplits: 1, whereSeparator: \.isWhitespace)
            guard parts.count == 2 else { continue }
            values[String(parts[0]).lowercased()] = String(parts[1]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        guard let hostName = values["hostname"], !hostName.isEmpty,
              let portValue = values["port"], let port = Int(portValue), (1...65535).contains(port) else { return nil }
        return EffectiveConfiguration(hostName: hostName, user: values["user"] ?? "", port: port)
    }
}
