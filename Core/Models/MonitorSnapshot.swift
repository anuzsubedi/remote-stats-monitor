import Foundation

struct MonitorSnapshot: Codable, Equatable, Sendable {
    var host: String
    var cpu: Double
    var temperature: Double?
    var memoryUsed: Double
    var memoryTotal: Double
    var diskUsed: Double
    var diskTotal: Double
    var uptime: Double
    var sampledAt: Date
    var connectionError: String?
    var processes: [RemoteProcess] = []
    var isSample = false
    var gpu: Double? = nil

    func isStale(at date: Date = .now) -> Bool { date.timeIntervalSince(sampledAt) > 45 }
    var memoryFraction: Double { memoryTotal > 0 ? memoryUsed / memoryTotal : 0 }
    var diskFraction: Double { diskTotal > 0 ? diskUsed / diskTotal : 0 }
    // Raspberry Pi's documented thermal throttling range begins at 80°C.
    var hasHighTemperature: Bool { (temperature ?? 0) >= 80 }

    static var sample: Self {
        .init(host: "pi5.local", cpu: 18, temperature: 47, memoryUsed: 2.1e9,
              memoryTotal: 8e9, diskUsed: 24e9, diskTotal: 59e9, uptime: 345600,
              sampledAt: .now, connectionError: nil,
              processes: [
                .init(pid: 812, name: "python3", cpuPercent: 8.3, memoryUsed: 232_000_000, memoryPercent: 2.9),
                .init(pid: 1, name: "systemd", cpuPercent: 0.2, memoryUsed: 28_000_000, memoryPercent: 0.4)
              ], isSample: true)
    }

    static func parse(_ output: String, host: String) throws -> Self {
        var values: [String: Double] = [:]
        var gpu: Double?
        var processes: [RemoteProcess] = []
        var processIDs: Set<Int> = []
        for line in output.split(separator: "\n") {
            let pair = line.split(separator: "=", maxSplits: 1)
            guard pair.count == 2 else { continue }
            if pair[0] == "process" {
                guard processes.count < RemoteProcess.maximumCount,
                      let process = RemoteProcess.parseCollectorRecord(pair[1]),
                      processIDs.insert(process.pid).inserted else { continue }
                processes.append(process)
            } else if pair[0] == "gpu" {
                if let number = Double(pair[1]), number.isFinite, (0...100).contains(number) {
                    gpu = number
                } else {
                    gpu = nil
                }
            } else if let number = Double(pair[1]), number.isFinite {
                values[String(pair[0])] = number
            }
        }
        guard let cpu = values["cpu"], let memoryUsed = values["memory_used"],
              let memoryTotal = values["memory_total"], memoryTotal > 0,
              let diskUsed = values["disk_used"], let diskTotal = values["disk_total"], diskTotal > 0,
              let uptime = values["uptime"], uptime >= 0, cpu >= 0,
              memoryUsed >= 0, memoryUsed <= memoryTotal, diskUsed >= 0, diskUsed <= diskTotal else {
            throw MonitorError.message("The server returned incomplete readings. Check that /proc and the root filesystem are available.")
        }
        return .init(host: host, cpu: min(100, cpu), temperature: values["temperature"],
                     memoryUsed: memoryUsed, memoryTotal: memoryTotal, diskUsed: diskUsed,
                     diskTotal: diskTotal, uptime: uptime, sampledAt: .now, connectionError: nil,
                     processes: processes, gpu: gpu)
    }
}

extension MonitorSnapshot {
    private enum CodingKeys: String, CodingKey {
        case host, cpu, temperature, memoryUsed, memoryTotal, diskUsed, diskTotal
        case uptime, sampledAt, connectionError, processes, isSample, gpu
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        host = try container.decode(String.self, forKey: .host)
        cpu = try container.decode(Double.self, forKey: .cpu)
        temperature = try container.decodeIfPresent(Double.self, forKey: .temperature)
        memoryUsed = try container.decode(Double.self, forKey: .memoryUsed)
        memoryTotal = try container.decode(Double.self, forKey: .memoryTotal)
        diskUsed = try container.decode(Double.self, forKey: .diskUsed)
        diskTotal = try container.decode(Double.self, forKey: .diskTotal)
        uptime = try container.decode(Double.self, forKey: .uptime)
        sampledAt = try container.decode(Date.self, forKey: .sampledAt)
        connectionError = try container.decodeIfPresent(String.self, forKey: .connectionError)
        processes = Array((try container.decodeIfPresent([RemoteProcess].self, forKey: .processes) ?? [])
            .prefix(RemoteProcess.maximumCount))
        isSample = try container.decodeIfPresent(Bool.self, forKey: .isSample) ?? false
        if let decodedGPU = try? container.decode(Double.self, forKey: .gpu),
           decodedGPU.isFinite, (0...100).contains(decodedGPU) {
            gpu = decodedGPU
        } else {
            gpu = nil
        }
    }
}
