import SwiftUI

struct AppNavigationView: View {
    @Bindable var model: MonitorModel
    @Binding var selection: AppNavigationSection?
    @Binding var detailPath: [ServerDetailRoute]
    @Environment(\.openWindow) private var openWindow

    var previewLayout: ServerLayout? = nil
    var previewDestination: AppNavigationSection? = nil
    var previewDetailID: UUID? = nil

    private var activeSection: AppNavigationSection { selection ?? .overview }

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Section("Monitor") {
                    ForEach(AppNavigationSection.monitoringSections) { section in
                        Label(section.rawValue, systemImage: section.symbol)
                            .tag(section)
                    }
                }

                Section {
                    Label(AppNavigationSection.settings.rawValue, systemImage: AppNavigationSection.settings.symbol)
                        .tag(AppNavigationSection.settings)
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("Remote Stats")
            .navigationSplitViewColumnWidth(min: 170, ideal: 198, max: 232)
        } detail: {
            NavigationStack(path: $detailPath) {
                rootPage
                    .navigationDestination(for: ServerDetailRoute.self) { route in
                        if model.sessions.contains(where: { $0.id == route.id }) {
                            TimelineView(.periodic(from: .now, by: 5)) { timeline in
                                ServerDetailView(
                                    model: model,
                                    currentDate: timeline.date,
                                    showsServerPicker: true,
                                    navigationChrome: true,
                                    onShowProcesses: showProcesses
                                )
                                .onAppear { model.select(route.id) }
                            }
                        } else {
                            ContentUnavailableView(
                                "Server unavailable",
                                systemImage: "server.rack",
                                description: Text("Return to Servers to choose another server.")
                            )
                        }
                    }
                    .toolbar {
                        if activeSection == .overview && model.sessions.isEmpty {
                            ToolbarItem(placement: .primaryAction) {
                                Button("Add server", systemImage: "plus", action: addServer)
                            }
                        }
                    }
            }
            .navigationSplitViewColumnWidth(min: 620, ideal: 760)
        }
        .navigationSplitViewStyle(.balanced)
        .onChange(of: selection) { _, _ in detailPath.removeAll() }
        .task {
            guard let previewDestination else { return }
            await Task.yield()
            selection = previewDestination
            detailPath = []
            guard let previewDetailID else { return }
            await Task.yield()
            detailPath = [ServerDetailRoute(id: previewDetailID)]
        }
        .frame(minWidth: 900, minHeight: 600)
    }

    @ViewBuilder
    private var rootPage: some View {
        switch activeSection {
        case .overview:
            TimelineView(.periodic(from: .now, by: 5)) { timeline in
                ServerDetailView(
                    model: model,
                    currentDate: timeline.date,
                    showsServerPicker: true,
                    navigationChrome: true,
                    onShowProcesses: showProcesses
                )
            }
        case .servers:
            ServersView(model: model, previewLayout: previewLayout)
        case .processes:
            ProcessesView(model: model, embedded: true)
                .navigationTitle("Processes")
        case .settings:
            SettingsView(model: model, embedded: true, onAddTestServers: { navigate(to: .servers) })
                .navigationTitle("Settings")
        }
    }

    private func showProcesses() {
        navigate(to: .processes)
    }

    private func navigate(to section: AppNavigationSection) {
        selection = section
        detailPath = []
    }

    private func addServer() {
        model.addServer()
        openWindow(id: "connection")
        NSApp.activate()
    }
}
