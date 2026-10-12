import SwiftUI

struct ProcessesView: View {
    @Bindable var model: MonitorModel
    @State private var search = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Processes").font(.largeTitle.weight(.bold))
                Spacer()
                Menu(model.connection?.displayName ?? "Servers") {
                    ForEach(model.sessions) { session in
                        Button(session.connection.displayName) { model.select(session.id) }
                    }
                }.fixedSize()
                Spacer()
                Button("Refresh", systemImage: "arrow.clockwise") { Task { await model.refresh() } }
                    .disabled(model.isRefreshing || model.connection == nil)
            }
            TextField("Find a process", text: $search)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel("Find a process")
            if let snapshot = model.snapshot {
                TimelineView(.periodic(from: .now, by: 5)) { timeline in
                    HStack {
                        Text(ReadingStatus.label(snapshot, at: timeline.date))
                        Text(snapshot.sampledAt, format: .dateTime.hour().minute().second())
                    }.font(.caption).foregroundStyle(.secondary)
                }
                Text("Up to 100 processes with the highest CPU or memory usage.")
                    .font(.caption).foregroundStyle(.secondary)
                ScrollView {
                    ProcessListView(processes: snapshot.processes.filter { search.isEmpty || $0.name.localizedStandardContains(search) }, limit: 100, showsTitle: false)
                }
            } else {
                ContentUnavailableView("No process readings", systemImage: "list.bullet.rectangle", description: Text("Connect a server to view its processes."))
            }
        }
        .padding(24)
        .frame(minWidth: 540, minHeight: 360)
    }
}
