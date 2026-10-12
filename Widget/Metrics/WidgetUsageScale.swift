import SwiftUI

struct WidgetUsageScale: View {
    let value: Double?
    var warning = false

    private var fraction: Double {
        guard let value else { return 0 }
        return min(1, max(0, value / 100))
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(.quaternary)
                if value != nil {
                    Capsule()
                        .fill(warning ? Color.orange : Color.primary)
                        .frame(width: geometry.size.width * fraction)
                }
            }
        }
        .frame(height: 4)
        .accessibilityHidden(true)
    }
}
