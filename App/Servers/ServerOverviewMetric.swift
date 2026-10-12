import SwiftUI

struct ServerOverviewMetric: View {
    let title: String
    let symbol: String
    let value: Double?
    var temperature = false

    var body: some View {
        VStack(alignment: .center, spacing: 6) {
            Label(title, systemImage: symbol).font(.caption).foregroundStyle(.secondary)
            Text(value.map { $0.formatted(.number.precision(.fractionLength(0))) + (temperature ? "°C" : "%") } ?? "—")
                .font(.title3.weight(.semibold).monospacedDigit())
                .foregroundStyle((value ?? 0) >= (temperature ? 80 : 90) ? PiTheme.warning : PiTheme.ink)
        }.frame(maxWidth: .infinity, alignment: .center)
            .accessibilityElement(children: .combine)
    }
}
