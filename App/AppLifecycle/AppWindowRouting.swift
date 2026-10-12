import SwiftUI

struct AppWindowRouting: View {
    let appDelegate: AppDelegate
    @Binding var selection: AppNavigationSection?
    @Binding var detailPath: [ServerDetailRoute]
    var bootstrap = false
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .onAppear(perform: registerRoutes)
    }

    private func registerRoutes() {
        appDelegate.openMainWindow = {
            openWindow(id: "servers")
            NSApp.activate(ignoringOtherApps: true)
        }
        appDelegate.openMainSection = { section in
            selection = section
            detailPath = []
            openWindow(id: "servers")
            NSApp.activate(ignoringOtherApps: true)
        }

        guard bootstrap, appDelegate.claimInitialMainWindowBootstrap() else { return }
        appDelegate.openMainWindow?()
    }
}
