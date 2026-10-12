import SwiftUI
import WidgetKit

struct FleetWidgetView: View {
    let entry: FleetEntry

    private let columns: [(title: String, metric: MonitorMetric)] = [
        ("°C", .temperature),
        ("CPU", .cpu),
        ("GPU", .gpu),
        ("MEM", .memory)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if entry.records.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Label("No servers selected", systemImage: "server.rack")
                        .font(.headline)
                    Text("Add servers in Remote Stats Monitor, then edit this widget to choose them.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxHeight: .infinity, alignment: .center)
            } else {
                HStack(spacing: 4) {
                    Text("Servers")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    ForEach(columns, id: \.title) { column in
                        Text(column.title)
                            .frame(width: 38, alignment: .trailing)
                    }
                }
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
                .padding(.bottom, 2)

                ForEach(Array(entry.records.prefix(entry.capacity).enumerated()), id: \.element.server.id) { index, record in
                    if index > 0 { Divider() }
                    WidgetFleetServerRow(record: record, date: entry.date, compact: entry.capacity == 4)
                        .frame(maxHeight: .infinity)
                }
            }
        }
        .containerBackground(for: .widget) { WidgetGlassBackground() }
    }
}
