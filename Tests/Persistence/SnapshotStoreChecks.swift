import Foundation

@main struct SnapshotStoreChecks {
    static func require(_ condition: @autoclosure () -> Bool, _ message: String) throws {
        if !condition() { throw MonitorError.message("Check failed: " + message) }
    }

    static func main() throws {
        let root = FileManager.default.temporaryDirectory.appending(path: "snapshot-store-checks-\(UUID().uuidString)", directoryHint: .isDirectory)
        defer { try? FileManager.default.removeItem(at: root) }

        let store = SnapshotStore.store(at: root.appending(path: "servers", directoryHint: .isDirectory))
        let firstID = UUID()
        let secondID = UUID()
        try store.upsertServer(id: firstID, name: "Pi One", iconName: "desktopcomputer")
        try store.upsertServer(id: secondID, name: "Pi Two", iconName: "externaldrive")
        try require(store.servers().count == 2, "registered servers appear before the first reading")
        try require(store.record(for: firstID)?.snapshot == nil, "registered server has no fabricated reading")
        try require(store.descriptor(for: firstID)?.iconName == "desktopcomputer", "server icon is stored before the first reading")

        var first = MonitorSnapshot.sample
        first.host = "pi-one.local"
        first.isSample = false
        var second = MonitorSnapshot.sample
        second.host = "pi-two.local"
        second.isSample = false

        try store.write(first, for: firstID, name: "Pi One", iconName: "desktopcomputer")
        try store.write(second, for: secondID, name: "Pi Two", iconName: "externaldrive")
        try require(store.read(for: firstID)?.host == "pi-one.local", "first UUID reads its own snapshot")
        try require(store.read(for: secondID)?.host == "pi-two.local", "second UUID reads its own snapshot")
        try require(store.record(for: firstID)?.server.iconName == "desktopcomputer", "snapshot cache retains server icon")
        try store.upsertServer(id: firstID, name: "Renamed Pi", iconName: "laptopcomputer")
        try require(store.record(for: firstID)?.snapshot?.host == "pi-one.local", "identity edits preserve cached readings")
        try require(store.record(for: firstID)?.server.name == "Renamed Pi" && store.record(for: firstID)?.server.iconName == "laptopcomputer",
                    "identity edits update widget name and icon")

        try store.select(id: secondID)
        try require(store.readSelected()?.host == "pi-two.local", "unconfigured widget follows selected server")
        try store.select(id: firstID)
        try require(store.readSelected()?.host == "pi-one.local", "selection changes the default server")
        try require(store.read(for: secondID)?.host == "pi-two.local", "selection leaves other server data intact")

        try store.write(.sample, for: firstID, name: "Pi One")
        try require(store.read(for: firstID)?.host == "pi-one.local", "sample reading cannot replace live data")
        try store.remove(id: firstID)
        try require(store.record(for: firstID) == nil, "removing a server removes its descriptor and reading")
        try require(store.readSelected()?.host == "pi-two.local", "default selection falls back to a remaining server")

        let duplicateID = UUID()
        let orphanID = UUID()
        try store.write(first, for: duplicateID, name: "Duplicate")
        try store.upsertServer(id: orphanID, name: "Orphan")
        try store.reconcile([.init(id: secondID, name: "Pi Two")], aliases: [duplicateID: secondID])
        try require(store.servers().map(\.id) == [secondID], "reconciliation removes orphan and duplicate choices")
        try require(store.record(for: duplicateID)?.server.id == secondID, "old widget selection redirects to retained server")
        try store.reconcile([.init(id: secondID, name: "Pi Two")])
        try require(store.record(for: duplicateID)?.server.id == secondID, "redirect survives subsequent startup")

        let legacyDirectory = root.appending(path: "legacy", directoryHint: .isDirectory)
        let legacyStore = SnapshotStore.store(at: legacyDirectory)
        try legacyStore.writeLegacySnapshot(.sample)
        try require(legacyStore.readSelected() == nil, "sample reading cannot be written in legacy format")
        try require(!FileManager.default.fileExists(atPath: legacyDirectory.path), "rejected legacy sample does not create a cache file")
        try legacyStore.writeLegacySnapshot(first)
        try require(legacyStore.readSelected()?.host == "pi-one.local", "legacy single-snapshot reads remain supported")

        let oldCacheDirectory = root.appending(path: "old-cache", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: oldCacheDirectory, withIntermediateDirectories: true)
        let oldID = UUID()
        let oldState = """
        {"aliases":null,"version":1,"selectedServerID":"\(oldID.uuidString)","servers":{"\(oldID.uuidString)":{"server":{"id":"\(oldID.uuidString)","name":"Legacy Pi"},"snapshot":null,"lastSelectedAt":null}}}
        """
        try Data(oldState.utf8).write(to: oldCacheDirectory.appending(path: "snapshot-store.json"))
        let oldStore = SnapshotStore.store(at: oldCacheDirectory)
        try require(oldStore.descriptor(for: oldID)?.iconName == "server.rack", "old widget cache defaults missing icon to rack")

        print("Snapshot store checks passed: isolated servers, identity persistence, selection, removal, sample rejection, and legacy compatibility.")
    }
}
