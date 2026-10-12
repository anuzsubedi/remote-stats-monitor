import SwiftUI

struct AppNavigationCommands: Commands {
    let navigate: (AppNavigationSection) -> Void

    var body: some Commands {
        CommandGroup(after: .sidebar) {
            Button("Show Overview") { navigate(.overview) }
                .keyboardShortcut("1", modifiers: .command)
            Button("Show Servers") { navigate(.servers) }
                .keyboardShortcut("2", modifiers: .command)
            Button("Show Processes") { navigate(.processes) }
                .keyboardShortcut("3", modifiers: .command)
            Button("Show Settings") { navigate(.settings) }
                .keyboardShortcut("4", modifiers: .command)
        }
    }
}
