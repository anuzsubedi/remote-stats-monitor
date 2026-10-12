import SwiftUI
import WidgetKit

struct TemperatureWidget: Widget {
    var body: some WidgetConfiguration { MetricWidget(metric: .temperature).body }
}
