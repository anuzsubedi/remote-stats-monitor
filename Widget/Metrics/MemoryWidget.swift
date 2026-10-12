import SwiftUI
import WidgetKit

struct MemoryWidget: Widget {
    var body: some WidgetConfiguration { MetricWidget(metric: .memory).body }
}
