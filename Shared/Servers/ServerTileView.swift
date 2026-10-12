import SwiftUI

struct ServerTileView: View {
    let record: ServerSnapshotRecord
    var currentDate = Date.now
    var compact = false

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 5 : 14) {
            HStack(spacing: 5) {
                Image(systemName: record.server.iconName).foregroundStyle(.secondary)
                Text(record.server.name).font(compact ? .caption.weight(.semibold) : .headline)
                    .lineLimit(1).truncationMode(.middle)
                Spacer(minLength: 0)
            }
            if !compact {
                Text(ReadingStatus.label(record.snapshot, at: currentDate))
                    .font(.caption).foregroundStyle(record.snapshot?.connectionError != nil ? PiTheme.warning : PiTheme.secondary)
            }
            Grid(horizontalSpacing: compact ? 8 : 20, verticalSpacing: compact ? 3 : 10) {
                GridRow {
                    metric(.cpu)
                    metric(.temperature)
                }
                GridRow {
                    metric(.gpu)
                    metric(.memory)
                }
            }
            if compact, record.snapshot?.connectionError != nil || record.snapshot?.isStale(at: currentDate) == true {
                Text(ReadingStatus.label(record.snapshot, at: currentDate)).font(.caption2).foregroundStyle(PiTheme.warning)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .accessibilityElement(children: .combine)
    }

    private func metric(_ metric: MonitorMetric) -> some View {
        HStack(spacing: 4) {
            Text(metric == .temperature ? "Temp" : metric.rawValue).foregroundStyle(.secondary)
            Spacer(minLength: 0)
            Text(metric.formatted(record.snapshot)).fontWeight(.semibold)
                .foregroundStyle(metric.warning(record.snapshot) ? PiTheme.warning : PiTheme.ink)
        }.font(compact ? .caption2.monospacedDigit() : .callout.monospacedDigit())
    }
}
