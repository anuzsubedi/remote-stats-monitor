import SwiftUI

struct ConnectionSceneView: View {
    @Bindable var model: MonitorModel
    let appDelegate: AppDelegate
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow

    var body: some View {
        ConnectionView(model: model)
            .onChange(of: model.successfulConnectionCount) {
                dismissWindow(id: "connection")
            }
            .onAppear {
                NSApp.activate(ignoringOtherApps: true)
            }
    }
}
