import SwiftUI

struct TopProcessesView: View {
    let snapshot: MonitorSnapshot?
    var limit = 5

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Top processes").font(.headline)
                Spacer()
                Text("CPU").frame(width: 42, alignment: .trailing)
                Text("RAM").frame(width: 60, alignment: .trailing)
            }.font(.caption).foregroundStyle(.secondary)
            if let snapshot, !snapshot.processes.isEmpty {
                ForEach(Array(snapshot.processes.sorted { $0.cpuPercent > $1.cpuPercent }.prefix(limit))) { process in
                    HStack {
                        Text(process.name).lineLimit(1).truncationMode(.middle)
                        Spacer(minLength: 4)
                        Text(process.cpuPercent.formatted(.number.precision(.fractionLength(0))) + "%")
                            .frame(width: 42, alignment: .trailing)
                        Text((Double(process.memoryUsed) / 1e6).formatted(.number.precision(.fractionLength(0))) + " MB")
                            .frame(width: 60, alignment: .trailing)
                    }.font(.caption.monospacedDigit()).accessibilityElement(children: .combine)
                }
            } else {
                Text("No process readings").font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}
