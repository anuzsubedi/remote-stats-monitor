import SwiftUI
import WidgetKit

struct FleetGridView: View {
    let entry: FleetEntry

    var body: some View {
        Group {
            if entry.records.isEmpty {
                Text("Add servers in Remote Stats Monitor, then edit this widget to choose them.").font(.caption)
            } else {
                Grid(horizontalSpacing: 12, verticalSpacing: 8) {
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
        }.containerBackground(.background, for: .widget)
    }
}
