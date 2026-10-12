import SwiftUI
import WidgetKit

struct ProcessesWidgetView: View {
    let entry: PiEntry
    @Environment(\.widgetFamily) private var family
    var previewFamily: WidgetFamily? = nil

    var body: some View {
        WidgetServerContainer(entry: entry) {
            if entry.missingServerName != nil {
                WidgetMissingServerMessage()
                    .frame(maxHeight: .infinity, alignment: .center)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    WidgetProcessRows(snapshot: entry.snapshot, limit: (previewFamily ?? family) == .systemLarge ? 10 : 3)
                    Spacer(minLength: 0)
                    WidgetStatusLabel(snapshot: entry.snapshot, date: entry.date)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
    }
}
