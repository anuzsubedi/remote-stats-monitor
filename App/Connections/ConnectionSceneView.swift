import SwiftUI

struct ConnectionSceneView: View {
    @Bindable var model: MonitorModel
    let appDelegate: AppDelegate
    var onAddTestServers: (() -> Void)? = nil
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow

    var body: some View {
        ConnectionView(model: model, onAddTestServers: onAddTestServers)
            .onChange(of: model.successfulConnectionCount) {
                dismissWindow(id: "connection")
            }
            .onAppear {
                NSApp.activate(ignoringOtherApps: true)
            }
    }
}
