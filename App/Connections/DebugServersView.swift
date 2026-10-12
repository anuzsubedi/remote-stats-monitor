#if DEBUG
import SwiftUI

struct DebugServersView: View {
    @Bindable var model: MonitorModel
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Label("Debug", systemImage: "ladybug")
                    .font(.callout.weight(.semibold))
                Spacer(minLength: 8)
                Button("Add test servers", systemImage: "plus") {
                    model.addSyntheticServers()
                    dismissWindow(id: "connection")
                    openWindow(id: "processes")
                }
                .disabled(model.hasSyntheticServers)

                Button("Remove", systemImage: "minus", role: .destructive) {
                    model.removeSyntheticServers()
                }
                .disabled(!model.hasSyntheticServers)
            }

            Text("Adds 8 test servers to the app and Debug widget picker.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
#endif
