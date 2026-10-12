import SwiftUI
import WidgetKit

struct DiskWidget: Widget {
    var body: some WidgetConfiguration { MetricWidget(metric: .disk).body }
}
