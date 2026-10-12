import Foundation
import WidgetKit

struct FleetEntry: TimelineEntry {
    let date: Date
    let records: [ServerSnapshotRecord]
    let capacity: Int

    static let previewRecords: [ServerSnapshotRecord] = {
        let names = ["pi5.local", "nas.local", "build.local", "studio.local", "office.local", "backup.local", "media.local", "lab.local"]
        return names.enumerated().map { index, name in
            var snapshot = MonitorSnapshot.sample
            snapshot.host = name
            snapshot.cpu = [18.0, 42, 8, 67, 24, 11, 36, 5][index]
            snapshot.temperature = [47.0, 55, nil, 72, 48, nil, 63, 39][index]
            snapshot.gpu = [nil, 31.0, 0, nil, 18, nil, 54, 0][index]
            snapshot.sampledAt = .now.addingTimeInterval(-Double(index * 11))
            return ServerSnapshotRecord(
                server: ServerDescriptor(id: UUID(), name: name),
                snapshot: snapshot
            )
        }
    }()
}
