import SwiftUI
import WidgetKit

struct RemoteStatsMonitorWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: SnapshotStore.widgetKind, intent: PiWidgetConfigurationIntent.self, provider: PiProvider()) { PiWidgetView(entry: $0) }
            .configurationDisplayName("Server Overview")
            .description("CPU, GPU, temperature, memory, and disk usage for a selected server.")
            .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

@main
struct RemoteStatsMonitorWidgetBundle: WidgetBundle {
    var body: some Widget {
        RemoteStatsMonitorWidget()
        FleetServerListWidget()
        FleetGridWidget()
        CPUWidget()
        GPUWidget()
        MemoryWidget()
        DiskWidget()
        TemperatureWidget()
        ProcessesWidget()
    }
}
