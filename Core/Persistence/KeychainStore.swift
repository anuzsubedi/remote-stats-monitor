import Foundation
import Security

enum KeychainStore {
    private static let service = "dev.anuz.RemoteStatsMonitor.connection"
    private static let legacyAccount = "primary"

    private static var baseQuery: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: service]
    }

    private static func query(for id: UUID) -> [String: Any] {
        baseQuery.merging([kSecAttrAccount as String: id.uuidString.lowercased()], uniquingKeysWith: { _, new in new })
    }

    private static var legacyQuery: [String: Any] {
        baseQuery.merging([kSecAttrAccount as String: legacyAccount], uniquingKeysWith: { _, new in new })
    }

    /// Reads saved servers and migrates the former single `primary` item to a
    /// UUID-keyed record before removing the old item.
    static func loadAll(copyMatching: (CFDictionary, UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus = SecItemCopyMatching) throws -> [Connection] {
        var request = baseQuery
        request[kSecReturnAttributes as String] = true
        request[kSecMatchLimit as String] = kSecMatchLimitAll
        var result: CFTypeRef?
        let status = copyMatching(request as CFDictionary, &result)
        if status == errSecItemNotFound { return [] }
        guard status == errSecSuccess, let rows = result as? [[String: Any]] else { throw error(status) }

        var connections: [UUID: Connection] = [:]
        var legacyConnection: Connection?
        for row in rows {
            guard let account = row[kSecAttrAccount as String] as? String else { continue }
            // macOS rejects ReturnData + MatchLimitAll for these legacy items.
            // Enumerate metadata, then read each secret with a single-item query.
            var itemQuery = baseQuery
            itemQuery[kSecAttrAccount as String] = account
            itemQuery[kSecReturnData as String] = true
            itemQuery[kSecMatchLimit as String] = kSecMatchLimitOne
            var itemResult: CFTypeRef?
            let itemStatus = copyMatching(itemQuery as CFDictionary, &itemResult)
            guard itemStatus == errSecSuccess, let data = itemResult as? Data else { throw error(itemStatus) }
            let connection = try JSONDecoder().decode(Connection.self, from: data)
            if account == legacyAccount {
                legacyConnection = connection
            } else {
                connections[connection.id] = connection
            }
        }

        if let legacyConnection {
            let migratedConnection = connections[legacyConnection.id] ?? legacyConnection
            if connections[legacyConnection.id] == nil { connections[legacyConnection.id] = migratedConnection }
            if rows.contains(where: { ($0[kSecAttrAccount as String] as? String) == legacyAccount }) {
                try save(migratedConnection)
            }
            try deleteLegacy()
        }
        return connections.values.sorted { $0.id.uuidString < $1.id.uuidString }
    }

    /// Kept for the original single-server API. On upgraded installs this
    /// returns the first saved server after performing the legacy migration.
    static func load() throws -> Connection? {
        try loadAll().first
    }

    static func load(id: UUID) throws -> Connection? {
        var request = query(for: id)
        request[kSecReturnData as String] = true
        request[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(request as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = result as? Data else { throw error(status) }
        return try JSONDecoder().decode(Connection.self, from: data)
    }

    static func save(_ connection: Connection) throws {
        let data = try JSONEncoder().encode(connection)
        let itemQuery = query(for: connection.id)
        // The same signed app executable handles SSH askpass requests. Default
        // Keychain access control therefore grants it access without a second ACL.
        let attributes: [String: Any] = [kSecValueData as String: data,
                                         kSecAttrLabel as String: "Remote Stats Monitor — \(connection.displayName)"]
        let updated = SecItemUpdate(itemQuery as CFDictionary, attributes as CFDictionary)
        if updated == errSecItemNotFound {
            let status = SecItemAdd(itemQuery.merging(attributes, uniquingKeysWith: { _, new in new }) as CFDictionary, nil)
            guard status == errSecSuccess else { throw error(status) }
        } else if updated != errSecSuccess {
            throw error(updated)
        }
    }

    static func delete(id: UUID) throws {
        let status = SecItemDelete(query(for: id) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { throw error(status) }
    }

    /// Compatibility helper for callers that still remove the old singleton.
    static func delete() throws { try deleteLegacy() }

    private static func deleteLegacy() throws {
        let status = SecItemDelete(legacyQuery as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { throw error(status) }
    }

    private static func error(_ status: OSStatus) -> MonitorError {
        .message("Keychain: \(SecCopyErrorMessageString(status, nil) as String? ?? "Unable to access saved credentials.")")
    }
}
