import AppIntents
import WidgetKit

struct WidgetServerAction: AppIntent {
    static let title: LocalizedStringResource = "Switch widget server"
    @Parameter(title: "Scope") var scope: String
    @Parameter(title: "Action") var action: String
    @Parameter(title: "Server") var serverID: String

    init() {}
    init(scope: String, action: String, serverID: String = "") {
        self.scope = scope
        self.action = action
        self.serverID = serverID
    }

    func perform() async throws -> some IntentResult {
        let defaults = UserDefaults(suiteName: SnapshotStore.group)
        let key = "widget-navigation." + scope
        switch action {
        case "next", "previous":
            let servers = WidgetServerSource.servers()
            if !servers.isEmpty {
                // A second tap can arrive before WidgetKit has rendered a new entry,
                // so serverID may still describe the earlier card. Prefer the last
                // persisted choice, then fall back to the rendered entry.
                let persistedID = defaults?.string(forKey: key + ".server")
                let index = [persistedID, serverID]
                    .compactMap { candidate in
                        candidate.flatMap { id in servers.firstIndex { $0.id.uuidString == id } }
                    }
                    .first ?? (action == "previous" ? 0 : -1)
                let offset = action == "previous" ? -1 : 1
                defaults?.set(servers[(index + offset + servers.count) % servers.count].id.uuidString, forKey: key + ".server")
            }
        default: break
        }
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
