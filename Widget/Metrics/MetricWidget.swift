import SwiftUI
import WidgetKit

struct MetricWidget: Widget {
    let metric: MonitorMetric
    init() { metric = .cpu }
    init(metric: MonitorMetric) { self.metric = metric }

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "RemoteStatsMetric" + metric.id, intent: PiWidgetConfigurationIntent.self, provider: PiProvider(kind: "RemoteStatsMetric" + metric.id)) { entry in
            MetricWidgetView(entry: entry, metric: metric)
        }
        .configurationDisplayName(metric.rawValue)
        .description("Live usage readings for a selected server.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
