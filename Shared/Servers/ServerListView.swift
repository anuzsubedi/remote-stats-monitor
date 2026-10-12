import SwiftUI

struct ServerListView: View {
    let records: [ServerSnapshotRecord]
    let capacity: Int
    let currentDate: Date

    private var visibleRecords: [ServerSnapshotRecord] {
        Array(records.prefix(max(0, capacity)))
    }

    private var compact: Bool { capacity <= 4 }

    var body: some View {
        if visibleRecords.isEmpty {
            ContentUnavailableView(
                "No servers",
                systemImage: "server.rack",
                description: Text("Add an SSH server in Remote Stats Monitor to see its readings here.")
            )
            .padding(compact ? 12 : 16)
        } else {
            VStack(alignment: .leading, spacing: compact ? 4 : 5) {
                HStack(spacing: 6) {
                    Text("Server")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("°C").frame(width: 36, alignment: .center)
                    Text("CPU").frame(width: 34, alignment: .center)
                    Text("GPU").frame(width: 34, alignment: .center)
                    Text("MEM").frame(width: 40, alignment: .center)
                }
                .font(.caption.weight(.medium))
                .foregroundStyle(PiTheme.secondary)
                .accessibilityHidden(true)

                ForEach(Array(visibleRecords.enumerated()), id: \.element.server.id) { index, record in
                    ServerListRowView(record: record, currentDate: currentDate, compact: compact)

                    if index < visibleRecords.count - 1 {
                        Divider()
                    }
                }
            }
            .padding(.horizontal, compact ? 10 : 12)
            .padding(.vertical, compact ? 8 : 10)
            .foregroundStyle(PiTheme.ink)
        }
    }
}

#Preview("Server list · medium") {
    let now = Date.now
    let records = ["pi5.local", "nas.local", "build.local", "studio.local"].enumerated().map { index, name in
        var snapshot = MonitorSnapshot.sample
        snapshot.host = name
        let cpus: [Double] = [18, 42, 8, 67]
        let temperatures: [Double?] = [47, 55, nil, 72]
        let gpus: [Double?] = [nil, 31, 0, nil]
        snapshot.cpu = cpus[index]
        snapshot.temperature = temperatures[index]
        snapshot.gpu = gpus[index]
        snapshot.sampledAt = now.addingTimeInterval(-Double(index * 19))
        return ServerSnapshotRecord(server: ServerDescriptor(id: UUID(), name: name), snapshot: snapshot)
    }

    ServerListView(records: records, capacity: 4, currentDate: now)
        .frame(width: 360, height: 170)
        .containerBackground(.background, for: .widget)
}
