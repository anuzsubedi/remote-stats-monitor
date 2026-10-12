import Foundation

// Isolated stand-ins keep navigation tests away from the real app group.
enum SnapshotStore {
    static let group = "dev.anuz.RemoteStatsMonitor.navigation-tests." + UUID().uuidString
}
struct FixtureServer { let id: UUID }
enum WidgetServerSource {
    static let fixtures = [FixtureServer(id: UUID()), FixtureServer(id: UUID())]
    static func servers() -> [FixtureServer] { fixtures }
    static func record(for id: UUID) -> FixtureServer? { fixtures.first { $0.id == id } }
}

@main enum WidgetNavigationChecks {
    static func main() async throws {
        let defaults = UserDefaults(suiteName: SnapshotStore.group)!
        defer { defaults.removePersistentDomain(forName: SnapshotStore.group) }
        let scope = "test-overview"
        let key = "widget-navigation." + scope
        let ids = WidgetServerSource.fixtures.map { $0.id.uuidString }
        _ = try await WidgetServerAction(scope: scope, action: "next", serverID: ids[0]).perform()
        precondition(defaults.string(forKey: key + ".server") == ids[1])
        // The widget can send the same entry ID for both taps if its refreshed
        // timeline has not rendered yet. Each action must advance persisted state.
        _ = try await WidgetServerAction(scope: scope, action: "next", serverID: ids[0]).perform()
        precondition(defaults.string(forKey: key + ".server") == ids[0])
        _ = try await WidgetServerAction(scope: scope, action: "previous", serverID: ids[1]).perform()
        precondition(defaults.string(forKey: key + ".server") == ids[1])
        _ = try await WidgetServerAction(scope: scope, action: "previous", serverID: ids[1]).perform()
        precondition(defaults.string(forKey: key + ".server") == ids[0])
        precondition(defaults.string(forKey: "widget-navigation.other.server") == nil)
        print("Widget navigation checks passed: next, previous, wraparound, stale-entry taps, and scope isolation.")
    }
}
