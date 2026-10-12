import SwiftUI

struct MenuPanel: View {
    @Bindable var model: MonitorModel
    @Environment(\.openWindow) private var openWindow
    @AppStorage("menuLayout") private var storedLayout = ServerLayout.single
    var previewLayout: ServerLayout? = nil
    private var layout: ServerLayout { previewLayout ?? storedLayout }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Label("Remote Stats", systemImage: "server.rack").font(.headline)
                Spacer()
                Text("\(model.sessions.count) servers").font(.caption).foregroundStyle(.secondary)
                Button("Open servers", systemImage: "arrow.up.right.square") { openWindow(id: "servers"); NSApp.activate() }
                    .labelStyle(.iconOnly).buttonStyle(.plain).help("Open server overview")
            }.padding(16)
            Picker("View", selection: Binding(get: { layout }, set: { storedLayout = $0 })) {
                ForEach(ServerLayout.allCases) { Label($0.rawValue, systemImage: $0.symbol).tag($0) }
            }.pickerStyle(.segmented).labelsHidden().padding(.horizontal, 16).padding(.bottom, 12)
            Divider()
            ServerBrowser(model: model, layout: layout, compact: true)
                .frame(height: model.sessions.isEmpty ? 200 : layout == .single ? 400 : min(440, CGFloat(model.sessions.count) * (layout == .list ? 92 : 110) + 30))
            Divider()
            HStack {
                Button("Add server", systemImage: "plus") { model.addServer(); openWindow(id: "connection"); NSApp.activate() }
                    .buttonStyle(.glassProminent)
                Button("All servers…") { openWindow(id: "servers"); NSApp.activate() }
                    .buttonStyle(.glass)
                Spacer()
                Menu("Settings", systemImage: "gearshape") {
                    Button("Settings & widgets…") { openWindow(id: "settings"); NSApp.activate() }
                    if model.selectedSession != nil {
                        Button("Edit selected connection…") { model.editSelected(); openWindow(id: "connection"); NSApp.activate() }
                        Button("Refresh selected server") { Task { await model.refresh() } }
                    }
                    #if DEBUG
                    Button("Add test servers") { model.addSyntheticServers() }
                    Button("Remove test servers") { model.removeSyntheticServers() }.disabled(!model.hasSyntheticServers)
                    #endif
                    Divider()
                    Button("Quit Remote Stats Monitor") { NSApp.terminate(nil) }.keyboardShortcut("q")
                }.labelStyle(.iconOnly).menuStyle(.borderlessButton).fixedSize()
            }.font(.callout).padding(14)
        }.frame(width: layout == .single ? 410 : 500)
    }
}
