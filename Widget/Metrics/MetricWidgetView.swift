import SwiftUI
import WidgetKit

struct MetricWidgetView: View {
    let entry: PiEntry
    let metric: MonitorMetric

    var body: some View {
        WidgetServerContainer(entry: entry) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(metric.formatted(entry.snapshot))
                        .font(.system(size: 36, weight: .medium, design: .rounded))
                        .monospacedDigit().minimumScaleFactor(0.6).lineLimit(1)
                    Spacer(minLength: 0)
                    Image(systemName: metric.symbol).font(.title3).foregroundStyle(.secondary)
                }.frame(maxHeight: .infinity)
                HStack {
                    Text(metric.rawValue).fontWeight(.medium)
                    Spacer()
                    Text(metric == .temperature ? "°C" : "%").foregroundStyle(.secondary)
                }.font(.caption)
                WidgetUsageScale(value: entry.snapshot.flatMap { metric.value($0) }, warning: metric.warning(entry.snapshot))
                HStack {
                    Text("0")
                    Spacer()
                    Text("100")
                }.font(.system(size: 9)).monospacedDigit().foregroundStyle(.secondary)
                Text(entry.missingServerName == nil ? ReadingStatus.label(entry.snapshot, at: entry.date) : "Server unavailable")
                    .font(.caption2).foregroundStyle(.secondary)
            }
        }
    }
}
