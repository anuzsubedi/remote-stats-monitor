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
        case "choose": defaults?.set(true, forKey: key + ".choosing")
        case "close": defaults?.set(false, forKey: key + ".choosing")
        case "page": defaults?.set((defaults?.integer(forKey: key + ".page") ?? 0) + 1, forKey: key + ".page")
        case "select":
            if let id = UUID(uuidString: serverID), WidgetServerSource.record(for: id) != nil {
                defaults?.set(serverID, forKey: key + ".server")
            }
            defaults?.set(false, forKey: key + ".choosing")
        case "next", "previous":
            let servers = WidgetServerSource.servers()
            if !servers.isEmpty {
                let index = servers.firstIndex { $0.id.uuidString == serverID } ?? (action == "previous" ? 0 : -1)
                let offset = action == "previous" ? -1 : 1
                defaults?.set(servers[(index + offset + servers.count) % servers.count].id.uuidString, forKey: key + ".server")
            }
        default: break
        }
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
