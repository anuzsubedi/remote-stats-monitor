#if DEBUG
import AppKit

/// Captures the real SwiftUI scene, including its toolbar and content insets.
/// Only available with the isolated --ui-preview model.
enum SceneCapture {
    @MainActor static func prepareIfRequested() {
        let arguments = CommandLine.arguments
        guard arguments.contains("--ui-preview"),
              let index = arguments.firstIndex(of: "--capture-scene"),
              arguments.indices.contains(index + 1) else { return }
        let file = URL(fileURLWithPath: arguments[index + 1])
        NSApplication.shared.appearance = NSAppearance(named: arguments.contains("--preview-dark") ? .darkAqua : .aqua)
        Task { @MainActor in
            do {
                try await Task.sleep(for: .seconds(3))
                FileHandle.standardError.write(Data((NSApp.windows.map { "window: \($0.title) visible: \($0.isVisible)" }.joined(separator: "\n") + "\n").utf8))
                guard let window = NSApp.windows.first(where: { $0.styleMask.contains(.titled) }) else {
                    throw MonitorError.message("The preview scene did not open a window.")
                }
                let compact = arguments.contains("--preview-compact")
                window.setContentSize(NSSize(width: compact ? 900 : 1060, height: compact ? 600 : 760))
                window.center()
                window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
                try await Task.sleep(for: .milliseconds(500))
                try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
                process.arguments = ["-x", "-o", "-l", String(window.windowNumber), file.path]
                try process.run()
                process.waitUntilExit()
                guard process.terminationStatus == 0 else { throw MonitorError.message("Scene capture failed.") }
                exit(0)
            } catch {
                FileHandle.standardError.write(Data((error.localizedDescription + "\n").utf8))
                exit(1)
            }
        }
    }
}
#endif
