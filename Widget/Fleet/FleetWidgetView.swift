import SwiftUI
import WidgetKit

struct FleetWidgetView: View {
    let entry: FleetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if entry.records.isEmpty {
                Text("No servers").font(.headline)
                Text("Edit this widget to choose servers.").font(.caption).foregroundStyle(.secondary)
            } else {
                HStack {
                    Text("Servers").fontWeight(.semibold)
                    Spacer()
                    ForEach(["°C", "CPU", "GPU", "MEM"], id: \.self) { label in
                        Text(label).frame(width: 34)
                    }
                }.font(.caption2).foregroundStyle(.secondary)
                ForEach(Array(entry.records.prefix(entry.capacity)), id: \.server.id) { record in
                    HStack(spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 3) {
                                if record.snapshot?.connectionError != nil {
                                    Image(systemName: "exclamationmark.circle.fill").foregroundStyle(.orange)
                                }
                                Text(record.server.name).lineLimit(1).truncationMode(.middle)
                            }.font(.caption.weight(.medium))
                            if entry.capacity > 4 {
                                Text(ReadingStatus.label(record.snapshot, at: entry.date)).font(.caption2).foregroundStyle(.secondary)
                            }
                        }.frame(maxWidth: .infinity, alignment: .leading)
                        ForEach([MonitorMetric.temperature, .cpu, .gpu, .memory]) { metric in
                            VStack(spacing: 3) {
                                Text(metric.formatted(record.snapshot)).font(.system(size: 10, weight: .medium).monospacedDigit()).lineLimit(1).minimumScaleFactor(0.7)
                                    .frame(maxWidth: .infinity)
                                    .foregroundStyle(metric.warning(record.snapshot) ? Color.orange : .primary)
                                if metric != .temperature {
                                    WidgetUsageScale(value: record.snapshot.flatMap { metric.value($0) }, warning: metric.warning(record.snapshot))
                                }
                            }.frame(width: 34)
                        }
                    }.frame(maxHeight: .infinity)
                }
            }
        }.containerBackground(.background, for: .widget)
    }
}
