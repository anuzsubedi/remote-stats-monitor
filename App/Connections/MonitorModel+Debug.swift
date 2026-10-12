#if DEBUG
import Foundation
import WidgetKit

@MainActor
extension MonitorModel {
    var hasSyntheticServers: Bool {
        sessions.contains(where: \.isSynthetic)
    }

    func addSyntheticServers(publish: Bool = true) {
        guard !hasSyntheticServers else { return }

        let syntheticSessions = makeSyntheticSessions(SyntheticServers.records())
        sessions.append(contentsOf: syntheticSessions)
        if publish { publishSyntheticServers() }
        if let firstSession = syntheticSessions.first { selectedID = firstSession.id }
    }

    func restoreSyntheticServers() {
        guard !hasSyntheticServers else { return }
        let restored = makeSyntheticSessions(DebugSnapshotStore.read())
        sessions.append(contentsOf: restored)
        if selectedID == nil { selectedID = restored.first?.id }
    }

    private func makeSyntheticSessions(_ records: [ServerSnapshotRecord]) -> [ServerSession] {
        records.map { record in
            var connection = Connection(host: record.snapshot?.host ?? record.server.name)
            connection.id = record.server.id
            let session = ServerSession(connection: connection, snapshot: record.snapshot)
            session.isSynthetic = true
            session.error = record.snapshot?.connectionError
            return session
        }

    }

    func removeSyntheticServers() {
        let removedIDs = Set(sessions.filter(\.isSynthetic).map(\.id))
        guard !removedIDs.isEmpty else { return }

        sessions.removeAll(where: \.isSynthetic)
        try? DebugSnapshotStore.clear()
        WidgetCenter.shared.reloadAllTimelines()
        guard let selectedID, removedIDs.contains(selectedID) else { return }

        if let realSession = sessions.first {
            select(realSession.id)
        } else {
            self.selectedID = nil
        }
    }

    func updateSyntheticReadings() {
        let now = Date.now
        for session in sessions where session.isSynthetic {
            guard var reading = session.snapshot, reading.connectionError == nil else { continue }

            reading.gpu = reading.gpu.map { varied($0, by: -5...5, within: 0...100) }
            reading.cpu = varied(reading.cpu, by: -5...5, within: 0...100)
            reading.temperature = reading.temperature.map {
                varied($0, by: -1.5...1.5, within: 20...100)
            }
            reading.memoryUsed = varied(reading.memoryUsed, by: -45_000_000...45_000_000,
                                        within: 0...reading.memoryTotal)
            reading.diskUsed = varied(reading.diskUsed, by: -3_000_000...3_000_000,
                                      within: 0...reading.diskTotal)
            reading.uptime += max(0, now.timeIntervalSince(reading.sampledAt))
            reading.sampledAt = now
            reading.isSample = true
            reading.processes = reading.processes.map { process in
                .init(pid: process.pid,
                      name: process.name,
                      cpuPercent: varied(process.cpuPercent, by: -2...2, within: 0...100),
                      memoryUsed: process.memoryUsed,
                      memoryPercent: process.memoryPercent)
            }

            session.snapshot = reading
            session.error = reading.connectionError
        }
        publishSyntheticServers()
    }

    private func publishSyntheticServers() {
        let records = sessions.filter(\.isSynthetic).map {
            ServerSnapshotRecord(server: .init(id: $0.id, name: "Test · " + $0.connection.host), snapshot: $0.snapshot)
        }
        do { try DebugSnapshotStore.write(records) }
        catch { self.error = error.localizedDescription }
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func varied(_ value: Double, by change: ClosedRange<Double>, within bounds: ClosedRange<Double>) -> Double {
        min(max(value + Double.random(in: change), bounds.lowerBound), bounds.upperBound)
    }
}

#endif
