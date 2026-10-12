import SwiftUI

enum AppNavigationSection: String, CaseIterable, Hashable, Identifiable {
    case overview = "Overview"
    case servers = "Servers"
    case processes = "Processes"
    case settings = "Settings"

    static let monitoringSections: [AppNavigationSection] = [.overview, .servers, .processes]

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .overview: "gauge.with.dots.needle.67percent"
        case .servers: "server.rack"
        case .processes: "list.bullet.rectangle"
        case .settings: "gearshape"
        }
    }

    static func previewDestination(arguments: [String]) -> AppNavigationSection {
        guard let optionIndex = arguments.firstIndex(of: "--preview-destination"),
              arguments.indices.contains(optionIndex + 1) else {
            return .overview
        }

        switch arguments[optionIndex + 1].lowercased() {
        case "overview": return .overview
        case "detail": return .servers
        case "servers": return .servers
        case "processes": return .processes
        case "settings": return .settings
        default: return .overview
        }
    }
}
