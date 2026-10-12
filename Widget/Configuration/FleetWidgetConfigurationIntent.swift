import AppIntents

struct FleetWidgetConfigurationIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Server List"
    static let description = IntentDescription("Choose servers to show. Leave the list empty to show saved servers in name order.")

    @Parameter(
        title: "Servers",
        description: "Choose up to four servers in a medium widget or eight in a large widget.",
        size: [
            .systemMedium: IntentCollectionSize(min: 0, max: 4),
            .systemLarge: IntentCollectionSize(min: 0, max: 8)
        ]
    )
    var servers: [ServerWidgetEntity]?

    init() {
    }
}
