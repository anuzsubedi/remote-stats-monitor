import SwiftUI

enum ServerLayout: String, CaseIterable, Identifiable {
    case single = "Server", list = "List", grid = "Grid"
    var id: String { rawValue }
    var symbol: String {
        switch self { case .single: "rectangle"; case .list: "list.bullet"; case .grid: "square.grid.2x2" }
    }
}
