import SwiftUI

struct ServerSummaryView: View {
    let snapshot: MonitorSnapshot?
    var name: String?
    var iconName = "server.rack"
    var currentDate = Date.now
    var compact = false
    var showsHeader = true

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 10 : 20) {
            if showsHeader {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(name ?? snapshot?.host ?? "Choose a server")
                        .font(compact ? .headline : .title2.weight(.semibold)).lineLimit(1).truncationMode(.middle)
                    Text(ReadingStatus.label(snapshot, at: currentDate))
                        .font(.caption).foregroundStyle(snapshot?.connectionError != nil || snapshot?.isStale(at: currentDate) == true ? PiTheme.warning : PiTheme.secondary)
                }
                Spacer(minLength: 4)
                Image(systemName: iconName).font(compact ? .title3 : .title).foregroundStyle(.secondary)
            }
            }
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(MonitorMetric.cpu.formatted(snapshot))
                    .font(.system(size: compact ? 30 : 44, weight: .semibold, design: .rounded)).monospacedDigit()
                    .foregroundStyle(MonitorMetric.cpu.warning(snapshot) ? PiTheme.warning : PiTheme.ink)
                Text("CPU").font(.callout).foregroundStyle(.secondary)
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    Text(MonitorMetric.temperature.formatted(snapshot)).font(.title3.monospacedDigit().weight(.medium))
                        .foregroundStyle(MonitorMetric.temperature.warning(snapshot) ? PiTheme.warning : PiTheme.ink)
                    Text("Temperature").font(.caption2).foregroundStyle(.secondary)
                }
            }
            Divider()
            HStack(spacing: compact ? 12 : 20) {
                ForEach([MonitorMetric.gpu, .memory, .disk]) { metric in
                    VStack(alignment: .center, spacing: 4) {
                        Text(metric.rawValue).font(.caption).foregroundStyle(.secondary)
                        Text(metric.formatted(snapshot)).font((compact ? Font.callout : .title3).monospacedDigit().weight(.semibold))
                            .foregroundStyle(metric.warning(snapshot) ? PiTheme.warning : PiTheme.ink)
                    }.frame(maxWidth: .infinity, alignment: .center).accessibilityElement(children: .combine)
                }
            }
            if !compact, let snapshot {
                HStack {
                    Text("Up \(Int(snapshot.uptime / 3600))h")
                    Spacer()
                    Text(snapshot.sampledAt, format: .dateTime.hour().minute().second())
                }.font(.caption).foregroundStyle(.secondary)
            }
            if snapshot == nil {
                Text("Open the app to collect server readings.").font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}
