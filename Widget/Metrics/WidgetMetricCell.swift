import SwiftUI

struct WidgetMetricCell: View {
    let metric: MonitorMetric
    let snapshot: MonitorSnapshot?
    var compact = false
    var stacked = false

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 3 : 6) {
            if stacked {
                Text(metric == .temperature ? "Temp" : metric.rawValue)
                    .font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                Text(metric.formatted(snapshot))
                    .font(.system(size: 19, weight: .medium, design: .rounded))
                    .monospacedDigit().lineLimit(1).minimumScaleFactor(0.7)
            } else {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(metric == .temperature ? "Temp" : metric.rawValue)
                    .font(.caption2).foregroundStyle(.secondary)
                Spacer(minLength: 0)
                Text(metric.formatted(snapshot))
                    .font(compact ? .caption.weight(.semibold) : .title3.weight(.medium))
                    .monospacedDigit().lineLimit(1).minimumScaleFactor(0.7)
            }
            }
            WidgetUsageScale(value: snapshot.flatMap { metric.value($0) }, warning: metric.warning(snapshot))
        }.accessibilityElement(children: .combine)
    }
}

struct WidgetUsageScale: View {
    let value: Double?
    var warning = false

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(.quaternary)
                if let value {
                    Capsule().fill(warning ? Color.orange : Color.accentColor)
                        .frame(width: geometry.size.width * min(1, max(0, value / 100)))
                        .widgetAccentable()
                }
            }
        }.frame(height: 3).accessibilityHidden(true)
    }
}
