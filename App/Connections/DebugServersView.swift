#if DEBUG
import SwiftUI

struct DebugServersView: View {
    @Bindable var model: MonitorModel
    var onAdded: (() -> Void)? = nil
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Label("Test servers", systemImage: "ladybug")
                    .font(.callout.weight(.medium))
                Spacer(minLength: 12)
                Button("Add test servers", systemImage: "plus") {
                    model.addSyntheticServers()
                    dismissWindow(id: "connection")
                    if let onAdded {
                        onAdded()
                    } else {
                        openWindow(id: "processes")
                    }
                }
                .disabled(model.hasSyntheticServers)

                Button("Remove", systemImage: "minus", role: .destructive) {
                    model.removeSyntheticServers()
                }
                .disabled(!model.hasSyntheticServers)
            }

            Text(model.hasSyntheticServers
                 ? "Eight test servers are loaded in the app and Debug widget picker."
                 : "Adds eight test servers to the app and Debug widget picker.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
#endif
