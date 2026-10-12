import Foundation

struct ServerDescriptor: Codable, Hashable, Identifiable, Sendable {
    let id: UUID
    var name: String

    init(id: UUID, name: String) {
        self.id = id
        self.name = name
    }
}

struct ServerSnapshotRecord: Codable, Equatable, Sendable {
    var server: ServerDescriptor
    var snapshot: MonitorSnapshot?
}

enum SnapshotStore {
    static var group: String {
        Bundle.main.object(forInfoDictionaryKey: "RemoteStatsMonitorAppGroupIdentifier") as? String ?? "local.dev.anuz.RemoteStatsMonitor"
    }
    static let widgetKind = "RemoteStatsMonitorWidget"

    private static let legacyFileName = "snapshot.json"
    private static let storeFileName = "snapshot-store.json"

    static func directory() throws -> URL {
        if let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group) {
            return groupURL.appending(path: "RemoteStatsMonitor", directoryHint: .isDirectory)
        }
        throw MonitorError.message("The shared widget container is unavailable. Check that the app and widget use the same Apple signing team.")
    }

    /// Creates an isolated store at an injected directory. Used by persistence checks and previews.
    static func store(at directoryURL: URL) -> Store {
        Store(directoryURL: directoryURL)
    }

    /// The pre-multi-server snapshot path, retained for callers and existing installs.
    static func fileURL() throws -> URL { try directory().appending(path: legacyFileName) }

    private static func defaultStore() throws -> Store {
        Store(directoryURL: try directory())
    }

    static func servers() -> [ServerDescriptor] {
        guard let store = try? defaultStore() else { return [] }
        return store.servers()
    }

    static func descriptor(for id: UUID) -> ServerDescriptor? {
        guard let store = try? defaultStore() else { return nil }
        return store.descriptor(for: id)
    }

    static func reconcile(_ servers: [ServerDescriptor], aliases: [UUID: UUID] = [:]) throws {
        try defaultStore().reconcile(servers, aliases: aliases)
    }

    static func upsertServer(id: UUID, name: String) throws {
        try defaultStore().upsertServer(id: id, name: name)
    }

    static func write(_ snapshot: MonitorSnapshot, for id: UUID, name: String) throws {
        try defaultStore().write(snapshot, for: id, name: name)
    }

    static func read(for id: UUID) -> MonitorSnapshot? {
        guard let store = try? defaultStore() else { return nil }
        return store.read(for: id)
    }

    static func record(for id: UUID) -> ServerSnapshotRecord? {
        guard let store = try? defaultStore() else { return nil }
        return store.record(for: id)
    }

    static func select(id: UUID) throws {
        try defaultStore().select(id: id)
    }

    static func selectedRecord() -> ServerSnapshotRecord? {
        guard let store = try? defaultStore() else { return nil }
        return store.selectedRecord()
    }

    static func readSelected() -> MonitorSnapshot? {
        guard let store = try? defaultStore() else { return nil }
        return store.readSelected()
    }

    /// Compatibility API: reads the selected server, or the legacy single snapshot on older installs.
    static func read() -> MonitorSnapshot? { readSelected() }

    /// Compatibility API for older callers. New app code should include the stable connection UUID.
    static func write(_ snapshot: MonitorSnapshot) throws {
        try defaultStore().writeLegacySnapshot(snapshot)
    }

    static func remove(id: UUID) throws {
        try defaultStore().remove(id: id)
    }

    /// Compatibility API that clears all cached server readings and the legacy snapshot.
    static func clear() throws {
        try defaultStore().clear()
    }

    struct Store: Sendable {
        private let directoryURL: URL

        private struct StoredServer: Codable, Sendable {
            var server: ServerDescriptor
            var snapshot: MonitorSnapshot?
            var lastSelectedAt: Date?
        }

        private struct StoreState: Codable, Sendable {
            var aliases: [String: String]?
            var version = 1
            var selectedServerID: UUID?
            var servers: [String: StoredServer] = [:]
        }

        fileprivate init(directoryURL: URL) {
            self.directoryURL = directoryURL
        }

        func servers() -> [ServerDescriptor] {
            guard let state = try? readState() else { return [] }
            return state.servers.values.map(\.server).sorted {
                let order = $0.name.localizedStandardCompare($1.name)
                return order == .orderedSame ? $0.id.uuidString < $1.id.uuidString : order == .orderedAscending
            }
        }

        func descriptor(for id: UUID) -> ServerDescriptor? {
            guard let state = try? readState() else { return nil }
            return state.servers[id.uuidString]?.server
        }

        /// Credential storage is authoritative. Preserve redirects for widgets pinned to merged IDs.
        func reconcile(_ servers: [ServerDescriptor], aliases: [UUID: UUID] = [:]) throws {
            try updateState { state in
                for (old, new) in aliases {
                    state.aliases = state.aliases ?? [:]
                    state.aliases?[old.uuidString] = new.uuidString
                    if let previous = state.servers[old.uuidString],
                       (previous.snapshot?.sampledAt ?? .distantPast) > (state.servers[new.uuidString]?.snapshot?.sampledAt ?? .distantPast) {
                        state.servers[new.uuidString] = previous
                    }
                    if state.selectedServerID == old { state.selectedServerID = new }
                }
                for (old, target) in state.aliases ?? [:] {
                    var resolved = target
                    var visited = Set<String>()
                    while let next = state.aliases?[resolved], visited.insert(resolved).inserted { resolved = next }
                    state.aliases?[old] = resolved
                }
                let valid = Set(servers.map { $0.id.uuidString })
                state.servers = state.servers.filter { valid.contains($0.key) }
                state.aliases = state.aliases?.filter { valid.contains($0.value) && !valid.contains($0.key) }
                for server in servers {
                    var record = state.servers[server.id.uuidString] ?? StoredServer(server: server, snapshot: nil, lastSelectedAt: nil)
                    record.server = server
                    state.servers[server.id.uuidString] = record
                }
                if let selected = state.selectedServerID, !valid.contains(selected.uuidString) { state.selectedServerID = nil }
            }
            if servers.isEmpty, FileManager.default.fileExists(atPath: legacyFileURL().path) {
                try FileManager.default.removeItem(at: legacyFileURL())
            }
        }

        /// Adds or updates a server's widget label before its first successful collection.
        func upsertServer(id: UUID, name: String) throws {
            try updateState { state in
                let key = id.uuidString
                var record = state.servers[key] ?? StoredServer(server: .init(id: id, name: name), snapshot: nil, lastSelectedAt: nil)
                record.server.name = Self.normalizedName(name)
                state.servers[key] = record
            }
        }

        /// Stores one server's latest reading without changing the app's current server selection.
        func write(_ snapshot: MonitorSnapshot, for id: UUID, name: String) throws {
            // Preview fixtures must never become live widget data.
            guard !snapshot.isSample else { return }
            try updateState { state in
                let key = id.uuidString
                var record = state.servers[key] ?? StoredServer(server: .init(id: id, name: name), snapshot: nil, lastSelectedAt: nil)
                record.server.name = Self.normalizedName(name)
                record.snapshot = snapshot
                state.servers[key] = record
            }
        }

        func read(for id: UUID) -> MonitorSnapshot? {
            guard let state = try? readState() else { return nil }
            return state.servers[id.uuidString]?.snapshot
        }

        func record(for id: UUID) -> ServerSnapshotRecord? {
            guard let state = try? readState(), let stored = state.servers[state.aliases?[id.uuidString] ?? id.uuidString] else { return nil }
            return .init(server: stored.server, snapshot: stored.snapshot)
        }

        /// Marks the server selected in the app so unconfigured widgets follow it.
        func select(id: UUID) throws {
            try updateState { state in
                guard var record = state.servers[id.uuidString] else { return }
                record.lastSelectedAt = .now
                state.servers[id.uuidString] = record
                state.selectedServerID = id
            }
        }

        func selectedRecord() -> ServerSnapshotRecord? {
            guard let state = try? readState(), let stored = selectedServer(in: state) else { return nil }
            return .init(server: stored.server, snapshot: stored.snapshot)
        }

        func readSelected() -> MonitorSnapshot? {
            if let record = selectedRecord() { return record.snapshot }
            return readLegacySnapshot()
        }

        /// Writes the original single-snapshot format for older callers.
        func writeLegacySnapshot(_ snapshot: MonitorSnapshot) throws {
            guard !snapshot.isSample else { return }
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            try JSONEncoder().encode(snapshot).write(to: legacyFileURL(), options: .atomic)
        }

        func remove(id: UUID) throws {
            try updateState { state in
                state.servers.removeValue(forKey: id.uuidString)
                if state.selectedServerID == id {
                    state.selectedServerID = nil
                    if let next = mostRecentlySelected(in: state) {
                        state.selectedServerID = next.server.id
                    }
                }
            }

            // Avoid reviving a removed server from the old single-snapshot cache.
            if servers().isEmpty, FileManager.default.fileExists(atPath: legacyFileURL().path) {
                try FileManager.default.removeItem(at: legacyFileURL())
            }
        }

        /// Clears all cached server readings and the legacy snapshot.
        func clear() throws {
            for url in [storeFileURL(), legacyFileURL()] where FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.removeItem(at: url)
            }
        }

        private func storeFileURL() -> URL { directoryURL.appending(path: SnapshotStore.storeFileName) }
        private func legacyFileURL() -> URL { directoryURL.appending(path: SnapshotStore.legacyFileName) }

        private func readLegacySnapshot() -> MonitorSnapshot? {
            guard let data = try? Data(contentsOf: legacyFileURL()) else { return nil }
            return try? JSONDecoder().decode(MonitorSnapshot.self, from: data)
        }

        private func readState() throws -> StoreState {
            let url = storeFileURL()
            guard FileManager.default.fileExists(atPath: url.path) else { return StoreState() }
            let data = try Data(contentsOf: url)
            let state = try JSONDecoder().decode(StoreState.self, from: data)
            guard state.version == 1 else {
                throw MonitorError.message("The saved widget data uses an unsupported format.")
            }
            return state
        }

        private func updateState(_ update: (inout StoreState) -> Void) throws {
            var state = try readState()
            update(&state)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.sortedKeys]
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            try encoder.encode(state).write(to: storeFileURL(), options: .atomic)
        }

        private func selectedServer(in state: StoreState) -> StoredServer? {
            if let id = state.selectedServerID, let selected = state.servers[id.uuidString] {
                return selected
            }
            return mostRecentlySelected(in: state)
        }

        private func mostRecentlySelected(in state: StoreState) -> StoredServer? {
            state.servers.values.max {
                let leftDate = $0.lastSelectedAt ?? $0.snapshot?.sampledAt ?? .distantPast
                let rightDate = $1.lastSelectedAt ?? $1.snapshot?.sampledAt ?? .distantPast
                if leftDate == rightDate { return $0.server.id.uuidString > $1.server.id.uuidString }
                return leftDate < rightDate
            }
        }

        private static func normalizedName(_ name: String) -> String {
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? "Server" : trimmed
        }
    }
}
