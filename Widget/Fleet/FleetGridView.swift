import SwiftUI
import WidgetKit

struct FleetGridView: View {
    let entry: FleetEntry

    var body: some View {
        Group {
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
                Grid(horizontalSpacing: 16, verticalSpacing: 10) {
                    ForEach(0..<(min(entry.records.count, entry.capacity) + 1) / 2, id: \.self) { row in
                        GridRow {
                            ForEach(0..<2, id: \.self) { column in
                                let index = row * 2 + column
                                if index < min(entry.records.count, entry.capacity) {
                                    WidgetFleetTile(record: entry.records[index], date: entry.date)
                                } else { Color.clear }
                            }
                        }
                    }
                }
            }
        }.containerBackground(for: .widget) { WidgetGlassBackground() }
    }
}
