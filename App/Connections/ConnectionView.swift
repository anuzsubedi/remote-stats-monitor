import SwiftUI

struct ConnectionView: View {
    @Bindable var model: MonitorModel
    var onAddTestServers: (() -> Void)? = nil
    @Environment(\.dismissWindow) private var dismissWindow
    @State private var showForgetConfirmation = false

    private var isEditing: Bool { model.sessions.contains { $0.id == model.draft.id } }

    private var isSynthetic: Bool { model.sessions.first { $0.id == model.draft.id }?.isSynthetic == true }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: model.draft.iconName)
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                    Text(isEditing ? "Edit server" : "Add server")
                        .font(.title2.weight(.semibold))
                    Text(isSynthetic ? "Customize this test server." : "Connect with an SSH address or saved alias.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 24)
            .padding(.top, 22)
            .padding(.bottom, 8)

            Form {
                Section("Identity") {
                    ServerIdentityFields(connection: $model.draft)
                }

                if !isSynthetic {
                    Section {
                        ConnectionFieldsView(connection: $model.draft, chooseKey: chooseKey)
                    } header: {
                        Text("SSH connection")
                    } footer: {
                        Text("Leave the port blank to use your SSH config or port 22.")
                    }

                    Section {
                        Toggle("Collect GPU usage", isOn: $model.draft.collectGPU)
                    } header: {
                        Text("Monitoring")
                    } footer: {
                        Text("Turn this off to skip GPU commands and counter scans.")
                    }

                    Section {
                        Label("Passwords and key passphrases are saved in Keychain.", systemImage: "key.horizontal")
                    } header: {
                        Text("Credentials")
                    } footer: {
                        Text("Private keys stay in their original files.")
                    }

                }

                if let error = model.error ?? (model.selectedSession?.id == model.draft.id ? model.selectedSession?.error : nil) {
                    Section("Connection error") {
                        Label(error, systemImage: "exclamationmark.circle.fill")
                            .foregroundStyle(.red)
                            .fixedSize(horizontal: false, vertical: true)
                            .help(error)
                    }
                }

                if isEditing && !isSynthetic {
                    Section {
                        Button("Forget server", role: .destructive) {
                            showForgetConfirmation = true
                        }
                    }
                }

                #if DEBUG
                Section("Developer tools") {
                    DebugServersView(model: model, onAdded: onAddTestServers)
                }
                #endif
            }
            .formStyle(.grouped)

            Divider()

            HStack(spacing: 10) {
                if model.isConnecting {
                    ProgressView().controlSize(.small)
                    Text("Connecting…")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Cancel") { dismissWindow(id: "connection") }
                    .keyboardShortcut(.cancelAction)
                Button(isEditing ? "Save changes" : "Connect") { Task { await model.beginConnection() } }
                    .buttonStyle(.glassProminent)
                    .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .frame(width: 560, height: 660)
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
