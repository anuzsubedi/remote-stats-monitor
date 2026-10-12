#if DEBUG
import Foundation

enum SyntheticServers {
    static func records(at date: Date = .now) -> [ServerSnapshotRecord] {
        let names = ["pi-office", "gpu-render", "database", "backup-offline", "web-edge", "inference", "storage", "build-runner"]
        let cpus = [12.4, 91.7, 64.2, 24.7, 3.8, 78.5, 18.1, 99.2]
        let gpus: [Double?] = [nil, 96, nil, 14, nil, 72, nil, 43]
        return names.enumerated().map { index, name in
            let id = UUID(uuidString: String(format: "DEB00000-0000-4000-8000-%012d", index + 1))!
            let offline = index == 3
            let snapshot = MonitorSnapshot(host: name, cpu: cpus[index],
                temperature: index == 4 ? nil : 42 + Double(index) * 6,
                memoryUsed: Double(index + 1) * 900_000_000, memoryTotal: 8_000_000_000,
                diskUsed: Double(index + 1) * 5_000_000_000, diskTotal: 64_000_000_000,
                uptime: Double(index + 1) * 86_400,
                sampledAt: offline ? date.addingTimeInterval(-120) : date,
                connectionError: offline ? "Synthetic server is offline." : nil,
                processes: (0..<12).map { rank in
                    let weight = Double(12 - rank) / 78
                    let memory = Double(index + 1) * 900_000_000 * weight * 0.7
                    let names = ["python3 worker", "postgres", "nginx", "redis-server", "render-worker", "node", "containerd", "systemd", "sshd", "backup", "journald", "cron"]
                    return RemoteProcess(pid: 120 + index * 100 + rank, name: names[rank], cpuPercent: cpus[index] * weight * 0.8, memoryUsed: Int64(memory), memoryPercent: memory / 8_000_000_000 * 100)
                },
                isSample: true, gpu: gpus[index])
            return ServerSnapshotRecord(server: .init(id: id, name: "Test · " + name), snapshot: snapshot)
        }
    }
}
#endif
