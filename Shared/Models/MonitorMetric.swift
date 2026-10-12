import Foundation

enum MonitorMetric: String, CaseIterable, Identifiable, Sendable {
    case cpu = "CPU", gpu = "GPU", memory = "Memory", disk = "Disk", temperature = "Temperature"
    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .cpu: "cpu"
        case .gpu: "display"
        case .memory: "memorychip"
        case .disk: "internaldrive"
        case .temperature: "thermometer.medium"
        }
    }
    func value(_ snapshot: MonitorSnapshot) -> Double? {
        switch self {
        case .cpu: snapshot.cpu
        case .gpu: snapshot.gpu
        case .memory: snapshot.memoryFraction * 100
        case .disk: snapshot.diskFraction * 100
        case .temperature: snapshot.temperature
        }
    }
    func formatted(_ snapshot: MonitorSnapshot?) -> String {
        guard let snapshot, let value = value(snapshot) else { return "—" }
        return value.formatted(.number.precision(.fractionLength(0))) + (self == .temperature ? "°C" : "%")
    }
    func warning(_ snapshot: MonitorSnapshot?) -> Bool {
        guard let snapshot, let value = value(snapshot) else { return false }
        return value >= (self == .temperature ? 80 : 90)
    }
}
