// This executable links the production MonitorModel and ServerSession against
// isolated SSH, Keychain, and cache doubles; it never touches saved credentials.
import Foundation

actor CollectionProbe {
    static let shared = CollectionProbe()
    var active = 0
    var maximumActive = 0
    func begin() { active += 1; maximumActive = max(maximumActive, active) }
    func end() { active -= 1 }
}

actor SSHService {
    func proposedKey(for connection: Connection) async throws -> HostKeyProposal? {
        connection.host == "trust.local" ? HostKeyProposal(line: "fixture", fingerprint: "fixture") : nil
    }
    func trust(_ proposal: HostKeyProposal) throws {}
    func close(_ connection: Connection) async {}
    func collect(_ connection: Connection, helperURL: URL) async throws -> MonitorSnapshot {
        await CollectionProbe.shared.begin()
        try? await Task.sleep(for: .milliseconds(150))
        await CollectionProbe.shared.end()
        try Task.checkCancellation()
        if connection.host == "auth-failure.local" { throw MonitorError.authentication }
        var value = MonitorSnapshot.sample
        value.host = connection.host
        value.isSample = false
        return value
    }
}

@MainActor enum KeychainStore {
    static var connections = [Connection(host: "healthy.local"), Connection(host: "auth-failure.local")]
    static func loadAll() throws -> [Connection] { connections }
    static func save(_ connection: Connection) throws {
        connections.removeAll { $0.id == connection.id }
        connections.append(connection)
    }
    static func delete(id: UUID) throws { connections.removeAll { $0.id == id } }
}

struct ServerDescriptor: Codable, Hashable, Identifiable, Sendable { let id: UUID; var name: String }
struct ServerSnapshotRecord: Codable, Equatable, Sendable { var server: ServerDescriptor; var snapshot: MonitorSnapshot? }
@MainActor enum SnapshotStore {
    nonisolated static func directory() throws -> URL { URL(fileURLWithPath: NSTemporaryDirectory()).appending(path: "monitor-model-checks-" + String(ProcessInfo.processInfo.processIdentifier)) }

    static func reconcile(_ servers: [ServerDescriptor], aliases: [UUID: UUID] = [:]) throws {}
    static let widgetKind = "ModelChecksOnly"
    static var readings: [UUID: MonitorSnapshot] = [:]
    static var selectedID: UUID?
    static func upsertServer(id: UUID, name: String) throws {}
    static func read(for id: UUID) -> MonitorSnapshot? { readings[id] }
    static func write(_ reading: MonitorSnapshot, for id: UUID, name: String) throws { readings[id] = reading }
    static func remove(id: UUID) throws { readings[id] = nil }
    static func select(id: UUID) throws { selectedID = id }
}

