import Foundation

@main struct ConnectionChecks {
    static func require(_ condition: @autoclosure () throws -> Bool, _ message: String) throws {
        if try !condition() { throw MonitorError.message("Check failed: " + message) }
    }

    static func main() async throws {
        var connection = Connection(host: "pi5.local", username: "pi", password: "fixture-only")
        try require(connection.authentication == .sshConfig, "SSH config is the default authentication mode")
        try require(connection.validationError == nil && !connection.usesExplicitPort, "blank port uses SSH config")

        try require(!connection.collectGPU, "GPU collection defaults off")
        try require(connection.nickname.isEmpty && connection.iconName == "server.rack", "server identity defaults to address and rack icon")
        let legacyGPU = Data(#"{"host":"pi.local"}"#.utf8)
        let migratedConnection = try JSONDecoder().decode(Connection.self, from: legacyGPU)
        try require(!migratedConnection.collectGPU, "existing connections default GPU off")
        try require(migratedConnection.nickname.isEmpty && migratedConnection.iconName == "server.rack", "existing connections default identity fields")
        connection.collectGPU = true
        connection.nickname = "  Office Pi  "
        connection.iconName = "desktopcomputer"
        try require(try JSONDecoder().decode(Connection.self, from: JSONEncoder().encode(connection)).collectGPU, "GPU opt-in persists")

        var duplicate = connection
        duplicate.id = UUID()
        try require(connection.hasSameSettings(as: duplicate), "identical credentials ignore UUID for migration")
        duplicate.nickname = "Different name"
        duplicate.iconName = "externaldrive"
        try require(connection.hasSameSettings(as: duplicate), "identity metadata does not change credential deduplication")
        duplicate.address = "  pi@PI5.local  "
        try require(connection.hasSameSettings(as: duplicate), "equivalent address spelling merges without comparing raw input")
        duplicate.password = "different-fixture"
        try require(!connection.hasSameSettings(as: duplicate), "migration never merges different credentials")
        duplicate = connection
        duplicate.portText = "22"
        try require(connection.endpointKey != duplicate.endpointKey, "implicit SSH config port remains distinct from explicit port")
        connection.portText = "2222"
        try require(connection.port == 2222 && connection.knownHostName == "[pi5.local]:2222", "explicit port is retained")
        let encoded = try JSONEncoder().encode(connection)
        try require(try JSONDecoder().decode(Connection.self, from: encoded) == connection, "connection round trip preserves ID and explicit port")

        connection.address = "admin@server.local:2202"
        try require(connection.username == "admin" && connection.host == "server.local" && connection.port == 2202,
                    "address parses username, hostname, and optional port")
        try require(connection.displayName == "Office Pi", "display label trims and prefers nickname")
        connection.nickname = "  \n "
        try require(connection.displayName == "admin@server.local:2202", "blank nickname falls back to SSH address")
        connection.address = "monitor@another.local"
        try require(connection.portText == "2202" && connection.address == "monitor@another.local:2202",
                    "editing the address preserves the separate explicit port")

        connection.host = "2001:db8::1"
        connection.username = "pi"
        connection.port = 2222
        try require(connection.validationError == nil && connection.address == "pi@[2001:db8::1]:2222" &&
                    connection.knownHostName == "[2001:db8::1]:2222", "IPv6 address and alternate port")
        connection.port = 70000
        try require(connection.validationError != nil, "reject invalid ports")
        try require(Connection.parseAddress("-oProxyCommand=bad") == nil, "reject option-like addresses")
        try require(Connection.parseAddress("pi@server.local:0") == nil, "reject invalid embedded ports")
        try require(Connection.parseAddress("pi@[2001:db8::1]:2200")?.host == "2001:db8::1", "parse bracketed IPv6 with port")

        let legacyJSON = #"{"host":"old.local","username":"olduser","port":22,"authentication":"Password","password":"legacy-secret"}"#
        let legacy = try JSONDecoder().decode(Connection.self, from: Data(legacyJSON.utf8))
        let legacyAgain = try JSONDecoder().decode(Connection.self, from: Data(legacyJSON.utf8))
        try require(legacy.id == legacyAgain.id && legacy.usesExplicitPort && legacy.port == 22,
                    "legacy singleton connections get a stable migration ID and keep their port")

        let fixture = try await ProcessRunner.run("/usr/bin/ssh", arguments: [
            "-G", "-F", "/dev/null", "-o", "User=fixture-user", "-o", "Port=2222", "--", "fixture.local"
        ])
        let config = SSHArguments.parseEffectiveConfiguration(fixture.text)
        try require(fixture.status == 0 && config == .init(hostName: "fixture.local", user: "fixture-user", port: 2222),
                    "parse effective OpenSSH config output")
        try require(SSHArguments.configurationQuery(for: Connection(host: "alias.local")) == ["-G", "--", "alias.local"],
                    "blank address fields leave SSH config values available")
        try require(SSHArguments.quotedPath("a\"b\\c") == "\"a\\\"b\\\\c\"", "escape paths in ssh_config options")

        print("Connection checks passed: default auth, identity migration and persistence, address parsing, ports, IPv6, migration IDs, Codable, and OpenSSH config parsing.")
    }
}
