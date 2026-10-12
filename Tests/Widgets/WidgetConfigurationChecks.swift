import SwiftUI
import WidgetKit

@main enum WidgetConfigurationChecks {
    static func main() {
        // Construct the actual configurations, including their gallery metadata.
        // Interpolated LocalizedStringKey descriptions trap here in WidgetKit.
        for metric in MonitorMetric.allCases { _ = MetricWidget(metric: metric).body }
        _ = FleetServerListWidget().body
        _ = FleetGridWidget().body
        _ = ProcessesWidget().body
        print("Widget configurations passed: metric descriptions, server list, server grid and processes.")
    }
}
