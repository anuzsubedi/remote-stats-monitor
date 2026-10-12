import SwiftUI

struct MenuPanel: View {
    @Bindable var model: MonitorModel
    @Environment(\.openWindow) private var openWindow
    @AppStorage("menuLayout") private var storedLayout = ServerLayout.single
    var onOpenSection: ((AppNavigationSection) -> Void)? = nil
    var previewLayout: ServerLayout? = nil

    private var layout: ServerLayout { previewLayout ?? storedLayout }
    private var panelWidth: CGFloat { layout == .single ? 420 : 500 }
    private var browserHeight: CGFloat {
        guard !model.sessions.isEmpty else { return 220 }
        return switch layout {
        case .single: 460
        case .list: min(430, CGFloat(model.sessions.count) * 78 + 16)
        case .grid: min(430, CGFloat((model.sessions.count + 1) / 2) * 174 + 16)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Remote Stats")
                        .font(.headline)
                    Text(model.sessions.count == 1 ? "1 server" : "\(model.sessions.count) servers")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                Button("Open servers", systemImage: "arrow.up.right.square") {
                    openSection(.overview)
                }
                .labelStyle(.iconOnly)
                .buttonStyle(.plain)
                .help("Open server overview")

                settingsMenu
            }
            .padding(.horizontal, 18)
            .padding(.top, 16)
            .padding(.bottom, 14)

            Picker("View", selection: Binding(get: { layout }, set: { storedLayout = $0 })) {
                ForEach(ServerLayout.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(.horizontal, 18)
            .padding(.bottom, 14)

            Divider()

            ServerBrowser(model: model, layout: layout, compact: true, onShowProcesses: { openSection(.processes) })
                .frame(height: browserHeight)

            Divider()

            HStack(spacing: 10) {
                Button("Add server", systemImage: "plus") {
                    model.addServer()
                    openSection(.servers)
                    openWindow(id: "connection")
                    NSApp.activate()
                }
                .buttonStyle(.glassProminent)

                Button("All servers", systemImage: "server.rack") {
                    openSection(.servers)
                }
                .buttonStyle(.glass)

                Spacer(minLength: 0)
            }
            .font(.callout)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .frame(width: panelWidth)
    }

    private var settingsMenu: some View {
        Menu("More", systemImage: "ellipsis") {
            Button("Settings & widgets…") {
                openSection(.settings)
            }

            if model.selectedSession != nil {
                Button("Edit selected connection…") {
                    model.editSelected()
                    openWindow(id: "connection")
                    NSApp.activate()
                }
                Button("Refresh selected server") { Task { await model.refresh() } }
                    .disabled(model.isRefreshing)
            }

            #if DEBUG
            Button("Add test servers") { model.addSyntheticServers() }
                .disabled(model.hasSyntheticServers)
            Button("Remove test servers") { model.removeSyntheticServers() }
                .disabled(!model.hasSyntheticServers)
            #endif

            Divider()
            Button("Quit Remote Stats Monitor") { NSApp.terminate(nil) }
                .keyboardShortcut("q")
        }
        .labelStyle(.iconOnly)
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .help("More actions")
    }

    private func openSection(_ section: AppNavigationSection) {
        if let onOpenSection {
            onOpenSection(section)
        } else {
            openWindow(id: "servers")
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
