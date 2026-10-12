import SwiftUI

struct SettingsView: View {
    @Bindable var model: MonitorModel
    var embedded = false
    var onAddTestServers: (() -> Void)? = nil
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
            #if DEBUG
            Section("Test servers") {
                DebugServersView(model: model, onAdded: onAddTestServers)
            }
            #endif
            if let error = model.error {
                Section("App status") {
                    Label(error, systemImage: "exclamationmark.circle.fill")
                        .foregroundStyle(.red)
                        .textSelection(.enabled)
                }
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: embedded ? 0 : 580, minHeight: 440)
    }
}
