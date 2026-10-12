import SwiftUI

struct WidgetMetricValue: View {
    let metric: MonitorMetric
    let snapshot: MonitorSnapshot?
    var font: Font = .title3.weight(.semibold)
    var alignment: Alignment = .trailing
    var expands = true

    private var warning: Bool { metric.warning(snapshot) }

    private var warningDescription: String {
        metric == .temperature ? "high temperature" : "high \(metric.rawValue.lowercased()) use"
    }

    var body: some View {
        HStack(spacing: 3) {
            if warning {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.caption2.weight(.semibold))
                    .accessibilityHidden(true)
            }
            Text(metric.formatted(snapshot))
                .font(font)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .foregroundStyle(warning ? Color.orange : Color.primary)
        .frame(maxWidth: expands ? .infinity : nil, alignment: alignment)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(metric.formatted(snapshot) + (warning ? ", \(warningDescription)" : ""))
    }
}
