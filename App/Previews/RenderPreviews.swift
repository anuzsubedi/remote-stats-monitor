import SwiftUI

enum RenderPreviews {
    @MainActor static func export(to directory: URL) throws {
        _ = NSApplication.shared
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        for (name, size, width, height) in [("medium", DashboardView.Size.medium, 360.0, 170.0),
                                           ("large", .large, 360.0, 360.0),
                                           ("menu", .menu, 370.0, 250.0)] {
            let content = DashboardView(snapshot: .sample, size: size)
                .padding(size == .medium ? 14 : 22)
                .frame(width: width, height: height)
                .background(PiTheme.surface)
                .clipShape(.rect(cornerRadius: 22))
                .environment(\.colorScheme, .light)
            // AppKit-backed native controls need an NSHostingView capture;
            // ImageRenderer does not render their backing views on macOS.
            try renderNative(content, width: width, height: height, to: directory.appending(path: name + ".png"))
        }
        let icon = NSWorkspace.shared.icon(forFile: Bundle.main.bundlePath)
        if let tiff = icon.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: tiff), let data = bitmap.representation(using: .png, properties: [:]) {
            try data.write(to: directory.appending(path: "app-icon.png"))
        }
        let model = MonitorModel(preview: true)
        try renderNative(MenuPanel(model: model, previewLayout: .single), width: 410, height: 650, to: directory.appending(path: "menu-panel.png"))
        try renderNative(ProcessesView(model: model), width: 640, height: 620, to: directory.appending(path: "processes.png"))
        try renderNative(ConnectionView(model: model), width: 520, height: 680, to: directory.appending(path: "connection.png"), fitHeight: true)
        model.draft.authentication = .password
        try renderNative(ConnectionView(model: model), width: 520, height: 680, to: directory.appending(path: "connection-password.png"), fitHeight: true)
        model.draft.authentication = .privateKey
        try renderNative(ConnectionView(model: model), width: 520, height: 680, to: directory.appending(path: "connection-key.png"), fitHeight: true)
        #if DEBUG
        try renderNative(ServersView(model: model), width: 780, height: 720, to: directory.appending(path: "servers-empty.png"))
        model.addSyntheticServers(publish: false)
        try renderNative(ServersView(model: model), width: 780, height: 720, to: directory.appending(path: "servers-overview.png"))
        try renderNative(ServersView(model: model), width: 660, height: 500, to: directory.appending(path: "servers-compact.png"))
        try renderNative(MenuPanel(model: model, previewLayout: .single), width: 410, height: 700, to: directory.appending(path: "test-servers.png"), fitHeight: true)
        for layout in ServerLayout.allCases {
            try renderNative(MenuPanel(model: model, previewLayout: layout), width: layout == .single ? 410 : 500, height: 600, to: directory.appending(path: "menu-\(layout.rawValue).png"), fitHeight: true)
            try renderNative(ServersView(model: model, previewLayout: layout), width: 860, height: 720, to: directory.appending(path: "app-\(layout.rawValue).png"))
        }
        try renderNative(SettingsView(model: model), width: 580, height: 440, to: directory.appending(path: "settings.png"))
        for capacity in [4, 8] {
            let height = capacity == 4 ? 170.0 : 380.0
            let content = ServerListView(records: SyntheticServers.records(), capacity: capacity, currentDate: .now)
                .frame(width: 328, height: height - 32)
                .padding(16)
            try renderNative(content, width: 360, height: height, to: directory.appending(path: "servers-\(capacity).png"))
        }
        #endif
    }

    @MainActor private static func renderNative<V: View>(_ content: V, width: Double, height: Double, to file: URL, fitHeight: Bool = false) throws {
        let view = NSHostingView(rootView: content.background(.background).environment(\.colorScheme, .light))
        view.frame = NSRect(x: 0, y: 0, width: width, height: height)
        if fitHeight { view.frame.size.height = view.fittingSize.height }
        let window = NSWindow(contentRect: view.frame, styleMask: [.borderless], backing: .buffered, defer: false)
        window.contentView = view
        view.layoutSubtreeIfNeeded()
        guard let bitmap = view.bitmapImageRepForCachingDisplay(in: view.bounds) else {
            throw MonitorError.message("Could not render the native view.")
        }
        view.cacheDisplay(in: view.bounds, to: bitmap)
        guard let data = bitmap.representation(using: .png, properties: [:]) else {
            throw MonitorError.message("Could not save the native view.")
        }
        try data.write(to: file)
        window.close()
    }
}
