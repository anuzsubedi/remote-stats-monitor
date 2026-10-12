import SwiftUI
import WidgetKit

struct PiWidgetContentView: View {
    let entry: PiEntry
    let family: WidgetFamily

    var body: some View {
        WidgetServerContainer(entry: entry) {
            if entry.missingServerName != nil {
                Text("Server unavailable").font(.headline)
                Text("Edit this widget to choose a saved server.").font(.caption).foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: family == .systemSmall ? 10 : 14) {
                    Grid(horizontalSpacing: 18, verticalSpacing: family == .systemSmall ? 8 : 16) {
                        GridRow {
                            WidgetMetricCell(metric: .cpu, snapshot: entry.snapshot, compact: family == .systemSmall, stacked: family == .systemSmall)
                            WidgetMetricCell(metric: .memory, snapshot: entry.snapshot, compact: family == .systemSmall, stacked: family == .systemSmall)
                        }
                        GridRow {
                            WidgetMetricCell(metric: .gpu, snapshot: entry.snapshot, compact: family == .systemSmall, stacked: family == .systemSmall)
                            WidgetMetricCell(metric: family == .systemSmall ? .temperature : .disk, snapshot: entry.snapshot, compact: family == .systemSmall, stacked: family == .systemSmall)
                        }
                    }.frame(maxHeight: .infinity)
                    if family != .systemSmall {
                        HStack {
                            Label(MonitorMetric.temperature.formatted(entry.snapshot), systemImage: "thermometer.medium")
                            Spacer()
                            Text(ReadingStatus.label(entry.snapshot, at: entry.date)).foregroundStyle(.secondary)
                        }.font(.caption)
                    } else {
                        Text(ReadingStatus.label(entry.snapshot, at: entry.date)).font(.caption2).foregroundStyle(.secondary)
                    }
                    if family == .systemLarge {
                        Divider()
                        WidgetProcessRows(snapshot: entry.snapshot, limit: 5)
                    }
                }
            }
        }
    }
}
