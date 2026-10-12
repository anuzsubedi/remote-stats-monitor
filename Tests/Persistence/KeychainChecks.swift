import Foundation
import Security

@main struct KeychainChecks {
    static func main() throws {
        let first = Connection(host: "fixture-one.local")
        let second = Connection(host: "fixture-two.local")
        let data = try [first, second].reduce(into: [String: Data]()) { result, connection in
            result[connection.id.uuidString.lowercased()] = try JSONEncoder().encode(connection)
        }
        var enumerationCount = 0
        var secretReadCount = 0
        let loaded = try KeychainStore.loadAll { query, result in
            let query = query as NSDictionary
            if query[kSecMatchLimit] as? String == kSecMatchLimitAll as String {
                guard query[kSecReturnData] == nil else { return errSecParam }
                enumerationCount += 1
                result?.pointee = data.keys.map { [kSecAttrAccount as String: $0] } as CFArray
                return errSecSuccess
            }
            guard query[kSecMatchLimit] as? String == kSecMatchLimitOne as String,
                  let account = query[kSecAttrAccount] as? String,
                  let value = data[account] else { return errSecItemNotFound }
            secretReadCount += 1
            result?.pointee = value as CFData
            return errSecSuccess
        }
        guard Set(loaded.map(\.id)) == Set([first.id, second.id]), enumerationCount == 1, secretReadCount == 2 else {
            throw MonitorError.message("Keychain enumeration failed")
        }
        let empty = try KeychainStore.loadAll { _, _ in errSecItemNotFound }
        guard empty.isEmpty else { throw MonitorError.message("Missing Keychain records should be empty") }
        print("Keychain checks passed: metadata enumeration, individual secret reads, empty storage. No user credentials accessed.")
    }
}
