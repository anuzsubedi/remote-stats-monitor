import SwiftUI
import WidgetKit

struct MetricWidgetView: View {
    let entry: PiEntry
    let metric: MonitorMetric
    @Environment(\.widgetFamily) private var family
    var previewFamily: WidgetFamily? = nil

    var body: some View {
        WidgetServerContainer(entry: entry) {
            if entry.missingServerName != nil {
                WidgetMissingServerMessage()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else if (previewFamily ?? family) == .systemMedium {
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Text(metric.rawValue)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.secondary)
                            Spacer()
                            Image(systemName: metric.symbol)
                                .font(.title3)
                                .foregroundStyle(.secondary)
                                .accessibilityHidden(true)
                        }
                        WidgetMetricValue(
                            metric: metric,
                            snapshot: entry.snapshot,
                            font: .system(.largeTitle, design: .default, weight: .semibold),
                            alignment: .leading
                        )
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .leading, spacing: 6) {
                        WidgetUsageScale(value: entry.snapshot.flatMap { metric.value($0) }, warning: metric.warning(entry.snapshot))
                        HStack {
                            Text("0")
                            Spacer()
                            Text(metric == .temperature ? "100°C" : "100%")
                        }
                        .font(.caption2)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                        WidgetStatusLabel(snapshot: entry.snapshot, date: entry.date)
                    }
                    .frame(width: 140)
                    .frame(maxHeight: .infinity, alignment: .center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 6) {
                        Text(metric.rawValue)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Image(systemName: metric.symbol)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                            .accessibilityHidden(true)
                    }
                    .padding(.bottom, 4)
                    WidgetMetricValue(
                        metric: metric,
                        snapshot: entry.snapshot,
                        font: .system(.largeTitle, design: .default, weight: .semibold),
                        alignment: .leading
                    )
                    .padding(.bottom, 8)
                    WidgetUsageScale(value: entry.snapshot.flatMap { metric.value($0) }, warning: metric.warning(entry.snapshot))
                    HStack {
                        Text("0")
                        Spacer()
                        Text(metric == .temperature ? "100°C" : "100%")
                    }
                    .font(.caption2)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .padding(.top, 3)
                    Spacer(minLength: 4)
                    WidgetStatusLabel(snapshot: entry.snapshot, date: entry.date)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
    }
}
