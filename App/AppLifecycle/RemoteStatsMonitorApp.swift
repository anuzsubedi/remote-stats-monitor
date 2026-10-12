import SwiftUI

struct RemoteStatsMonitorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var model = MonitorModel()

    var body: some Scene {
        MenuBarExtra {
            MenuPanel(model: model)
        } label: {
            Label(model.menuBarTitle, systemImage: "cpu")
        }
        .menuBarExtraStyle(.window)

        Window("Remote Stats Monitor — Servers", id: "servers") {
            ServersView(model: model)
                .background(AppWindowRouting(appDelegate: appDelegate))
        }
        .defaultSize(width: 860, height: 720)
        .defaultLaunchBehavior(.presented)

        Window("Remote Stats Monitor — Settings", id: "settings") {
            SettingsView(model: model)
        }
        .windowResizability(.contentSize)
        .defaultLaunchBehavior(.suppressed)

        Window("Remote Stats Monitor — Processes", id: "processes") {
            ProcessesView(model: model)
        }
        .defaultSize(width: 640, height: 620)
        .defaultLaunchBehavior(.suppressed)

        Window("Remote Stats Monitor — Connection", id: "connection") {
            ConnectionSceneView(model: model, appDelegate: appDelegate)
        }
        .windowResizability(.contentSize)
        .defaultLaunchBehavior(.suppressed)
    }
}
