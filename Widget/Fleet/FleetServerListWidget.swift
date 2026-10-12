import SwiftUI
import WidgetKit

struct FleetServerListWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: "RemoteStatsMonitorFleetWidget",
            intent: FleetWidgetConfigurationIntent.self,
            provider: FleetProvider()
        ) { entry in
            FleetWidgetView(entry: entry)
        }
        .configurationDisplayName("Server List")
        .description("CPU, GPU, temperature, and memory for selected servers.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}
