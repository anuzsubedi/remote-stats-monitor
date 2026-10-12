import SwiftUI

struct ConnectionView: View {
    @Bindable var model: MonitorModel
    @Environment(\.dismissWindow) private var dismissWindow
    @State private var showForgetConfirmation = false

    private var isEditing: Bool { model.sessions.contains { $0.id == model.draft.id } }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                Image(systemName: "server.rack")
                    .font(.title).foregroundStyle(.secondary).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text(isEditing ? "Connection" : "Add server").font(.largeTitle.weight(.bold))
                    Text("Use an SSH address or a saved SSH alias.")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
            }
            GroupBox {
                ConnectionFieldsView(connection: $model.draft, chooseKey: chooseKey)
                    .padding(10)
            }
            Toggle("Collect GPU usage", isOn: $model.draft.collectGPU)
                .help("Enable GPU sampling for this server. Off skips GPU commands and counter scans.")
            Text("Credentials are saved in Keychain. Private keys stay in their original files.")
                .font(.caption).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            if let error = model.error ?? (model.selectedSession?.id == model.draft.id ? model.selectedSession?.error : nil) {
                Label(error, systemImage: "exclamationmark.circle.fill")
                    .font(.callout).foregroundStyle(.red).lineLimit(4).help(error)
                    .fixedSize(horizontal: false, vertical: true)
            }
            HStack {
                Spacer()
                if isEditing {
                    Button("Forget server", role: .destructive) { showForgetConfirmation = true }
                }
            }.font(.callout)
            #if DEBUG
            DebugServersView(model: model)
            #endif
            Divider()
            HStack(spacing: 10) {
                if model.isConnecting {
                    ProgressView().controlSize(.small)
                    Text("Connecting…").font(.callout).foregroundStyle(.secondary)
                }
                Spacer()
                Button("Cancel") { dismissWindow(id: "connection") }
                    .keyboardShortcut(.cancelAction)
                Button("Connect") { Task { await model.beginConnection() } }
                    .buttonStyle(.glassProminent).keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 520)
        .background(.background)
        .disabled(model.isConnecting)
        .alert("Trust this server?", isPresented: $model.showHostKeyPrompt) {
            Button("Trust & connect") { Task { await model.trustAndConnect() } }
            Button("Cancel", role: .cancel) { model.cancelTrust() }
        } message: {
            Text("First connection to \(model.draft.host). Check this SSH host key fingerprint against your server:\n\n\(model.keyProposal?.fingerprint ?? "")")
        }
        .confirmationDialog("Remove this server and its saved credentials?", isPresented: $showForgetConfirmation) {
            Button("Forget server", role: .destructive) { Task { await model.forgetConnection() } }
        }
    }

    private func chooseKey() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.showsHiddenFiles = true
        panel.message = "Choose your SSH private key. The key stays in this file."
        panel.begin { response in
            if response == .OK, let url = panel.url { model.draft.privateKeyPath = url.path }
        }
    }
}
