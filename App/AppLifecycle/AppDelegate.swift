import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    var openMainWindow: (() -> Void)?
    var openMainSection: ((AppNavigationSection) -> Void)?
    var didBootstrapMainWindow = false

    func claimInitialMainWindowBootstrap() -> Bool {
        guard !didBootstrapMainWindow else { return false }
        didBootstrapMainWindow = true
        return true
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // SwiftUI's openWindow action also recreates a previously closed window.
        // Do not rely on a status item being visible beside the Mac's notch.
        guard let openMainWindow else { return true }
        openMainWindow()
        sender.activate(ignoringOtherApps: true)
        return false
    }
}
