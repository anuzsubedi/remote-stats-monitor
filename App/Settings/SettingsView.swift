import SwiftUI

struct SettingsView: View {
    @Bindable var model: MonitorModel
    @AppStorage("menuLayout") private var layout = ServerLayout.single

    var body: some View {
        Form {
            Section {
                Toggle("Open at login", isOn: $model.launchesAtLogin)
                    .onChange(of: model.launchesAtLogin) { model.setLaunchAtLogin() }
                Picker("Menu bar layout", selection: $layout) {
                    ForEach(ServerLayout.allCases) { Text($0.rawValue).tag($0) }
                }
            } header: {
                    Text("General")
                } footer: {
                Text("New connections are selected automatically. Saved servers reconnect when the app starts.")
            }
            Section {
                LabeledContent("Server overview", value: "Small, medium, large")
                LabeledContent("Server list and grid", value: "4 or 8 servers")
                LabeledContent("Individual metrics", value: "CPU, GPU, memory, disk, temperature")
                LabeledContent("Top processes", value: "Medium, large")
            } header: {
                    Text("Desktop widgets")
                } footer: {
                VStack(alignment: .leading, spacing: 6) {
                    Text("To add a widget, Control-click the desktop, choose Edit Widgets, then search for Remote Stats Monitor.")
                    Text("Metric widgets are small or medium. Edit a widget to choose servers. macOS controls refresh timing; keep the app running to collect readings.")
                }
            }
            if let error = model.error {
                Section("App status") {
                    Label(error, systemImage: "exclamationmark.circle.fill")
                        .foregroundStyle(.red)
                        .textSelection(.enabled)
                }
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 580, minHeight: 440)
    }
}
