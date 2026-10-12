import SwiftUI
import WidgetKit

@main enum Launcher {
    @MainActor static func main() {
        SSHAskpass.handleIfRequested()
        #if DEBUG
        if CommandLine.arguments.contains("--add-test-servers") {
            do {
                try DebugSnapshotStore.write(SyntheticServers.records())
                WidgetCenter.shared.reloadAllTimelines()
                print("Test servers available to widgets:", DebugSnapshotStore.read().count)
            } catch { print(error.localizedDescription); exit(1) }
            return
        }
        if CommandLine.arguments.contains("--diagnose-startup") {
            let model = MonitorModel()
            print("Loaded sessions:", model.sessions.count)
            print("Startup error:", model.error ?? "none")
            for session in model.sessions { session.pollTask?.cancel() }
            return
        }
        #endif
        if CommandLine.arguments.contains("--diagnose-storage") {
            do {
                let connections = try KeychainStore.loadAll()
                print("Saved connections:", connections.count)
                let groups = Dictionary(grouping: connections, by: \.endpointKey)
                for group in groups.values where group.count > 1 {
                    guard let first = group.first else { continue }
                    print("Repeated destination records:", group.count)
                    for other in group.dropFirst() {
                        var fields: [String] = []
                        if first.authentication != other.authentication { fields.append("authentication") }
                        if first.password != other.password { fields.append("password") }
                        if first.passphrase != other.passphrase { fields.append("passphrase") }
                        if first.privateKeyPath != other.privateKeyPath { fields.append("key path") }
                        if first.address != other.address { fields.append("address spelling") }
                        print("Differing fields:", fields.joined(separator: ", "))
                    }
                }
            } catch { print("Storage diagnosis failed:", error.localizedDescription) }
            return
        }
        if let index = CommandLine.arguments.firstIndex(of: "--render-preview"), CommandLine.arguments.count > index + 1 {
            do { try RenderPreviews.export(to: URL(fileURLWithPath: CommandLine.arguments[index + 1])) }
            catch { FileHandle.standardError.write(Data(error.localizedDescription.utf8)); exit(1) }
            return
        }
        #if DEBUG
        SceneCapture.prepareIfRequested()
        #endif
        RemoteStatsMonitorApp.main()
    }
}
