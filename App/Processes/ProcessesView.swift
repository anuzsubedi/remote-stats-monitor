import SwiftUI

struct ProcessesView: View {
    @Bindable var model: MonitorModel
    @State private var search = ""

    private var filteredProcesses: [RemoteProcess] {
        model.snapshot?.processes.filter {
            search.isEmpty || $0.name.localizedStandardContains(search)
        } ?? []
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                Text("Processes")
                    .font(.largeTitle.weight(.bold))

                Spacer(minLength: 16)

                Menu {
                    ForEach(model.sessions) { session in
                        Button {
                            model.select(session.id)
                        } label: {
                            if model.selectedID == session.id {
                                Label(session.connection.displayName, systemImage: "checkmark")
                            } else {
                                Text(session.connection.displayName)
                            }
                        }
                    }
                } label: {
                    Label(model.connection?.displayName ?? "Select server", systemImage: "server.rack")
                        .lineLimit(1)
                }
                .frame(maxWidth: 240)
                .disabled(model.sessions.isEmpty)

                Button {
                    Task { await model.refresh() }
                } label: {
                    if model.isRefreshing {
                        HStack(spacing: 7) {
                            ProgressView().controlSize(.small)
                            Text("Refreshing…")
                        }
                    } else {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                }
                .disabled(model.isRefreshing || model.connection == nil)
            }
            .padding(24)

            Divider()

            VStack(alignment: .leading, spacing: 16) {
                TextField("Find a process", text: $search)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel("Find a process")
                    .frame(maxWidth: 380)

                if let snapshot = model.snapshot {
                    TimelineView(.periodic(from: .now, by: 5)) { timeline in
                        HStack {
                            Text(ReadingStatus.label(snapshot, at: timeline.date))
                                .font(.callout.weight(.medium))
                            Spacer()
                            Text("Updated \(snapshot.sampledAt, format: .dateTime.hour().minute().second())")
                                .font(.callout.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityElement(children: .combine)
                    }

                    if snapshot.processes.isEmpty {
                        ContentUnavailableView(
                            "No process readings",
                            systemImage: "list.bullet.rectangle",
                            description: Text("The latest server reading did not include any processes.")
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if filteredProcesses.isEmpty {
                        ContentUnavailableView.search(text: search)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            ProcessListView(processes: filteredProcesses, limit: 100, showsTitle: false)
                                .padding(.top, 4)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                } else {
                    ContentUnavailableView(
                        "No process readings",
                        systemImage: "list.bullet.rectangle",
                        description: Text("Connect a server to view its processes.")
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(minWidth: 600, minHeight: 440)
    }
}
