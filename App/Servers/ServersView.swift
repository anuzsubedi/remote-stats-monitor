import SwiftUI

struct ServersView: View {
    @Bindable var model: MonitorModel
    @Environment(\.openWindow) private var openWindow
    @State private var search = ""
    @AppStorage("windowLayout") private var storedLayout = ServerLayout.list
    var previewLayout: ServerLayout? = nil

    private var layout: ServerLayout { previewLayout ?? storedLayout }
    private var fleetLayout: ServerLayout { layout == .grid ? .grid : .list }
    private var filteredSessions: [ServerSession] {
        model.sessions
            .filter { search.isEmpty || $0.connection.displayName.localizedStandardContains(search) || $0.connection.address.localizedStandardContains(search) }
            .sorted { $0.connection.displayName.localizedStandardCompare($1.connection.displayName) == .orderedAscending }
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 5)) { timeline in
            Group {
                if filteredSessions.isEmpty {
                    emptyState
                } else if fleetLayout == .list {
                    listView(currentDate: timeline.date)
                } else {
                    gridView(currentDate: timeline.date)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle("Servers")
        .navigationSubtitle(serverCountLabel)
        .searchable(text: $search, prompt: "Find a server")
        .toolbar {
            ToolbarItem(placement: .principal) {
                Picker("Fleet layout", selection: Binding(
                    get: { fleetLayout },
                    set: { storedLayout = $0 }
                )) {
                    Label("List", systemImage: ServerLayout.list.symbol).tag(ServerLayout.list)
                    Label("Grid", systemImage: ServerLayout.grid.symbol).tag(ServerLayout.grid)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .fixedSize()
                .help("Choose list or grid")
            }

            ToolbarItemGroup(placement: .primaryAction) {
                Button("Add server", systemImage: "plus", action: addServer)
                    .help("Add a server")
                actionsMenu
            }
        }
        .frame(minWidth: 620, minHeight: 440)
    }

    private var serverCountLabel: String {
        model.sessions.count == 1 ? "1 server" : "\(model.sessions.count) servers"
    }

    private func listView(currentDate: Date) -> some View {
        List {
            ForEach(filteredSessions) { session in
                NavigationLink(value: ServerDetailRoute(id: session.id)) {
                    serverRow(session, currentDate: currentDate)
                }
                .buttonStyle(.plain)
                .listRowSeparator(.visible)
                .listRowInsets(EdgeInsets(top: 0, leading: 18, bottom: 0, trailing: 18))
            }
        }
        .listStyle(.plain)
    }

    private func serverRow(_ session: ServerSession, currentDate: Date) -> some View {
        HStack(spacing: 18) {
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Image(systemName: session.connection.iconName)
                        .foregroundStyle(session.id == model.selectedID ? Color.accentColor : Color.secondary)
                    Text(session.connection.displayName)
                        .font(.body.weight(.semibold))
                        .lineLimit(1)
                        .truncationMode(.middle)
                    if session.id == model.selectedID {
                        Image(systemName: "menubar.rectangle")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .help("Shown in the menu bar")
                    }
                }

                HStack(spacing: 6) {
                    Circle()
                        .fill(statusColor(for: session, at: currentDate))
                        .frame(width: 6, height: 6)
                        .accessibilityHidden(true)
                    Text(statusText(for: session, at: currentDate))
                        .font(.caption)
                        .foregroundStyle(statusColor(for: session, at: currentDate))
                    if let sampledAt = session.snapshot?.sampledAt {
                        Text("·").foregroundStyle(.tertiary)
                        Text(sampledAt, format: .dateTime.hour().minute())
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(minWidth: 170, maxWidth: 250, alignment: .leading)

            Spacer(minLength: 6)

            HStack(spacing: 0) {
                metricValue(.cpu, session: session, width: 78)
                metricValue(.gpu, session: session, width: 78)
                metricValue(.temperature, session: session, width: 92)
                metricValue(.memory, session: session, width: 92)
            }
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(serverAccessibilityLabel(session, currentDate: currentDate))
    }

    private func gridView(currentDate: Date) -> some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 245), spacing: 14)], spacing: 14) {
                ForEach(filteredSessions) { session in
                    NavigationLink(value: ServerDetailRoute(id: session.id)) {
                        serverTile(session, currentDate: currentDate)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(20)
        }
    }

    private func serverTile(_ session: ServerSession, currentDate: Date) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: session.connection.iconName)
                    .font(.title3)
                    .foregroundStyle(session.id == model.selectedID ? Color.accentColor : Color.secondary)
                VStack(alignment: .leading, spacing: 5) {
                    Text(session.connection.displayName)
                        .font(.body.weight(.semibold))
                        .lineLimit(1)
                        .truncationMode(.middle)
                    HStack(spacing: 6) {
                        Circle()
                            .fill(statusColor(for: session, at: currentDate))
                            .frame(width: 6, height: 6)
                            .accessibilityHidden(true)
                        Text(statusText(for: session, at: currentDate))
                            .font(.caption)
                            .foregroundStyle(statusColor(for: session, at: currentDate))
                    }
                }
                Spacer(minLength: 0)
                if session.id == model.selectedID {
                    Image(systemName: "menubar.rectangle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .help("Shown in the menu bar")
                }
            }

            Divider()

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 12) {
                metricValue(.cpu, session: session)
                metricValue(.gpu, session: session)
                metricValue(.temperature, session: session)
                metricValue(.memory, session: session)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: .rect(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.secondary.opacity(0.16))
        }
        .contentShape(.rect(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(serverAccessibilityLabel(session, currentDate: currentDate))
    }

    @ViewBuilder
    private func metricValue(_ metric: MonitorMetric, session: ServerSession, width: CGFloat? = nil) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(metric == .temperature ? "Temp" : metric.rawValue)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(metric.formatted(session.snapshot))
                .font(.body.monospacedDigit().weight(.medium))
                .foregroundStyle(metric.warning(session.snapshot) ? PiTheme.warning : PiTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .frame(width: width, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var emptyState: some View {
        Group {
            if search.isEmpty {
                ContentUnavailableView {
                    Label("No servers yet", systemImage: "server.rack")
                } description: {
                    Text("Add an SSH connection to view its readings.")
                } actions: {
                    Button("Add server", action: addServer)
                        .buttonStyle(.glassProminent)
                    #if DEBUG
                    Button("Add test servers") { model.addSyntheticServers() }
                    #endif
                }
            } else {
                ContentUnavailableView.search(text: search)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var actionsMenu: some View {
        Menu("More server actions", systemImage: "ellipsis") {
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
        .menuIndicator(.hidden)
        .help("More server actions")
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

    private func serverAccessibilityLabel(_ session: ServerSession, currentDate: Date) -> String {
        "\(session.connection.displayName), \(statusText(for: session, at: currentDate)), CPU \(MonitorMetric.cpu.formatted(session.snapshot)), GPU \(MonitorMetric.gpu.formatted(session.snapshot)), temperature \(MonitorMetric.temperature.formatted(session.snapshot)), memory \(MonitorMetric.memory.formatted(session.snapshot))"
    }
}
