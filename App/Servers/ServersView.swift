import SwiftUI

struct ServersView: View {
    @Bindable var model: MonitorModel
    @Environment(\.openWindow) private var openWindow
    @State private var search = ""
    @AppStorage("windowLayout") private var storedLayout = ServerLayout.list
    var previewLayout: ServerLayout? = nil

    private var layout: ServerLayout { previewLayout ?? storedLayout }
    private var selectedServer: Binding<UUID?> {
        Binding(
            get: { model.selectedID },
            set: { if let id = $0 { model.select(id) } }
        )
    }
    private var filteredSessions: [ServerSession] {
        model.sessions
            .filter { search.isEmpty || $0.connection.displayName.localizedStandardContains(search) }
            .sorted { $0.connection.displayName.localizedStandardCompare($1.connection.displayName) == .orderedAscending }
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 5)) { timeline in
            VStack(spacing: 0) {
                header
                Divider()

                if model.sessions.isEmpty {
                    emptyState
                } else if layout == .single {
                    ServerDetailView(model: model, currentDate: timeline.date, showsServerPicker: true)
                } else {
                    NavigationSplitView {
                        serverSidebar(currentDate: timeline.date)
                            .navigationSplitViewColumnWidth(min: 245, ideal: 310, max: 390)
                    } detail: {
                        ServerDetailView(model: model, currentDate: timeline.date)
                    }
                    .navigationSplitViewStyle(.balanced)
                }
            }
        }
        .frame(minWidth: 660, minHeight: 440)
    }

    private var header: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Servers")
                    .font(.title3.weight(.semibold))
                Text(model.sessions.count == 1 ? "1 saved server" : "\(model.sessions.count) saved servers")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 6)

            Picker("View", selection: Binding(get: { layout }, set: { storedLayout = $0 })) {
                ForEach(ServerLayout.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(width: 230)

            Button("Add server", systemImage: "plus", action: addServer)
                .buttonStyle(.glassProminent)

            actionsMenu
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 13)
    }

    private func serverSidebar(currentDate: Date) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(layout == .list ? "Server list" : "Server grid")
                    .font(.headline)
                Spacer()
                Text("\(filteredSessions.count)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 18)
            .padding(.bottom, 12)

            searchField
                .padding(.horizontal, 12)
                .padding(.bottom, 8)

            if filteredSessions.isEmpty {
                ContentUnavailableView.search(text: search)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if layout == .list {
                List(selection: selectedServer) {
                    ForEach(filteredSessions) { session in
                        serverListRow(session, currentDate: currentDate)
                            .tag(Optional(session.id))
                            .listRowSeparator(.hidden)
                    }
                }
                .listStyle(.sidebar)
                .scrollContentBackground(.hidden)
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 126), spacing: 10)], spacing: 10) {
                        ForEach(filteredSessions) { session in
                            serverGridItem(session, currentDate: currentDate)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
            }

            Divider()

            Label("Selection appears in the menu bar", systemImage: "menubar.rectangle")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
        }
        .background(Color(nsColor: .underPageBackgroundColor))
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Find a server", text: $search)
                .textFieldStyle(.plain)
                .accessibilityLabel("Find a server")
            if !search.isEmpty {
                Button("Clear search", systemImage: "xmark.circle.fill") { search = "" }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.plain)
                    .help("Clear search")
            }
        }
        .padding(8)
        .background(.background, in: .rect(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.secondary.opacity(0.18))
        }
    }

    private func serverListRow(_ session: ServerSession, currentDate: Date) -> some View {
        let isSelected = session.id == model.selectedID
        let status = statusText(for: session, at: currentDate)

        return HStack(spacing: 10) {
            Image(systemName: "server.rack")
                .font(.title3)
                .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 4) {
                Text(session.connection.displayName)
                    .font(.body.weight(.medium))
                    .lineLimit(1)
                    .truncationMode(.middle)
                HStack(spacing: 5) {
                    Circle()
                        .fill(statusColor(for: session, at: currentDate))
                        .frame(width: 6, height: 6)
                    Text(status)
                        .font(.caption)
                        .foregroundStyle(session.error == nil ? Color.secondary : PiTheme.warning)
                }
            }

            Spacer(minLength: 6)

            Text(MonitorMetric.cpu.formatted(session.snapshot))
                .font(.body.monospacedDigit().weight(.semibold))
                .foregroundStyle(MonitorMetric.cpu.warning(session.snapshot) ? PiTheme.warning : PiTheme.ink)
                .frame(minWidth: 46, alignment: .trailing)
        }
        .padding(.vertical, 7)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(session.connection.displayName), \(status), CPU \(MonitorMetric.cpu.formatted(session.snapshot))")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func serverGridItem(_ session: ServerSession, currentDate: Date) -> some View {
        let isSelected = session.id == model.selectedID
        let temperature = MonitorMetric.temperature.formatted(session.snapshot)
        let status = statusText(for: session, at: currentDate)

        return Button { model.select(session.id) } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "server.rack")
                        .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                    if isSelected {
                        Spacer(minLength: 0)
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.tint)
                    }
                }

                Text(session.connection.displayName)
                    .font(.body.weight(.medium))
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(alignment: .firstTextBaseline) {
                    Text("CPU")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer(minLength: 4)
                    Text(MonitorMetric.cpu.formatted(session.snapshot))
                        .font(.callout.monospacedDigit().weight(.semibold))
                        .foregroundStyle(MonitorMetric.cpu.warning(session.snapshot) ? PiTheme.warning : PiTheme.ink)
                }

                HStack(alignment: .firstTextBaseline) {
                    Text("Temp")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer(minLength: 4)
                    Text(temperature)
                        .font(.caption.monospacedDigit().weight(.medium))
                        .foregroundStyle(MonitorMetric.temperature.warning(session.snapshot) ? PiTheme.warning : PiTheme.ink)
                }

                HStack(spacing: 5) {
                    Circle()
                        .fill(statusColor(for: session, at: currentDate))
                        .frame(width: 6, height: 6)
                    Text(status)
                        .font(.caption)
                        .foregroundStyle(session.error == nil ? Color.secondary : PiTheme.warning)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            .padding(11)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(nsColor: .controlBackgroundColor), in: .rect(cornerRadius: 10))
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(Color.accentColor, lineWidth: 1.5)
                }
            }
            .contentShape(.rect(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(session.connection.displayName), \(status), CPU \(MonitorMetric.cpu.formatted(session.snapshot)), temperature \(temperature)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No servers yet", systemImage: "server.rack")
        } description: {
            Text("Add an SSH connection to view its readings alongside your other servers.")
        } actions: {
            Button("Add server", action: addServer)
            #if DEBUG
            Button("Add 8 test servers") { model.addSyntheticServers() }
            #endif
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var actionsMenu: some View {
        Menu("More", systemImage: "ellipsis") {
            Button("Settings & widgets…") {
                openWindow(id: "settings")
                NSApp.activate()
            }

            if let session = model.selectedSession {
                Button("Refresh selected server") { Task { await model.refreshServer(id: session.id) } }
                    .disabled(session.isRefreshing)
                if !session.isSynthetic {
                    Button("Edit selected connection…") {
                        model.editSelected()
                        openWindow(id: "connection")
                        NSApp.activate()
                    }
                }
            }

            #if DEBUG
            Divider()
            Button("Add test servers") { model.addSyntheticServers() }
                .disabled(model.hasSyntheticServers)
            Button("Refresh test readings") { model.updateSyntheticReadings() }
                .disabled(!model.hasSyntheticServers)
            Button("Remove test servers") { model.removeSyntheticServers() }
                .disabled(!model.hasSyntheticServers)
            #endif

            Divider()
            Button("Quit Remote Stats Monitor") { NSApp.terminate(nil) }
                .keyboardShortcut("q")
        }
        .labelStyle(.iconOnly)
        .menuStyle(.borderlessButton)
        .fixedSize()
        .help("More actions")
    }

    private func addServer() {
        model.addServer()
        openWindow(id: "connection")
        NSApp.activate()
    }

    private func statusText(for session: ServerSession, at currentDate: Date) -> String {
        if session.isRefreshing { return "Updating" }
        if session.error != nil || session.snapshot?.connectionError != nil { return "Disconnected" }
        if session.isSynthetic { return "Test server" }
        return ReadingStatus.label(session.snapshot, at: currentDate)
    }

    private func statusColor(for session: ServerSession, at currentDate: Date) -> Color {
        switch statusText(for: session, at: currentDate) {
        case "Connected": PiTheme.connected
        case "Disconnected", "Last reading", "High temperature": PiTheme.warning
        default: .secondary
        }
    }
}
