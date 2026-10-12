import SwiftUI
import WidgetKit

struct ProcessesWidgetView: View {
    let entry: PiEntry
    @Environment(\.widgetFamily) private var family
    var previewFamily: WidgetFamily? = nil

    var body: some View {
        WidgetServerContainer(entry: entry) {
        VStack(alignment: .leading, spacing: 10) {
            WidgetProcessRows(snapshot: entry.snapshot, limit: (previewFamily ?? family) == .systemLarge ? 10 : 3)
            Spacer(minLength: 0)
            Text(entry.missingServerName == nil ? ReadingStatus.label(entry.snapshot, at: entry.date) : "Server unavailable")
                .font(.caption2).foregroundStyle(.secondary)
        }
        }
    }
}