@main struct ModelChecks {
    @MainActor static func main() async throws {
        func require(_ condition: Bool, _ message: String) throws {
            if !condition { throw MonitorError.message("Model check failed: " + message) }
        }
        defer { try? FileManager.default.removeItem(at: SnapshotStore.directory()) }
        var duplicate = KeychainStore.connections[0]
        duplicate.id = UUID()
        KeychainStore.connections.append(duplicate)
        let model = MonitorModel()
        try require(model.sessions.count == 2 && KeychainStore.connections.count == 2, "identical saved connections merge on startup")
        try await Task.sleep(for: .milliseconds(500))
        try require(await CollectionProbe.shared.maximumActive == 2, "servers collect concurrently")
        let healthy = model.sessions.first { $0.connection.host == "healthy.local" }!
        let selectionBeforeRefresh = model.selectedID
        await model.refreshServer(id: healthy.id)
        try require(model.selectedID == selectionBeforeRefresh, "refreshing a specific server preserves selection")
        let failed = model.sessions.first { $0.connection.host == "auth-failure.local" }!
        try require(healthy.snapshot?.host == "healthy.local", "healthy server publishes despite peer failure")
        try require(failed.authenticationFailed && failed.snapshot == nil, "authentication failure is isolated")
        try require(SnapshotStore.readings.count == 1, "cache contains only successful reading")
        model.selectedID = healthy.id
        model.draft = failed.connection
        await model.forgetConnection()
        try require(model.sessions.count == 1 && model.connection?.id == healthy.id, "forget removes only requested server")
        try require(KeychainStore.connections.map(\.id) == [healthy.id], "forget leaves other credentials")
        model.draft = healthy.connection
        model.draft.host = "updated.local"
        let connecting = Task { await model.beginConnection() }
        try await Task.sleep(for: .milliseconds(40))
        try require(model.isConnecting && model.successfulConnectionCount == 0, "wait for first reading before closing")
        await connecting.value
        try require(!model.isConnecting && model.successfulConnectionCount == 1, "successful first reading requests dismissal once")
        try await Task.sleep(for: .milliseconds(300))
        try require(model.sessions.count == 1 && model.snapshot?.host == "updated.local", "edit replaces session using stable ID")
        try require(model.sessions[0].id == healthy.id, "edit preserves identity")
        model.draft = Connection(host: "auth-failure.local")
        await model.beginConnection()
        try require(model.successfulConnectionCount == 1 && model.selectedSession?.error != nil, "failed connection keeps dialog open")
        model.draft = Connection(host: "trust.local")
        await model.beginConnection()
        try require(model.showHostKeyPrompt && model.successfulConnectionCount == 1, "host-key prompt does not dismiss connection window")
        await model.trustAndConnect()
        try require(model.successfulConnectionCount == 2, "trusted connection dismisses after its first reading")
        let existingCount = model.sessions.count
        let existingID = model.selectedID
        model.draft = Connection(host: "trust.local")
        await model.beginConnection()
        await model.trustAndConnect()
        try require(model.sessions.count == existingCount && model.selectedID == existingID, "adding same destination reuses saved identity")
        #if DEBUG
        let credentialsBefore = KeychainStore.connections
        let cacheBefore = SnapshotStore.readings
        let widgetSelectionBefore = SnapshotStore.selectedID
        model.addSyntheticServers()
        let syntheticIDs = model.sessions.filter(\.isSynthetic).map(\.id)
        try require(syntheticIDs.count == 8, "eight synthetic servers")
        model.select(syntheticIDs[1])
        model.addSyntheticServers()
        try require(model.sessions.filter(\.isSynthetic).count == 8, "adding synthetic servers is idempotent")
        await model.refresh()
        try require(model.selectedSession?.snapshot?.isSample == true, "synthetic refresh remains labelled")
        try require(KeychainStore.connections == credentialsBefore && SnapshotStore.readings == cacheBefore, "synthetic servers never persist credentials or telemetry")
        try require(SnapshotStore.selectedID == widgetSelectionBefore, "synthetic selection does not change widget selection")
        try require(DebugSnapshotStore.read().count == 8, "debug widget cache contains eight samples")
        let restarted = MonitorModel()
        try require(restarted.sessions.filter(\.isSynthetic).map(\.id) == syntheticIDs, "restart restores test servers with stable IDs")
        try require(DebugSnapshotStore.read().count == 8, "restart preserves widget picker cache")
        try require(restarted.sessions.filter(\.isSynthetic).allSatisfy { $0.pollTask == nil }, "restored test servers never poll SSH")
        for session in restarted.sessions { session.pollTask?.cancel() }
        model.removeSyntheticServers()
        try require(DebugSnapshotStore.read().isEmpty, "removal clears debug widget cache")
        try require(!model.sessions.contains(where: \.isSynthetic), "synthetic removal leaves real sessions")
        print("Debug checks passed: synthetic scenarios, refresh, selection and persistence isolation.")
        #endif
        for session in model.sessions { session.pollTask?.cancel() }
        KeychainStore.connections = [Connection(host: "in-flight.local")]
        SnapshotStore.readings = [:]
        let inFlight = MonitorModel()
        try await Task.sleep(for: .milliseconds(30))
        await inFlight.forgetConnection()
        try await Task.sleep(for: .milliseconds(200))
        try require(inFlight.sessions.isEmpty && SnapshotStore.readings.isEmpty, "cancelled reading cannot restore a forgotten server")
        print("Model checks passed: concurrent polling, isolated authentication failure, per-server removal, stable-ID edits, in-flight removal, successful and failed connection completion, host-key trust.")
    }
}
