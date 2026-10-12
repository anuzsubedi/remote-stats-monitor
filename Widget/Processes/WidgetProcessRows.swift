import SwiftUI

struct WidgetProcessRows: View {
    let snapshot: MonitorSnapshot?
    let limit: Int

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Processes")
                Spacer()
                Text("CPU").frame(width: 48, alignment: .trailing)
                Text("Memory").frame(width: 60, alignment: .trailing)
            }.font(.caption).foregroundStyle(.secondary)
            ForEach(Array((snapshot?.processes ?? []).sorted { $0.cpuPercent > $1.cpuPercent }.prefix(limit).enumerated()), id: \.element.pid) { index, process in
                HStack(spacing: 8) {
                    Text("\(index + 1)").font(.caption2).foregroundStyle(.tertiary).frame(width: 12)
                    Text(process.name).font(.caption).lineLimit(1).truncationMode(.middle)
                    Spacer(minLength: 0)
                    VStack(spacing: 3) {
                        Text(process.cpuPercent.formatted(.number.precision(.fractionLength(0))) + "%")
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        WidgetUsageScale(value: process.cpuPercent)
                    }.frame(width: 48)
                    Text((process.memoryUsed / 1_000_000).formatted(.number.precision(.fractionLength(0))) + " MB")
                        .frame(width: 60, alignment: .trailing)
                }.font(.caption.monospacedDigit())
            }
            if snapshot?.processes.isEmpty != false {
                Text("No process readings").font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}
