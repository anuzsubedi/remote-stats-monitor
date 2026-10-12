import SwiftUI
import WidgetKit

struct PiWidgetContentView: View {
    let entry: PiEntry
    let family: WidgetFamily

    var body: some View {
        WidgetServerContainer(entry: entry) {
            if entry.missingServerName != nil {
                WidgetMissingServerMessage()
                .frame(maxHeight: .infinity, alignment: .center)
            } else {
                VStack(alignment: .leading, spacing: family == .systemSmall ? 10 : 12) {
                    Grid(horizontalSpacing: 18, verticalSpacing: family == .systemSmall ? 8 : 16) {
                        GridRow {
                            WidgetMetricCell(metric: .cpu, snapshot: entry.snapshot, compact: family == .systemSmall, stacked: family == .systemSmall)
                            WidgetMetricCell(metric: .memory, snapshot: entry.snapshot, compact: family == .systemSmall, stacked: family == .systemSmall)
                        }
                        GridRow {
                            WidgetMetricCell(metric: .gpu, snapshot: entry.snapshot, compact: family == .systemSmall, stacked: family == .systemSmall)
                            WidgetMetricCell(metric: family == .systemSmall ? .temperature : .disk, snapshot: entry.snapshot, compact: family == .systemSmall, stacked: family == .systemSmall)
                        }
                    }
                    if family != .systemSmall {
                        HStack(spacing: 5) {
                            Image(systemName: "thermometer.medium")
                                .foregroundStyle(MonitorMetric.temperature.warning(entry.snapshot) ? Color.orange : Color.secondary)
                                .accessibilityHidden(true)
                            WidgetMetricValue(
                                metric: .temperature,
                                snapshot: entry.snapshot,
                                font: .caption.weight(.semibold),
                                expands: false
                            )
                            Spacer(minLength: 4)
                            WidgetStatusLabel(snapshot: entry.snapshot, date: entry.date)
                        }
                        .font(.caption)
                        .accessibilityElement(children: .combine)
                    } else {
                        WidgetStatusLabel(snapshot: entry.snapshot, date: entry.date)
                    }
                    if family == .systemLarge {
                        Divider()
                        WidgetProcessRows(snapshot: entry.snapshot, limit: 5, spacious: true)
                    }
                }
                .frame(maxHeight: .infinity, alignment: .topLeading)
            }
        }
    }
}
