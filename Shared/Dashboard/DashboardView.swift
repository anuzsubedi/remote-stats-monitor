import SwiftUI

struct DashboardView: View {
    enum Size { case medium, large, menu }
    let snapshot: MonitorSnapshot?
    var size = Size.menu
    var currentDate = Date.now

    var body: some View {
        ServerSummaryView(snapshot: snapshot, currentDate: currentDate, compact: size == .medium)
    }
}
