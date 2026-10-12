import SwiftUI

struct WidgetGlassBackground: View {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        if reduceTransparency {
            Color(nsColor: .windowBackgroundColor)
        } else {
            Color.clear
                .glassEffect(.regular, in: ContainerRelativeShape())
        }
    }
}
