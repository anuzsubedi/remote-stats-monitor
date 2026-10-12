import SwiftUI

struct RemoteStatsMonitorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var model: MonitorModel
    @State private var navigationSelection: AppNavigationSection?
    @State private var navigationPath: [ServerDetailRoute] = []

    private let previewLayout: ServerLayout?
    private let previewDestination: AppNavigationSection?
    private let previewDetailID: UUID?

    init() {
        #if DEBUG
        let arguments = CommandLine.arguments
        let uiPreview = arguments.contains("--ui-preview")
        let model = MonitorModel(preview: uiPreview)
        if uiPreview {
            model.addSyntheticServers(publish: false)
        }

        let destination = uiPreview ? AppNavigationSection.previewDestination(arguments: arguments) : .overview
        previewLayout = uiPreview ? Self.previewLayout(arguments: arguments) : nil
        previewDestination = uiPreview ? destination : nil
        previewDetailID = uiPreview && Self.previewDestinationName(arguments: arguments) == "detail"
            ? model.sessions.first?.id
            : nil
        _model = State(initialValue: model)
        _navigationSelection = State(initialValue: destination)
        #else
        previewLayout = nil
        previewDestination = nil
        previewDetailID = nil
        _model = State(initialValue: MonitorModel())
        _navigationSelection = State(initialValue: .overview)
        #endif
    }

    var body: some Scene {
        MenuBarExtra {
            MenuPanel(model: model, onOpenSection: route(to:))
        } label: {
            Label(model.menuBarTitle, systemImage: "cpu")
                .background(AppWindowRouting(
                    appDelegate: appDelegate,
                    selection: $navigationSelection,
                    detailPath: $navigationPath,
                    bootstrap: true
                ))
        }
        .menuBarExtraStyle(.window)

        Window("Remote Stats Monitor", id: "servers") {
            AppNavigationView(
                model: model,
                selection: $navigationSelection,
                detailPath: $navigationPath,
                previewLayout: previewLayout,
                previewDestination: previewDestination,
                previewDetailID: previewDetailID
            )
            .background(AppWindowRouting(
                appDelegate: appDelegate,
                selection: $navigationSelection,
                detailPath: $navigationPath
            ))
        }
        .defaultSize(width: 1120, height: 780)
        .defaultLaunchBehavior(.presented)
        .commands {
            AppNavigationCommands(navigate: route(to:))
        }

        Window("Remote Stats Monitor — Settings", id: "settings") {
            SettingsView(model: model, onAddTestServers: { route(to: .servers) })
        }
        .windowResizability(.contentSize)
        .defaultLaunchBehavior(.suppressed)

        Window("Remote Stats Monitor — Processes", id: "processes") {
            ProcessesView(model: model)
        }
        .defaultSize(width: 640, height: 620)
        .defaultLaunchBehavior(.suppressed)

        Window("Remote Stats Monitor — Connection", id: "connection") {
            ConnectionSceneView(model: model, appDelegate: appDelegate, onAddTestServers: { route(to: .servers) })
        }
        .windowResizability(.contentSize)
        .defaultLaunchBehavior(.suppressed)
    }

    private func route(to section: AppNavigationSection) {
        if let openMainSection = appDelegate.openMainSection {
            openMainSection(section)
        } else {
            navigationSelection = section
            navigationPath = []
            appDelegate.openMainWindow?()
        }
    }

    #if DEBUG
    private static func previewDestinationName(arguments: [String]) -> String? {
        guard let optionIndex = arguments.firstIndex(of: "--preview-destination"),
              arguments.indices.contains(optionIndex + 1) else {
            return nil
        }
        return arguments[optionIndex + 1].lowercased()
    }

    private static func previewLayout(arguments: [String]) -> ServerLayout? {
        guard let optionIndex = arguments.firstIndex(of: "--preview-layout"),
              arguments.indices.contains(optionIndex + 1) else {
            return nil
        }

        switch arguments[optionIndex + 1].lowercased() {
        case "list": return .list
        case "grid": return .grid
        default: return nil
        }
    }
    #endif
}
