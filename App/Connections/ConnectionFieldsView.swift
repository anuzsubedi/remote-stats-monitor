import SwiftUI

struct ConnectionFieldsView: View {
    @Binding var connection: Connection
    let chooseKey: () -> Void

    var body: some View {
        Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 14) {
            GridRow {
                Text("SSH address").foregroundStyle(.secondary)
                TextField("SSH address", text: $connection.address, prompt: Text(verbatim: "username@hostname.local"))
                    .labelsHidden().accessibilityLabel("SSH address")
            }
            GridRow {
                Text("Port").foregroundStyle(.secondary)
                TextField("Port", text: $connection.portText, prompt: Text("Automatic · SSH config or 22"))
                    .labelsHidden().accessibilityLabel("SSH port, optional")
            }
            GridRow {
                Text("Authentication").foregroundStyle(.secondary)
                Picker("Authentication", selection: $connection.authentication) {
                    ForEach(Connection.Authentication.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }.labelsHidden().accessibilityLabel("Authentication")
            }
            if connection.authentication == .password {
                GridRow {
                    Text("Password").foregroundStyle(.secondary)
                    SecureField("Password", text: $connection.password)
                        .labelsHidden().accessibilityLabel("SSH password")
                }
            } else if connection.authentication == .privateKey {
                GridRow {
                    Text("Private key").foregroundStyle(.secondary)
                    HStack(spacing: 8) {
                        Text(connection.privateKeyPath.isEmpty ? "Choose a key file" : URL(fileURLWithPath: connection.privateKeyPath).lastPathComponent)
                            .lineLimit(1).truncationMode(.middle).frame(maxWidth: .infinity, alignment: .leading)
                        Button("Choose…", action: chooseKey)
                    }
                }
                GridRow {
                    Text("Passphrase").foregroundStyle(.secondary)
                    SecureField("Passphrase", text: $connection.passphrase, prompt: Text("Optional"))
                        .labelsHidden().accessibilityLabel("Private key passphrase")
                }
            }
        }
        .textFieldStyle(.roundedBorder)
        .controlSize(.large)
    }
}
