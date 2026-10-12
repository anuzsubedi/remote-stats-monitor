import SwiftUI
import WidgetKit

struct GPUWidget: Widget {
    var body: some WidgetConfiguration { MetricWidget(metric: .gpu).body }
}
