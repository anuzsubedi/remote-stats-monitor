import SwiftUI

struct ServerDetailView: View {
    @Bindable var model: MonitorModel
    let currentDate: Date
    var compact = false
    var showsServerPicker = false

    @Environment(\.openWindow) private var openWindow

    private var session: ServerSession? { model.selectedSession }
    private var snapshot: MonitorSnapshot? { session?.snapshot }
    private var serverName: String { session?.connection.displayName ?? "No server selected" }
    private var status: String {
        guard let session else { return "No reading" }
        if session.isRefreshing { return "Updating" }
        if session.error != nil || snapshot?.connectionError != nil { return "Disconnected" }
        if session.isSynthetic { return "Test server" }
        return ReadingStatus.label(snapshot, at: currentDate)
    }
    private var statusColor: Color {
        if status == "Disconnected" || status == "Last reading" || status == "High temperature" { return PiTheme.warning }
        if status == "Connected" { return PiTheme.connected }
        return .secondary
    }

    private var selection: Binding<UUID?> {
        Binding(
            get: { model.selectedID },
            set: { if let id = $0 { model.select(id) } }
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()

            if model.sessions.isEmpty {
                ContentUnavailableView(
                    "No servers yet",
                    systemImage: "server.rack",
                    description: Text("Add an SSH connection to view its readings.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if session == nil {
                ContentUnavailableView(
                    "No server selected",
                    systemImage: "server.rack",
                    description: Text("Choose a server to view its readings.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: compact ? 12 : 24) {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: compact ? 8 : 12) {
                            ServerOverviewMetric(title: "CPU", symbol: "cpu", value: snapshot?.cpu, compact: compact)
                            ServerOverviewMetric(title: "Temperature", symbol: "thermometer.medium", value: snapshot?.temperature, temperature: true, compact: compact)
                            ServerOverviewMetric(
                                title: "Memory",
                                symbol: "memorychip",
                                value: snapshot.map { $0.memoryFraction * 100 },
                                supportingValue: snapshot.map { byteSummary(used: $0.memoryUsed, total: $0.memoryTotal) },
                                compact: compact
                            )
                            ServerOverviewMetric(
                                title: "Disk",
                                symbol: "internaldrive",
                                value: snapshot.map { $0.diskFraction * 100 },
                                supportingValue: snapshot.map { byteSummary(used: $0.diskUsed, total: $0.diskTotal) },
                                compact: compact
                            )
                        }

                        if let error = session?.error {
                            Label(error, systemImage: "exclamationmark.triangle.fill")
                                .font(.callout)
                                .foregroundStyle(PiTheme.warning)
                                .lineLimit(3)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        if let snapshot {
                            HStack(spacing: 16) {
                                supportingReading(
                                    title: "GPU",
                                    value: MonitorMetric.gpu.formatted(snapshot),
                                    symbol: "display"
                                )
                                Divider().frame(height: 24)
                                supportingReading(
                                    title: "Uptime",
                                    value: formattedUptime(snapshot.uptime),
                                    symbol: "clock"
                                )
                                Spacer(minLength: 0)
                            }

                            Divider()

                            TopProcessesView(snapshot: snapshot, limit: compact ? 3 : 6)
                        } else {
                            ContentUnavailableView(
                                "Waiting for readings",
                                systemImage: "arrow.trianglehead.2.clockwise.rotate.90",
                                description: Text("Refresh the connection to request a new reading.")
                            )
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(compact ? 12 : 24)
                }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                if showsServerPicker && !model.sessions.isEmpty {
                    Picker("Server", selection: selection) {
                        ForEach(sortedSessions) { session in
                            Text(session.connection.displayName).tag(Optional(session.id))
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .font(.title3.weight(.semibold))
                    .accessibilityLabel("Selected server")
                } else {
                    Text(serverName)
                        .font(compact ? .title3.weight(.semibold) : .title2.weight(.semibold))
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                HStack(spacing: 6) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 7, height: 7)
                        .accessibilityHidden(true)
                    Text(status)
                        .lineLimit(1)
                        .foregroundStyle(statusColor)
                    if let sampledAt = snapshot?.sampledAt {
                        Text("·").foregroundStyle(.tertiary)
                        Text(sampledAt, format: .dateTime.hour().minute())
                            .foregroundStyle(.secondary)
                    }
                }
                .font(.caption)
            }

            Spacer(minLength: 4)

            if let session {
                Button("Processes", systemImage: "list.bullet.rectangle") {
                    openWindow(id: "processes")
                    NSApp.activate()
                }
                .labelStyle(.iconOnly)
                .help("Open processes")
                .disabled(session.snapshot == nil)

                Menu("Connection", systemImage: "ellipsis") {
                    Button("Refresh readings") { Task { await model.refreshServer(id: session.id) } }
                        .disabled(session.isRefreshing)
                    if !session.isSynthetic {
                        Button("Edit connection…") {
                            model.editSelected()
                            openWindow(id: "connection")
                            NSApp.activate()
                        }
                    }
                }
                .labelStyle(.iconOnly)
                .menuStyle(.borderlessButton)
                .fixedSize()
                .help("Connection actions")
            }
        }
        .padding(.horizontal, compact ? 16 : 24)
        .padding(.vertical, compact ? 12 : 18)
    }

    private var sortedSessions: [ServerSession] {
        model.sessions.sorted {
            $0.connection.displayName.localizedStandardCompare($1.connection.displayName) == .orderedAscending
        }
    }

    private func supportingReading(title: String, value: String, symbol: String) -> some View {
        HStack(spacing: 6) {
            Label(title, systemImage: symbol)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.monospacedDigit().weight(.medium))
        }
        .accessibilityElement(children: .combine)
    }

    private func byteSummary(used: Double, total: Double) -> String {
        "\((used / 1e9).formatted(.number.precision(.fractionLength(1)))) of \((total / 1e9).formatted(.number.precision(.fractionLength(1)))) GB"
    }

    private func formattedUptime(_ seconds: Double) -> String {
        let minutes = Int(max(0, seconds) / 60)
        let days = minutes / (24 * 60)
        let hours = (minutes / 60) % 24
        let remainingMinutes = minutes % 60
        if days > 0 { return "\(days)d \(hours)h" }
        if hours > 0 { return "\(hours)h \(remainingMinutes)m" }
        return "\(remainingMinutes)m"
    }
}
