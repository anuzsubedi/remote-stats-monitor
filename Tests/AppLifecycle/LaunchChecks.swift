import AppKit

@main enum LaunchChecks {
    @MainActor static func main() {
        let application = NSApplication.shared
        let delegate = AppDelegate()
        precondition(delegate.applicationShouldHandleReopen(application, hasVisibleWindows: false))
        var opens = 0
        delegate.openConnection = { opens += 1 }
        precondition(!delegate.applicationShouldHandleReopen(application, hasVisibleWindows: false))
        precondition(!delegate.applicationShouldHandleReopen(application, hasVisibleWindows: true))
        precondition(opens == 2)
        print("Launch checks passed: reopen routes to setup with or without visible windows.")
    }
}
