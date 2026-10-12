import SwiftUI

struct ServersView: View {
    @Bindable var model: MonitorModel
    @Environment(\.openWindow) private var openWindow
    @State private var search = ""
    @AppStorage("windowLayout") private var storedLayout = ServerLayout.list
    var previewLayout: ServerLayout? = nil
    private var layout: ServerLayout { previewLayout ?? storedLayout }

    private var filteredSessions: [ServerSession] {
        model.sessions.filter { search.isEmpty || $0.connection.displayName.localizedStandardContains(search) }
            .sorted { $0.connection.displayName.localizedStandardCompare($1.connection.displayName) == .orderedAscending }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Servers").font(.largeTitle.weight(.bold))
                    Text(model.sessions.count == 1 ? "1 server" : "\(model.sessions.count) servers")
                        .font(.callout).foregroundStyle(.secondary)
                }
                Spacer()
                Picker("View", selection: Binding(get: { layout }, set: { storedLayout = $0 })) {
                    ForEach(ServerLayout.allCases) { Label($0.rawValue, systemImage: $0.symbol).tag($0) }
                }.pickerStyle(.segmented).labelsHidden().frame(width: 230)
                Button("Add server", systemImage: "plus", action: addServer)
                    .buttonStyle(.glassProminent)
            }.padding(24)
            if layout != .single {
            HStack {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("Find a server", text: $search).textFieldStyle(.plain)
                    .accessibilityLabel("Find a server")
                if !search.isEmpty {
                    Button("Clear search", systemImage: "xmark.circle.fill") { search = "" }
                        .labelStyle(.iconOnly).buttonStyle(.plain)
                }
            }.padding(10).background(.quaternary, in: .rect(cornerRadius: 8))
                .padding(.horizontal, 24).padding(.bottom, 16)
            }
            Divider()
            if model.sessions.isEmpty {
                ContentUnavailableView {
                    Label("No servers yet", systemImage: "server.rack")
                } description: {
                    Text("Add a server to view its readings alongside your other connections.")
                } actions: {
                    Button("Add server", action: addServer)
                    #if DEBUG
                    Button("Add 8 test servers") { model.addSyntheticServers() }
                    #endif
                }.frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filteredSessions.isEmpty {
                ContentUnavailableView.search(text: search)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ServerBrowser(model: model, layout: layout, search: layout == .single ? "" : search)
            }
            Divider()
            HStack {
                Label("Select a server to show it in the menu bar.", systemImage: "menubar.rectangle")
                Spacer()
                #if DEBUG
                Menu("Test servers", systemImage: "ladybug") {
                    Button("Add 8 test servers") { model.addSyntheticServers() }
                        .disabled(model.hasSyntheticServers)
                    Button("Refresh test readings") { model.updateSyntheticReadings() }
                        .disabled(!model.hasSyntheticServers)
                    Button("Remove test servers") { model.removeSyntheticServers() }
                        .disabled(!model.hasSyntheticServers)
                }.fixedSize()
                #endif
            }.font(.caption).foregroundStyle(.secondary).padding(16)
        }
        .frame(minWidth: 660, minHeight: 420)
    }

    private func addServer() {
        model.addServer()
        openWindow(id: "connection")
        NSApp.activate()
    }
}
