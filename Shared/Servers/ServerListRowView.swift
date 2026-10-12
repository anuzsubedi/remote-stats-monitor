import SwiftUI

struct ServerListRowView: View {
    let record: ServerSnapshotRecord
    let currentDate: Date
    let compact: Bool

    var body: some View {
        let snapshot = record.snapshot
        let temperature = temperatureValue(snapshot)
        let cpu = percentage(snapshot?.cpu)
        let gpu = percentage(snapshot?.gpu)
        let memory = percentage(snapshot.map { $0.memoryFraction * 100 })

        HStack(spacing: 6) {
            VStack(alignment: .leading, spacing: 1) {
                Text(record.server.name)
                    .font(compact ? .caption.weight(.semibold) : .subheadline.weight(.semibold))
                    .lineLimit(1)
                    .truncationMode(.middle)

                Text(freshness(snapshot))
                    .font(.caption)
                    .foregroundStyle(freshnessColor(snapshot))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(temperature)
                .font(metricFont)
                .foregroundStyle(snapshot?.hasHighTemperature == true ? PiTheme.warning : PiTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(width: 36, alignment: .center)
                .widgetAccentable()

            Text(cpu)
                .font(metricFont)
                .foregroundStyle((snapshot?.cpu ?? 0) >= 90 ? PiTheme.warning : PiTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(width: 34, alignment: .center)
                .widgetAccentable()

            Text(gpu)
                .font(metricFont)
                .foregroundStyle((snapshot?.gpu ?? 0) >= 90 ? PiTheme.warning : PiTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(width: 34, alignment: .center)
                .widgetAccentable()

            Text(memory)
                .font(metricFont)
                .foregroundStyle((snapshot?.memoryFraction ?? 0) >= 0.9 ? PiTheme.warning : PiTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(width: 40, alignment: .center)
                .widgetAccentable()
        }
        .padding(.vertical, compact ? 1 : 2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(record.server.name), \(freshness(snapshot)), temperature \(temperature) Celsius, CPU \(cpu), GPU \(gpu), memory \(memory)")
    }

    private var metricFont: Font {
        (compact ? Font.caption : .subheadline).monospacedDigit().weight(.medium)
    }

    private func temperatureValue(_ snapshot: MonitorSnapshot?) -> String {
        guard let temperature = snapshot?.temperature else { return "—" }
        return temperature.formatted(.number.precision(.fractionLength(0))) + "°"
    }

    private func percentage(_ value: Double?) -> String {
        guard let value else { return "—" }
        return value.formatted(.number.precision(.fractionLength(0))) + "%"
    }

    private func freshness(_ snapshot: MonitorSnapshot?) -> String {
        guard let snapshot else { return "No reading" }
        let time = snapshot.sampledAt.formatted(.dateTime.hour().minute())
        if snapshot.connectionError != nil { return "Disconnected · \(time)" }
        if snapshot.isSample { return "Sample · \(time)" }
        if snapshot.isStale(at: currentDate) { return "Last reading · \(time)" }
        return "Updated · \(time)"
    }

    private func freshnessColor(_ snapshot: MonitorSnapshot?) -> Color {
        guard let snapshot else { return PiTheme.warning }
        if snapshot.connectionError != nil || snapshot.isStale(at: currentDate) {
            return PiTheme.warning
        }
        if snapshot.isSample { return PiTheme.secondary }
        return PiTheme.connected
    }
}
