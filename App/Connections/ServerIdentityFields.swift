import SwiftUI

struct ServerIdentityFields: View {
    @Binding var connection: Connection

    private let icons: [(symbol: String, title: String)] = [
        ("server.rack", "Server"), ("desktopcomputer", "Desktop"),
        ("laptopcomputer", "Laptop"), ("cpu", "Processor"),
        ("externaldrive", "Storage"), ("internaldrive", "Drive"),
        ("network", "Network"), ("cloud", "Cloud"),
        ("house", "Home"), ("building.2", "Office"),
        ("shippingbox", "Container"), ("gamecontroller", "Gaming")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            TextField("Nickname", text: $connection.nickname, prompt: Text("Optional"))
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
            Text("Icon").foregroundStyle(.secondary)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 8) {
                ForEach(icons, id: \.symbol) { icon in
                    Button {
                        connection.iconName = icon.symbol
                    } label: {
                        Image(systemName: icon.symbol)
                            .font(.title3)
                            .frame(maxWidth: .infinity)
                            .frame(height: 34)
                            .foregroundStyle(connection.iconName == icon.symbol ? Color.accentColor : Color.primary)
                            .background(connection.iconName == icon.symbol ? Color.accentColor.opacity(0.12) : Color.clear, in: .rect(cornerRadius: 8))
                            .overlay {
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(connection.iconName == icon.symbol ? Color.accentColor : Color.secondary.opacity(0.2))
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(icon.title)
                    .accessibilityAddTraits(connection.iconName == icon.symbol ? .isSelected : [])
                    .help(icon.title)
                }
            }
        }
    }
}
