import SwiftUI

struct AppWindowRouting: View {
    let appDelegate: AppDelegate
    @Environment(\.openWindow) private var openWindow
    var body: some View {
        Color.clear.onAppear {
            appDelegate.openConnection = { openWindow(id: "servers") }
        }
    }
}
