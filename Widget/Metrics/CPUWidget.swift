import SwiftUI
import WidgetKit

struct CPUWidget: Widget {
    var body: some WidgetConfiguration { MetricWidget(metric: .cpu).body }
}
