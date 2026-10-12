import SwiftUI
import WidgetKit

struct WidgetProcessRows: View {
    let snapshot: MonitorSnapshot?
    let limit: Int
    var spacious = false

    var body: some View {
        VStack(alignment: .leading, spacing: spacious ? 10 : 5) {
            HStack(alignment: .firstTextBaseline) {
                Text("Top processes")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Spacer()
                Text("CPU").frame(width: 50, alignment: .trailing)
                Text("MEM").frame(width: 62, alignment: .trailing)
            }
            .font(.caption2.weight(.medium))
            .foregroundStyle(.secondary)

            let processes = Array((snapshot?.processes ?? [])
                .sorted { $0.cpuPercent > $1.cpuPercent }
                .prefix(limit)
                .enumerated())
            if processes.isEmpty {
                Text("No process readings")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(processes, id: \.element.pid) { index, process in
                    WidgetProcessRow(rank: index + 1, process: process)
                }
            }
        }
    }
}
