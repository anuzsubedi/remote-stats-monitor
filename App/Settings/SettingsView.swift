import SwiftUI

struct SettingsView: View {
    @Bindable var model: MonitorModel
    @AppStorage("menuLayout") private var layout = ServerLayout.single

    var body: some View {
        Form {
            Section("General") {
                Toggle("Open at login", isOn: $model.launchesAtLogin)
                    .onChange(of: model.launchesAtLogin) { model.setLaunchAtLogin() }
                Picker("Menu bar layout", selection: $layout) {
                    ForEach(ServerLayout.allCases) { Text($0.rawValue).tag($0) }
                }
                Text("New connections become the selected server. All saved servers reconnect when the app starts.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("Desktop widgets") {
                Text("Control-click the desktop, choose Edit Widgets, and search for Remote Stats Monitor.")
                LabeledContent("Server overview", value: "Small · Medium · Large")
                LabeledContent("Server list and grid", value: "4 or 8 servers")
                LabeledContent("CPU · GPU · Memory · Disk · Temperature", value: "Small · Medium")
                LabeledContent("Top processes", value: "Medium · Large")
                Text("Edit a widget to choose its servers. Widget refresh timing is controlled by macOS; keep the app running to collect readings.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            if let error = model.error {
                Section("App status") { Text(error).foregroundStyle(.red) }
            }
        }.formStyle(.grouped).frame(width: 580, height: 440)
    }
}
