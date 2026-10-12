import SwiftUI

struct ServerOverviewMetric: View {
    let title: String
    let symbol: String
    let value: Double?
    var temperature = false
    var supportingValue: String? = nil
    var compact = false

    private var formattedValue: String {
        value.map {
            $0.formatted(.number.precision(.fractionLength(0))) + (temperature ? "°C" : "%")
        } ?? "—"
    }

    private var warning: Bool {
        guard let value else { return false }
        return value >= (temperature ? 80 : 90)
    }

    private var scale: Double? {
        guard let value else { return nil }
        return min(max(value, 0), 100) / 100
    }

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 6 : 9) {
            Label(title, systemImage: symbol)
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            HStack(alignment: .firstTextBaseline, spacing: 7) {
                Text(formattedValue)
                    .font(.system(size: compact ? 26 : 32, weight: .semibold)).monospacedDigit()
                    .foregroundStyle(warning ? PiTheme.warning : PiTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Spacer(minLength: 0)

                if warning {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(PiTheme.warning)
                        .accessibilityHidden(true)
                }
            }

            if let supportingValue {
                Text(supportingValue)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            if let scale {
                ProgressView(value: scale)
                    .tint(warning ? PiTheme.warning : PiTheme.accent)
                    .accessibilityHidden(true)
            } else {
                Color.clear.frame(height: 4).accessibilityHidden(true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, compact ? 8 : 14)
        .padding(.horizontal, compact ? 8 : 16)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title), \(formattedValue)\(supportingValue.map { ", " + $0 } ?? "")\(warning ? ", warning" : "")")
    }
}
