import SwiftUI
import WidgetKit

struct ProcessesWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "RemoteStatsProcesses", intent: PiWidgetConfigurationIntent.self, provider: PiProvider(kind: "RemoteStatsProcesses")) { entry in
            ProcessesWidgetView(entry: entry)
        }
        .configurationDisplayName("Processes")
        .description("The highest CPU processes on a selected server.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}
