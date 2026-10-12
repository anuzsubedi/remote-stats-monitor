import SwiftUI

struct ServerOverviewRow: View {
    @Bindable var model: MonitorModel
    let session: ServerSession
    let currentDate: Date
    @Environment(\.openWindow) private var openWindow

    private var status: String {
        if session.isRefreshing { return "Updating…" }
        if session.error != nil || session.snapshot?.connectionError != nil { return "Disconnected" }
        guard let reading = session.snapshot else { return "Waiting for first reading" }
        if session.isSynthetic { return "Test server" }
        return reading.isStale(at: currentDate) ? "Last reading" : "Connected"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: session.connection.iconName).font(.title2).foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 4) {
                    Button(action: select) {
                        HStack(spacing: 7) {
                            Text(session.connection.displayName).font(.headline).lineLimit(1).truncationMode(.middle)
                            if session.id == model.selectedID {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(.tint)
                            }
                        }
                    }.buttonStyle(.plain).help("Show this server in the menu bar")
                    HStack(spacing: 5) {
                        Text(status)
                        if let reading = session.snapshot {
                            Text("·")
                            Text(reading.sampledAt, format: .dateTime.hour().minute().second())
                        }
                    }.font(.caption).foregroundStyle(session.error != nil ? PiTheme.warning : PiTheme.secondary)
                }
                Spacer()
                Button("Processes", action: showProcesses).buttonStyle(.glass)
                Menu("Server actions", systemImage: "ellipsis") {
                    Button("Show in menu bar", action: select)
                    Button("Refresh readings") { Task { await model.refreshServer(id: session.id) } }
                        .disabled(session.isRefreshing)
                    if !session.isSynthetic {
                        Button("Edit connection…", action: editConnection)
                    }
                }.menuStyle(.borderlessButton).labelStyle(.iconOnly).fixedSize()
            }
            HStack(spacing: 24) {
                ServerOverviewMetric(title: "Temperature", symbol: "thermometer.medium", value: session.snapshot?.temperature, temperature: true)
                ServerOverviewMetric(title: "CPU", symbol: "cpu", value: session.snapshot?.cpu)
                ServerOverviewMetric(title: "GPU", symbol: "display", value: session.snapshot?.gpu)
                ServerOverviewMetric(title: "Memory", symbol: "memorychip", value: session.snapshot.map { $0.memoryFraction * 100 })
            }
            if let error = session.error {
                Label(error, systemImage: "exclamationmark.circle")
                    .font(.caption).foregroundStyle(PiTheme.warning).lineLimit(2).help(error)
            }
        }.padding(24)
            .background(session.id == model.selectedID ? Color.accentColor.opacity(0.05) : Color.clear)
    }

    private func select() { model.select(session.id) }
    private func showProcesses() { select(); openWindow(id: "processes"); NSApp.activate() }
    private func editConnection() { select(); model.editSelected(); openWindow(id: "connection"); NSApp.activate() }
}
