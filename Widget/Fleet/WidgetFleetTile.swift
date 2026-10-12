import SwiftUI

struct WidgetFleetTile: View {
    let record: ServerSnapshotRecord
    let date: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: record.snapshot?.connectionError == nil ? "server.rack" : "exclamationmark.circle")
                    .foregroundStyle(record.snapshot?.connectionError == nil ? Color.secondary : .orange)
                Text(record.server.name).fontWeight(.semibold).lineLimit(1).truncationMode(.middle)
            }.font(.caption)
            WidgetMetricCell(metric: .cpu, snapshot: record.snapshot, compact: true)
            HStack(spacing: 6) {
                Text("GPU \(MonitorMetric.gpu.formatted(record.snapshot))")
                Spacer(minLength: 0)
                Text("RAM \(MonitorMetric.memory.formatted(record.snapshot))")
                Text(MonitorMetric.temperature.formatted(record.snapshot))
            }.font(.system(size: 9).monospacedDigit()).foregroundStyle(.secondary)
        }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(record.server.name + ", " + ReadingStatus.label(record.snapshot, at: date) + ", CPU " + MonitorMetric.cpu.formatted(record.snapshot) + ", GPU " + MonitorMetric.gpu.formatted(record.snapshot) + ", Memory " + MonitorMetric.memory.formatted(record.snapshot) + ", Temperature " + MonitorMetric.temperature.formatted(record.snapshot))
    }
}
