import Foundation

enum ReadingStatus {
    static func label(_ snapshot: MonitorSnapshot?, at date: Date) -> String {
        guard let snapshot else { return "No reading" }
        if snapshot.connectionError != nil { return "Disconnected" }
        if snapshot.isSample { return "Sample" }
        if snapshot.isStale(at: date) { return "Last reading" }
        if snapshot.hasHighTemperature { return "High temperature" }
        return "Connected"
    }
}
