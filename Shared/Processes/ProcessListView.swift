import SwiftUI

struct ProcessListView: View {
    private enum SortOrder: String, CaseIterable, Identifiable {
        case cpu
        case memory

        var id: Self { self }
    }

    let processes: [RemoteProcess]
    let limit: Int
    let showsTitle: Bool

    @State private var sortOrder: SortOrder = .cpu

    init(processes: [RemoteProcess], limit: Int = 5, showsTitle: Bool = true) {
        self.processes = processes
        self.limit = limit
        self.showsTitle = showsTitle
    }

    private var sortedProcesses: [RemoteProcess] {
        processes.sorted { left, right in
            switch sortOrder {
            case .cpu:
                if left.cpuPercent != right.cpuPercent { left.cpuPercent > right.cpuPercent }
                else if left.memoryUsed != right.memoryUsed { left.memoryUsed > right.memoryUsed }
                else { left.pid < right.pid }
            case .memory:
                if left.memoryUsed != right.memoryUsed { left.memoryUsed > right.memoryUsed }
                else if left.cpuPercent != right.cpuPercent { left.cpuPercent > right.cpuPercent }
                else { left.pid < right.pid }
            }
        }
    }

    private var visibleProcesses: [RemoteProcess] {
        Array(sortedProcesses.prefix(max(0, limit)))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                if showsTitle { Text("Processes").font(.headline) }
                Spacer(minLength: 4)
                Picker("Sort processes by", selection: $sortOrder) {
                    Text("CPU").tag(SortOrder.cpu)
                    Text("Memory").tag(SortOrder.memory)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .accessibilityLabel("Sort processes by")
                .frame(width: 150)
            }

            Text("CPU is share of total CPU capacity; RAM is resident memory.")
                .font(.caption)
                .foregroundStyle(.secondary)

            if visibleProcesses.isEmpty {
                Text("No process readings")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                HStack(spacing: 8) {
                    Text("Process").frame(maxWidth: .infinity, alignment: .leading)
                    Text("CPU").frame(width: 56, alignment: .trailing)
                    Text("RAM").frame(width: 74, alignment: .trailing)
                    Text("RAM %").frame(width: 52, alignment: .trailing)
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                ForEach(visibleProcesses) { process in
                    HStack(spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(process.name)
                                .lineLimit(1)
                                .truncationMode(.middle)
                            Text("PID \(process.pid)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Text(process.cpuPercent / 100, format: .percent.precision(.fractionLength(1)))
                            .frame(width: 56, alignment: .trailing)
                        Text(process.memoryUsed, format: .byteCount(style: .memory))
                            .frame(width: 74, alignment: .trailing)
                        Text(process.memoryPercent / 100, format: .percent.precision(.fractionLength(1)))
                            .frame(width: 52, alignment: .trailing)
                    }
                    .font(.subheadline.monospacedDigit())
                    .accessibilityElement(children: .combine)
                }

                if processes.count > visibleProcesses.count {
                    Text("Showing \(visibleProcesses.count) of \(processes.count) collected processes.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
