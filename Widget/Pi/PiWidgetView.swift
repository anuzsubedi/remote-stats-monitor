import SwiftUI
import WidgetKit

struct PiWidgetView: View {
    let entry: PiEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        PiWidgetContentView(entry: entry, family: family)
    }
}
