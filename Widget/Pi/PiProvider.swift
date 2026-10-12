import Foundation
import WidgetKit

struct PiProvider: AppIntentTimelineProvider {
    var kind = SnapshotStore.widgetKind

    func placeholder(in context: Context) -> PiEntry {
        .init(date: .now, snapshot: .sample)
    }

    func snapshot(for configuration: PiWidgetConfigurationIntent, in context: Context) async -> PiEntry {
        if context.isPreview {
            return .init(date: .now, snapshot: .sample)
        }
        return makeEntry(for: configuration, at: .now)
    }

    func timeline(for configuration: PiWidgetConfigurationIntent, in context: Context) async -> Timeline<PiEntry> {
        let now = Date.now
        let entry = makeEntry(for: configuration, at: now)
        var entries = [entry]

        // The extra entry changes fresh readings to “Last reading” even if the app quits.
        if let snapshot = entry.snapshot, !snapshot.isStale(at: now) {
            var stale = entry
            stale.date = snapshot.sampledAt.addingTimeInterval(46)
            entries.append(stale)
        }
        return Timeline(entries: entries, policy: .after(now.addingTimeInterval(300)))
    }

    private func makeEntry(for configuration: PiWidgetConfigurationIntent, at date: Date) -> PiEntry {
        let scope = kind + "." + (configuration.server?.id.uuidString ?? "selected")
        let defaults = UserDefaults(suiteName: SnapshotStore.group)
        let key = "widget-navigation." + scope
        var entry = baseEntry(for: configuration, at: date)
        if let value = defaults?.string(forKey: key + ".server"), let id = UUID(uuidString: value),
           let record = WidgetServerSource.record(for: id) {
            entry = .init(date: date, snapshot: record.snapshot, server: record.server)
        }
        let servers = WidgetServerSource.servers()
        entry.navigationScope = scope
        entry.canSwitchServers = servers.count > 1
        return entry
    }

    private func baseEntry(for configuration: PiWidgetConfigurationIntent, at date: Date) -> PiEntry {
        if let server = configuration.server {
            guard let record = WidgetServerSource.record(for: server.id) else {
                return .init(date: date, snapshot: nil, missingServerName: server.name)
            }
            return .init(date: date, snapshot: record.snapshot, server: record.server)
        }

        if let record = SnapshotStore.selectedRecord() {
            return .init(date: date, snapshot: record.snapshot, server: record.server)
        }

        // Existing installs may still have only the original snapshot.json file.
        return .init(date: date, snapshot: SnapshotStore.readSelected())
    }
}
