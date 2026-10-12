import Foundation

struct Connection: Codable, Equatable, Identifiable, Sendable {
    enum Authentication: String, Codable, CaseIterable, Sendable {
        case sshConfig = "SSH config"
        case password = "Password"
        case privateKey = "SSH key"
    }

    struct ParsedAddress: Equatable, Sendable {
        let username: String
        let host: String
        let port: Int?
    }

    var id: UUID
    var authentication = Authentication.sshConfig
    var collectGPU = false
    var nickname = ""
    var iconName = "server.rack"
    var password = ""
    var privateKeyPath = ""
    var passphrase = ""

    private var addressValue: String
    private var portTextValue: String

    private static let legacyIdentifier = UUID(uuidString: "00000000-0000-4000-8000-000000000001")!

    var address: String {
        get {
            guard let parsed = Self.parseAddress(addressValue) else { return addressValue }
            let selectedPort = portTextValue.isEmpty ? nil : Int(portTextValue)
            return Self.formatAddress(username: parsed.username, host: parsed.host, port: selectedPort)
        }
        set {
            addressValue = newValue
            if let parsed = Self.parseAddress(newValue) {
                if let port = parsed.port { portTextValue = String(port) }
            }
        }
    }

    var host: String {
        get { Self.parseAddress(addressValue)?.host ?? "" }
        set {
            let username = Self.parseAddress(addressValue)?.username ?? ""
            addressValue = Self.formatAddress(username: username, host: newValue, port: nil)
        }
    }

    var username: String {
        get { Self.parseAddress(addressValue)?.username ?? "" }
        set {
            let host = Self.parseAddress(addressValue)?.host ?? ""
            let port = portTextValue.isEmpty ? nil : Int(portTextValue)
            addressValue = Self.formatAddress(username: newValue, host: host, port: port)
        }
    }

    var portText: String {
        get { portTextValue }
        set { portTextValue = newValue.trimmingCharacters(in: .whitespacesAndNewlines) }
    }

    /// The effective CLI value when no explicit port is entered. SSH itself is
    /// allowed to resolve the actual port from ssh_config when `portText` is blank.
    var port: Int {
        get { Int(portTextValue) ?? 22 }
        set { portTextValue = String(newValue) }
    }

    var usesExplicitPort: Bool { !portTextValue.isEmpty }

    var displayName: String {
        let nickname = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        if !nickname.isEmpty { return nickname }
        let value = address.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? "Server" : value
    }

    init(
        host: String = "",
        username: String = "",
        port: Int = 22,
        authentication: Authentication = .sshConfig,
        password: String = "",
        privateKeyPath: String = "",
        passphrase: String = "",
        id: UUID = UUID(),
        portText: String? = nil,
        nickname: String = "",
        iconName: String = "server.rack"
    ) {
        self.id = id
        self.authentication = authentication
        self.nickname = nickname
        self.iconName = iconName
        self.password = password
        self.privateKeyPath = privateKeyPath
        self.passphrase = passphrase
        self.addressValue = Self.formatAddress(username: username, host: host, port: nil)
        self.portTextValue = portText ?? (port == 22 ? "" : String(port))
    }

