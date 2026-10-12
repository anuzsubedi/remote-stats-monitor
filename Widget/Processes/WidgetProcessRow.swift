import SwiftUI

struct WidgetProcessRow: View {
    let rank: Int
    let process: RemoteProcess

    private var cpu: String {
        process.cpuPercent.formatted(.number.precision(.fractionLength(0))) + "%"
    }

    private var memory: String {
        (process.memoryUsed / 1_000_000).formatted(.number.precision(.fractionLength(0))) + " MB"
    }

    var body: some View {
        HStack(spacing: 8) {
            Text(rank.formatted(.number.precision(.integerLength(2))))
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.tertiary)
                .frame(width: 18, alignment: .leading)
            Text(process.name)
                .font(.caption)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: .infinity, alignment: .leading)
            VStack(spacing: 3) {
                Text(cpu)
                    .font(.caption.monospacedDigit())
                    .frame(maxWidth: .infinity, alignment: .trailing)
                WidgetUsageScale(value: process.cpuPercent)
            }
            .frame(width: 50)
            Text(memory)
                .font(.caption.monospacedDigit())
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(width: 62, alignment: .trailing)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(rank), \(process.name), CPU \(cpu), memory \(memory)")
    }
}
