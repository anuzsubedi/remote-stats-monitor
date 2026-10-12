#if DEBUG
import Foundation

enum DebugSnapshotStore {
    static func read(at directory: URL? = nil) -> [ServerSnapshotRecord] {
        guard let directory = directory ?? (try? SnapshotStore.directory()),
              let data = try? Data(contentsOf: directory.appending(path: "debug-servers.json")),
              let records = try? JSONDecoder().decode([ServerSnapshotRecord].self, from: data) else { return [] }
        return Array(records.filter { $0.snapshot?.isSample == true }.prefix(8))
    }

    static func write(_ records: [ServerSnapshotRecord], at directory: URL? = nil) throws {
        let directory = try directory ?? SnapshotStore.directory()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let samples = Array(records.filter { $0.snapshot?.isSample == true }.prefix(8))
        try JSONEncoder().encode(samples).write(to: directory.appending(path: "debug-servers.json"), options: .atomic)
    }

    static func clear(at directory: URL? = nil) throws {
        let directory = try directory ?? SnapshotStore.directory()
        let file = directory.appending(path: "debug-servers.json")
        if FileManager.default.fileExists(atPath: file.path) { try FileManager.default.removeItem(at: file) }
    }
}
#endif
