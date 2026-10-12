import Foundation
import WidgetKit

struct PiEntry: TimelineEntry {
    var navigationScope = "overview"
    var choosingServer = false
    var serverChoices: [ServerDescriptor] = []
    var choicePage = 0
    var choicePageCount = 1
    var hasMoreServers = false
    var canSwitchServers = false
    var date: Date
    var snapshot: MonitorSnapshot?
    var server: ServerDescriptor? = nil
    var missingServerName: String? = nil
}
