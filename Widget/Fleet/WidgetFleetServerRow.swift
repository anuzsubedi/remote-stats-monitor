import SwiftUI

struct WidgetFleetServerRow: View {
    let record: ServerSnapshotRecord
    let date: Date
    var compact = false

    private let metrics: [MonitorMetric] = [.temperature, .cpu, .gpu, .memory]

    private var accessibilitySummary: String {
        let snapshot = record.snapshot
        let warnings = metrics.compactMap { metric -> String? in
            guard metric.warning(snapshot) else { return nil }
            return metric == .temperature ? "high temperature" : "high \(metric.rawValue.lowercased()) use"
        }
        let warningText = warnings.isEmpty ? "" : ", " + warnings.joined(separator: ", ")
        return "\(record.server.name), \(ReadingStatus.label(snapshot, at: date)), temperature \(MonitorMetric.temperature.formatted(snapshot)), CPU \(MonitorMetric.cpu.formatted(snapshot)), GPU \(MonitorMetric.gpu.formatted(snapshot)), memory \(MonitorMetric.memory.formatted(snapshot))\(warningText)"
    }

    var body: some View {
        HStack(spacing: 4) {
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 4) {
                    Image(systemName: record.server.iconName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                    Text(record.server.name)
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                        .truncationMode(.middle)
                    if compact && record.snapshot?.connectionError != nil {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.caption2).foregroundStyle(.orange)
                    } else if compact && record.snapshot?.isStale(at: date) == true {
                        Image(systemName: "clock").font(.caption2).foregroundStyle(.secondary)
                    }
                }
                if !compact {
                    WidgetStatusLabel(snapshot: record.snapshot, date: date, compact: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(metrics) { metric in
                WidgetMetricValue(
                    metric: metric,
                    snapshot: record.snapshot,
                    font: .caption2.weight(.semibold)
                )
                .frame(width: 38, alignment: .trailing)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
    }
}
