import SwiftUI
import WidgetKit

struct FleetGridWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "RemoteStatsFleetGrid", intent: FleetWidgetConfigurationIntent.self, provider: FleetProvider()) { entry in
            FleetGridView(entry: entry)
        }
        .configurationDisplayName("Server Grid")
        .description("Compare up to four or eight selected servers.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}
