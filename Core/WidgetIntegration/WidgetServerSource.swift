import Foundation

enum WidgetServerSource {
    static func servers() -> [ServerDescriptor] {
        var servers = SnapshotStore.servers()
        #if DEBUG
        servers += DebugSnapshotStore.read().map(\.server)
        #endif
        return servers.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    static func record(for id: UUID) -> ServerSnapshotRecord? {
        #if DEBUG
        if let sample = DebugSnapshotStore.read().first(where: { $0.server.id == id }) { return sample }
        #endif
        return SnapshotStore.record(for: id)
    }
}
