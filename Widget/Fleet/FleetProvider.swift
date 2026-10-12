import Foundation
import WidgetKit

struct FleetProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> FleetEntry {
        .init(date: .now, records: FleetEntry.previewRecords, capacity: capacity(for: context.family))
    }

    func snapshot(for configuration: FleetWidgetConfigurationIntent, in context: Context) async -> FleetEntry {
        let now = Date.now
        let capacity = capacity(for: context.family)
        if context.isPreview {
            return .init(date: now, records: Array(FleetEntry.previewRecords.prefix(capacity)), capacity: capacity)
        }
        return makeEntry(for: configuration, capacity: capacity, at: now)
    }

    func timeline(for configuration: FleetWidgetConfigurationIntent, in context: Context) async -> Timeline<FleetEntry> {
        let now = Date.now
        let capacity = capacity(for: context.family)
        let entry = makeEntry(for: configuration, capacity: capacity, at: now)
        var entries = [entry]

        let staleTransitions = Set(entry.records.compactMap({ record -> Date? in
            guard let snapshot = record.snapshot,
                  !snapshot.isSample,
                  snapshot.connectionError == nil else { return nil }
            let staleDate = snapshot.sampledAt.addingTimeInterval(46)
            return staleDate > now ? staleDate : nil
        }))
        entries.append(contentsOf: staleTransitions.sorted().map { staleDate in
            .init(date: staleDate, records: entry.records, capacity: capacity)
        })

        return Timeline(entries: entries, policy: .after(now.addingTimeInterval(300)))
    }

    private func makeEntry(
        for configuration: FleetWidgetConfigurationIntent,
        capacity: Int,
        at date: Date
    ) -> FleetEntry {
        let configuredServers = Array((configuration.servers ?? []).prefix(capacity))
        let servers = configuredServers.isEmpty
            ? WidgetServerSource.servers().prefix(capacity).map(ServerWidgetEntity.init)
            : configuredServers

        var seen = Set<UUID>()
        let records = servers.map { server in
            WidgetServerSource.record(for: server.id) ?? ServerSnapshotRecord(
                server: ServerDescriptor(id: server.id, name: server.name),
                snapshot: nil
            )
        }
        let unique = records.filter { seen.insert($0.server.id).inserted }
        return .init(date: date, records: unique, capacity: capacity)
    }

    private func capacity(for family: WidgetFamily) -> Int {
        family == .systemMedium ? 4 : 8
    }
}
