import SwiftUI

struct ServerBrowser: View {
    @Bindable var model: MonitorModel
    let layout: ServerLayout
    var search = ""
    var compact = false
    var onShowProcesses: (() -> Void)? = nil

    @Environment(\.openWindow) private var openWindow

    private var sessions: [ServerSession] {
        model.sessions
            .filter { search.isEmpty || $0.connection.displayName.localizedStandardContains(search) || $0.connection.address.localizedStandardContains(search) }
            .sorted { $0.connection.displayName.localizedStandardCompare($1.connection.displayName) == .orderedAscending }
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 5)) { timeline in
            switch layout {
            case .single:
                ServerDetailView(
                    model: model,
                    currentDate: timeline.date,
                    compact: compact,
                    showsServerPicker: true,
                    onShowProcesses: showProcesses
                )
            case .list:
                listView(currentDate: timeline.date)
            case .grid:
                gridView(currentDate: timeline.date)
            }
        }
    }

    @ViewBuilder
    private func listView(currentDate: Date) -> some View {
        if sessions.isEmpty {
            emptyView
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(sessions) { session in
                        if compact {
                            compactServerRow(session, currentDate: currentDate)
                        } else {
                            ServerOverviewRow(model: model, session: session, currentDate: currentDate)
                        }
                        Divider().padding(.leading, compact ? 18 : 24)
                    }
                }
                .padding(.vertical, compact ? 6 : 8)
            }
        }
    }

    private func compactServerRow(_ session: ServerSession, currentDate: Date) -> some View {
        let isSelected = session.id == model.selectedID
        let status = session.error == nil
            ? (session.isSynthetic ? "Test server" : ReadingStatus.label(session.snapshot, at: currentDate))
            : "Disconnected"

        return Button { model.select(session.id) } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    Image(systemName: session.connection.iconName)
                        .font(.title3)
                        .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                        .frame(width: 22)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(session.connection.displayName)
                            .font(.body.weight(.medium))
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Text(status)
                            .font(.caption)
                            .foregroundStyle(session.error == nil ? Color.secondary : PiTheme.warning)
                    }

                    Spacer(minLength: 4)

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.tint)
                    }
                }

                HStack(spacing: 10) {
                    ForEach([MonitorMetric.cpu, .gpu, .temperature, .memory]) { metric in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(metric == .temperature ? "Temp" : metric.rawValue)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(metric.formatted(session.snapshot))
                                .font(.caption.monospacedDigit().weight(.semibold))
                                .foregroundStyle(metric.warning(session.snapshot) ? PiTheme.warning : PiTheme.ink)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.leading, 34)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .contentShape(.rect(cornerRadius: 9))
            .background(isSelected ? Color.accentColor.opacity(0.09) : .clear, in: .rect(cornerRadius: 9))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 8)
        .accessibilityLabel("\(session.connection.displayName), \(status), CPU \(MonitorMetric.cpu.formatted(session.snapshot)), GPU \(MonitorMetric.gpu.formatted(session.snapshot)), temperature \(MonitorMetric.temperature.formatted(session.snapshot)), memory \(MonitorMetric.memory.formatted(session.snapshot))")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    @ViewBuilder
    private func gridView(currentDate: Date) -> some View {
        if sessions.isEmpty {
            emptyView
        } else {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: compact ? 205 : 260), spacing: 12)], spacing: 12) {
                    ForEach(sessions) { session in
                        VStack(alignment: .leading, spacing: 12) {
                            Button { model.select(session.id) } label: {
                                ServerTileView(
                                    record: .init(
                                        server: .init(
                                            id: session.id,
                                            name: session.connection.displayName,
                                            iconName: session.connection.iconName
                                        ),
                                        snapshot: session.snapshot
                                    ),
                                    currentDate: currentDate
                                )
                                .contentShape(.rect)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(session.connection.displayName), \(ReadingStatus.label(session.snapshot, at: currentDate)), CPU \(MonitorMetric.cpu.formatted(session.snapshot)), GPU \(MonitorMetric.gpu.formatted(session.snapshot)), temperature \(MonitorMetric.temperature.formatted(session.snapshot)), memory \(MonitorMetric.memory.formatted(session.snapshot))")
                            .accessibilityAddTraits(session.id == model.selectedID ? .isSelected : [])

                            HStack {
                                if session.id == model.selectedID {
                                    Label("Selected", systemImage: "checkmark.circle.fill")
                                        .foregroundStyle(.tint)
                                }
                                Spacer()
                                Button("Processes") {
                                    model.select(session.id)
                                    showProcesses()
                                }
                                .help("Open this server's processes")
                            }
                            .font(.caption)
                        }
                        .padding(14)
                        .background(.background, in: .rect(cornerRadius: 12))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(session.id == model.selectedID ? Color.accentColor : Color.secondary.opacity(0.2))
                        }
                    }
                }
                .padding(14)
            }
        }
    }

    private var emptyView: some View {
        ContentUnavailableView(
            search.isEmpty ? "No servers" : "No matching servers",
            systemImage: "server.rack",
            description: Text(search.isEmpty ? "Add an SSH connection to start monitoring." : "Try another server name.")
        )
    }

    private func showProcesses() {
        if let onShowProcesses {
            onShowProcesses()
        } else {
            openWindow(id: "processes")
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
