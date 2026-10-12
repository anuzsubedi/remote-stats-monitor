import SwiftUI
import WidgetKit

struct WidgetServerContainer<Content: View>: View {
    let entry: PiEntry
    @Environment(\.widgetFamily) private var family
    @ViewBuilder var content: () -> Content

    private var name: String {
        entry.server?.name ?? entry.missingServerName ?? entry.snapshot?.host ?? "Choose a server"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: family == .systemSmall ? 8 : 10) {
            HStack(spacing: 4) {
                if entry.canSwitchServers { arrow("previous", symbol: "chevron.left", label: "Previous server") }
                Text(name).lineLimit(1).truncationMode(.middle)
                    .frame(maxWidth: .infinity, alignment: entry.canSwitchServers ? .center : .leading)
                if entry.canSwitchServers { arrow("next", symbol: "chevron.right", label: "Next server") }
            }
            .font(.headline.weight(.semibold))
            .frame(height: 24)
            content()
        }
        .buttonStyle(.plain)
        .containerBackground(for: .widget) { WidgetGlassBackground() }
    }

    private func arrow(_ action: String, symbol: String, label: String) -> some View {
        Button(intent: WidgetServerAction(scope: entry.navigationScope, action: action, serverID: entry.server?.id.uuidString ?? "")) {
            Image(systemName: symbol)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 24, height: 24)
                .contentShape(.rect)
        }.accessibilityLabel(label)
    }
}
