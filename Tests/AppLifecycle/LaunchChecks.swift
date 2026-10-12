import AppKit

@main enum LaunchChecks {
    @MainActor static func main() {
        let application = NSApplication.shared
        let delegate = AppDelegate()
        precondition(delegate.applicationShouldHandleReopen(application, hasVisibleWindows: false))
        var opens = 0
        delegate.openMainWindow = { opens += 1 }
        precondition(!delegate.applicationShouldHandleReopen(application, hasVisibleWindows: false))
        precondition(!delegate.applicationShouldHandleReopen(application, hasVisibleWindows: true))
        precondition(opens == 2)
        precondition(delegate.claimInitialMainWindowBootstrap())
        precondition(!delegate.claimInitialMainWindowBootstrap())
        print("Launch checks passed: reopen routes to the main window and startup bootstraps it once.")
    }
}
