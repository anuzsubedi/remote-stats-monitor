import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    var openConnection: (() -> Void)?

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // SwiftUI's openWindow action also recreates a previously closed window.
        // Do not rely on a status item being visible beside the Mac's notch.
        guard let openConnection else { return true }
        openConnection()
        sender.activate(ignoringOtherApps: true)
        return false
    }
}
