import SwiftUI
import WidgetKit

struct MetricView: View {
    let title: String
    let value: String
    let fraction: Double?
    let compact: Bool
    var warning = false

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 4 : 9) {
            Text(title).font(compact ? .caption : .subheadline).foregroundStyle(PiTheme.secondary)
            Text(value)
                .font(compact ? .title2.weight(.semibold) : .largeTitle.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(warning ? Color.orange : PiTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
                .widgetAccentable()
            if let fraction {
                ProgressView(value: max(0, min(1, fraction)))
                .progressViewStyle(.linear)
                .tint(fraction >= 0.9 ? PiTheme.warning : PiTheme.accent)
                .frame(height: compact ? 4 : 6)
                .accessibilityHidden(true)
            } else {
                Color.clear.frame(height: compact ? 4 : 6).accessibilityHidden(true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title), \(value)")
    }
}
