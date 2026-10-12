import SwiftUI

struct ServerBrowser: View {
    @Bindable var model: MonitorModel
    let layout: ServerLayout
    var search = ""
    var compact = false
    @Environment(\.openWindow) private var openWindow

    private var sessions: [ServerSession] {
        model.sessions.filter { search.isEmpty || $0.connection.displayName.localizedStandardContains(search) }
            .sorted { $0.connection.displayName.localizedStandardCompare($1.connection.displayName) == .orderedAscending }
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 5)) { timeline in
            if sessions.isEmpty {
                ContentUnavailableView(search.isEmpty ? "No servers" : "No matching servers", systemImage: "server.rack",
                                       description: Text(search.isEmpty ? "Add an SSH connection to start monitoring." : "Try another server name."))
            } else if layout == .single {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Picker("Server", selection: $model.selectedID) {
                            ForEach(sessions) { Text($0.connection.displayName).tag(Optional($0.id)) }
                        }.onChange(of: model.selectedID) { if let id = model.selectedID { model.select(id) } }
                        ServerSummaryView(snapshot: model.snapshot, name: model.connection?.displayName, currentDate: timeline.date, compact: compact)
                        if let error = model.selectedSession?.error {
                            Label(error, systemImage: "exclamationmark.circle").font(.caption).foregroundStyle(PiTheme.warning)
                        }
                        if let snapshot = model.snapshot {
                            Divider()
                            TopProcessesView(snapshot: snapshot, limit: compact ? 3 : 5)
                        }
                        HStack {
                            Button("Processes", systemImage: "list.bullet.rectangle") { openWindow(id: "processes"); NSApp.activate() }
                                .disabled(model.selectedID == nil)
                            Spacer()
                            Menu("Connection", systemImage: "network") {
                                Button("Refresh readings") { Task { await model.refresh() } }.disabled(model.isRefreshing)
                                if model.selectedSession?.isSynthetic != true {
                                    Button("Edit connection…") { model.editSelected(); openWindow(id: "connection"); NSApp.activate() }
                                }
                            }.fixedSize().disabled(model.selectedID == nil)
                        }
                    }.padding(compact ? 16 : 24)
                }
            } else if layout == .list {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(sessions) { session in
                            if compact {
                                Button { model.select(session.id) } label: {
                                    VStack(alignment: .leading, spacing: 9) {
                                        HStack {
                                            Text(session.connection.displayName).font(.headline).lineLimit(1)
                                            if model.selectedID == session.id { Image(systemName: "checkmark.circle.fill").foregroundStyle(.tint) }
                                            Spacer()
                                            Text(session.error == nil ? ReadingStatus.label(session.snapshot, at: timeline.date) : "Disconnected")
                                                .font(.caption).foregroundStyle(.secondary)
                                        }
                                        HStack {
                                            ForEach([MonitorMetric.cpu, .gpu, .temperature, .memory]) { metric in
                                                VStack(alignment: .center, spacing: 3) {
                                                    Text(metric.rawValue).font(.caption2).foregroundStyle(.secondary)
                                                    Text(metric.formatted(session.snapshot)).font(.callout.monospacedDigit().weight(.semibold))
                                                        .foregroundStyle(metric.warning(session.snapshot) ? PiTheme.warning : PiTheme.ink)
                                                }.frame(maxWidth: .infinity, alignment: .center)
                                            }
                                        }
                                    }.padding(14).contentShape(.rect)
                                }.buttonStyle(.plain)
                                    .background(model.selectedID == session.id ? Color.accentColor.opacity(0.07) : .clear)
                            } else {
                                ServerOverviewRow(model: model, session: session, currentDate: timeline.date)
                            }
                            Divider()
                        }
                    }
                }
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: compact ? 200 : 260))], spacing: 12) {
                        ForEach(sessions) { session in
                            VStack(alignment: .leading, spacing: 12) {
                                Button { model.select(session.id) } label: {
                                    ServerTileView(record: .init(server: .init(id: session.id, name: session.connection.displayName), snapshot: session.snapshot), currentDate: timeline.date)
                                        .contentShape(.rect)
                                }.buttonStyle(.plain)
                                HStack {
                                    if model.selectedID == session.id { Label("Selected", systemImage: "checkmark.circle.fill").foregroundStyle(.tint) }
                                    Spacer()
                                    Button("Processes") { model.select(session.id); openWindow(id: "processes"); NSApp.activate() }
                                }.font(.caption)
                            }.padding(16)
                                .background(.background, in: .rect(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(model.selectedID == session.id ? Color.accentColor : Color.secondary.opacity(0.2)))
                        }
                    }.padding(16)
                }
            }
        }
    }
}
