import Foundation
import WidgetKit

struct PiEntry: TimelineEntry {
    var navigationScope = "overview"
    var canSwitchServers = false
    var date: Date
    var snapshot: MonitorSnapshot?
    var server: ServerDescriptor? = nil
    var missingServerName: String? = nil
}
