import SwiftUI

struct WidgetMissingServerMessage: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Server unavailable", systemImage: "exclamationmark.circle.fill")
                .font(.headline)
                .foregroundStyle(.orange)
            Text("Edit this widget to choose a saved server.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