    var validationError: String? {
        guard let parsed = Self.parseAddress(addressValue), parsed.host == host else {
            return "Enter a valid SSH address, such as username@server.local."
        }
        if !parsed.username.isEmpty && parsed.username.range(of: #"^[a-zA-Z0-9._-]+$"#, options: .regularExpression) == nil {
            return "Use a valid SSH username without spaces or special characters."
        }
        if !portTextValue.isEmpty {
            guard portTextValue.range(of: #"^[0-9]+$"#, options: .regularExpression) != nil,
                  let parsedPort = Int(portTextValue), (1...65535).contains(parsedPort) else {
                return "Use a port between 1 and 65535."
            }
        }
        if authentication == .password && password.isEmpty { return "Enter your SSH password." }
        if authentication == .privateKey && !FileManager.default.fileExists(atPath: privateKeyPath) {
            return "Choose an SSH private key file on this Mac."
        }
        return nil
    }

    var knownHostName: String { knownHostName(port: port) }

    func knownHostName(port effectivePort: Int) -> String {
        effectivePort == 22 ? host : "[\(host)]:\(effectivePort)"
    }

    static func parseAddress(_ value: String) -> ParsedAddress? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !trimmed.contains(where: \.isWhitespace) else { return nil }

        let pieces = trimmed.split(separator: "@", omittingEmptySubsequences: false)
        guard pieces.count <= 2 else { return nil }
        if pieces.count == 2 && pieces[0].isEmpty { return nil }
        let username = pieces.count == 2 ? String(pieces[0]) : ""
        let rawHost = String(pieces.last ?? "")
        guard !rawHost.isEmpty,
              username.isEmpty || username.range(of: #"^[a-zA-Z0-9._-]+$"#, options: .regularExpression) != nil else { return nil }

        let host: String
        let portText: String?
        if rawHost.first == "[" {
            guard let close = rawHost.firstIndex(of: "]") else { return nil }
            host = String(rawHost[rawHost.index(after: rawHost.startIndex)..<close])
            let suffix = rawHost[rawHost.index(after: close)...]
            if suffix.isEmpty {
                portText = nil
            } else if suffix.first == ":", suffix.count > 1 {
                portText = String(suffix.dropFirst())
            } else {
                return nil
            }
        } else {
            let colonCount = rawHost.filter { $0 == ":" }.count
            if colonCount == 1, let colon = rawHost.lastIndex(of: ":") {
                host = String(rawHost[..<colon])
                portText = String(rawHost[rawHost.index(after: colon)...])
            } else {
                host = rawHost
                portText = nil
            }
        }

        guard !host.isEmpty, !host.hasPrefix("-"),
              host.range(of: #"^[a-zA-Z0-9._:%-]+$"#, options: .regularExpression) != nil else { return nil }
        let port: Int?
        if let portText {
            guard portText.range(of: #"^[0-9]+$"#, options: .regularExpression) != nil,
                  let parsed = Int(portText), (1...65535).contains(parsed) else { return nil }
            port = parsed
        } else {
            port = nil
        }
        return ParsedAddress(username: username, host: host, port: port)
    }

    private static func formatAddress(username: String, host: String, port: Int?) -> String {
        guard !host.isEmpty else { return "" }
        let displayHost = host.contains(":") ? "[\(host)]" : host
        let userPrefix = username.isEmpty ? "" : "\(username)@"
        let portSuffix = port.map { ":\($0)" } ?? ""
        return "\(userPrefix)\(displayHost)\(portSuffix)"
    }

    /// Keep SSH-config port resolution distinct from an explicit override.
    var endpointKey: String { username + "@" + host.lowercased() + "|" + portText }

    func hasSameSettings(as other: Connection) -> Bool {
        endpointKey == other.endpointKey && authentication == other.authentication &&
            password == other.password && privateKeyPath == other.privateKeyPath && passphrase == other.passphrase && collectGPU == other.collectGPU
    }

    private enum CodingKeys: String, CodingKey {
        case collectGPU, id, address, host, username, port, portText, authentication, password, privateKeyPath, passphrase
        case nickname, iconName
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        collectGPU = try values.decodeIfPresent(Bool.self, forKey: .collectGPU) ?? false
        id = try values.decodeIfPresent(UUID.self, forKey: .id) ?? Self.legacyIdentifier
        authentication = try values.decodeIfPresent(Authentication.self, forKey: .authentication) ?? .sshConfig
        nickname = try values.decodeIfPresent(String.self, forKey: .nickname) ?? ""
        iconName = try values.decodeIfPresent(String.self, forKey: .iconName) ?? "server.rack"
        password = try values.decodeIfPresent(String.self, forKey: .password) ?? ""
        privateKeyPath = try values.decodeIfPresent(String.self, forKey: .privateKeyPath) ?? ""
        passphrase = try values.decodeIfPresent(String.self, forKey: .passphrase) ?? ""

        if let address = try values.decodeIfPresent(String.self, forKey: .address) {
            addressValue = address
        } else {
            let host = try values.decodeIfPresent(String.self, forKey: .host) ?? ""
            let username = try values.decodeIfPresent(String.self, forKey: .username) ?? ""
            addressValue = Self.formatAddress(username: username, host: host, port: nil)
        }

        if let text = try values.decodeIfPresent(String.self, forKey: .portText) {
            portTextValue = text
        } else if let port = try values.decodeIfPresent(Int.self, forKey: .port) {
            // Older saved connections always supplied a port. Retain it as an
            // explicit override rather than silently changing the destination.
            portTextValue = String(port)
        } else {
            portTextValue = ""
        }
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(collectGPU, forKey: .collectGPU)
        try values.encode(id, forKey: .id)
        try values.encode(addressValue, forKey: .address)
        try values.encode(host, forKey: .host)
        try values.encode(username, forKey: .username)
        try values.encode(port, forKey: .port)
        try values.encode(portTextValue, forKey: .portText)
        try values.encode(authentication, forKey: .authentication)
        try values.encode(nickname, forKey: .nickname)
        try values.encode(iconName, forKey: .iconName)
        try values.encode(password, forKey: .password)
        try values.encode(privateKeyPath, forKey: .privateKeyPath)
        try values.encode(passphrase, forKey: .passphrase)
    }
}
