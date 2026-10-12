import SwiftUI

struct WidgetStatusLabel: View {
    let snapshot: MonitorSnapshot?
    let date: Date
    var compact = false

    private var status: String { ReadingStatus.label(snapshot, at: date) }
    private var isDisconnected: Bool { snapshot?.connectionError != nil }
    private var isHighTemperature: Bool { snapshot?.hasHighTemperature == true }
    private var isWarning: Bool { isDisconnected || isHighTemperature }

    private var visibleStatus: String {
        guard isHighTemperature, status != "High temperature" else { return status }
        return status + " · High temperature"
    }

    private var symbol: String? {
        if isDisconnected { return "exclamationmark.circle.fill" }
        if isHighTemperature { return "thermometer.high" }
        return nil
    }

    var body: some View {
        HStack(spacing: 4) {
            if let symbol {
                Image(systemName: symbol)
                    .font(compact ? .caption2.weight(.semibold) : .caption.weight(.semibold))
                    .accessibilityHidden(true)
            }
            Text(visibleStatus)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .font(compact ? .caption2 : .caption)
        .foregroundStyle(isWarning ? Color.orange : Color.secondary)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(visibleStatus)
    }
}
