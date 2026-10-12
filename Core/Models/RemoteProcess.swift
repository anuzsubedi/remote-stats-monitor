import Foundation

/// A process reading from one short sampling interval.
/// CPU percentage is normalized to total host CPU capacity, so one fully used
/// core on a four-core host is reported as roughly 25%.
struct RemoteProcess: Codable, Equatable, Identifiable, Sendable {
    static let maximumCount = 100
    static let maximumNameLength = 64

    let pid: Int
    let name: String
    let cpuPercent: Double
    let memoryUsed: Int64
    let memoryPercent: Double

    var id: Int { pid }

    static func parseCollectorRecord(_ record: Substring) -> Self? {
        let fields = record.split(separator: "|", omittingEmptySubsequences: false)
        guard fields.count == 5,
              let pid = Int(fields[0]), pid > 0,
              let cpuPercent = Double(fields[2]), cpuPercent.isFinite, (0...100).contains(cpuPercent),
              let memoryUsed = Int64(fields[3]), memoryUsed >= 0,
              let memoryPercent = Double(fields[4]), memoryPercent.isFinite, (0...100).contains(memoryPercent) else {
            return nil
        }

        let name = String(fields[1])
        let allowedNameCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 ._-:/+@()=")
        guard !name.isEmpty,
              name.utf8.count <= maximumNameLength,
              name.unicodeScalars.allSatisfy(allowedNameCharacters.contains) else {
            return nil
        }

        return .init(pid: pid, name: name, cpuPercent: cpuPercent,
                     memoryUsed: memoryUsed, memoryPercent: memoryPercent)
    }
}
