import SwiftUI

struct WidgetFleetTile: View {
    let record: ServerSnapshotRecord
    let date: Date

    private var warningSummary: String {
        let warnings = [MonitorMetric.cpu, .gpu, .memory, .temperature].filter { $0.warning(record.snapshot) }
        return warnings.isEmpty ? "" : ", " + warnings.map { "high " + $0.rawValue.lowercased() }.joined(separator: ", ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 4) {
                Text(record.server.name)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer(minLength: 0)
                if record.snapshot?.connectionError != nil {
                    Image(systemName: "exclamationmark.circle.fill").foregroundStyle(.orange)
                } else if record.snapshot?.isSample == true {
                    Text("Sample").foregroundStyle(.secondary).font(.system(size: 9))
                } else if record.snapshot?.isStale(at: date) == true {
                    Image(systemName: "clock").foregroundStyle(.secondary)
                }
            }
            Grid(horizontalSpacing: 10, verticalSpacing: 4) {
                GridRow {
                    reading(.cpu, label: "CPU")
                    reading(.temperature, label: "Temp")
                }
                GridRow {
                    reading(.gpu, label: "GPU")
                    reading(.memory, label: "RAM")
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(record.server.name + ", " + ReadingStatus.label(record.snapshot, at: date) + ", CPU " + MonitorMetric.cpu.formatted(record.snapshot) + ", GPU " + MonitorMetric.gpu.formatted(record.snapshot) + ", Memory " + MonitorMetric.memory.formatted(record.snapshot) + ", Temperature " + MonitorMetric.temperature.formatted(record.snapshot) + warningSummary)
    }

    private func reading(_ metric: MonitorMetric, label: String) -> some View {
        HStack(spacing: 3) {
            Text(label).foregroundStyle(.secondary)
            Spacer(minLength: 0)
            Text(metric.formatted(record.snapshot))
                .fontWeight(.medium)
                .foregroundStyle(metric.warning(record.snapshot) ? Color.orange : Color.primary)
                .monospacedDigit()
        }
        .font(.caption2)
        .lineLimit(1)
        .minimumScaleFactor(0.85)
    }
}
