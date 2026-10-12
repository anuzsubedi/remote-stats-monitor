import SwiftUI

struct WidgetMetricCell: View {
    let metric: MonitorMetric
    let snapshot: MonitorSnapshot?
    var compact = false
    var stacked = false

    private var title: String {
        metric == .temperature ? "Temp" : metric.rawValue
    }

    private var warningDescription: String {
        metric == .temperature ? "high temperature" : "high \(metric.rawValue.lowercased()) use"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 2 : 6) {
            if stacked {
                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                WidgetMetricValue(
                    metric: metric,
                    snapshot: snapshot,
                    font: .title3.weight(.semibold),
                    alignment: .leading
                )
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(title)
                        .font(compact ? .caption2.weight(.medium) : .caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Spacer(minLength: 2)
                    WidgetMetricValue(
                        metric: metric,
                        snapshot: snapshot,
                        font: compact ? .caption.weight(.semibold) : .title3.weight(.semibold)
                    )
                }
            }
            WidgetUsageScale(value: snapshot.flatMap { metric.value($0) }, warning: metric.warning(snapshot))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(metric.rawValue + ", " + metric.formatted(snapshot) + (metric.warning(snapshot) ? ", \(warningDescription)" : ""))
    }
}
