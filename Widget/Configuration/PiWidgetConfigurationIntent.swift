import AppIntents

struct PiWidgetConfigurationIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Remote Stats Monitor"
    static let description = IntentDescription("Choose which server this widget shows.")

    @Parameter(title: "Server")
    var server: ServerWidgetEntity?

    init() {}
}
