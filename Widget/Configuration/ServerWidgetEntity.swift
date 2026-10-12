import AppIntents
import Foundation

struct ServerWidgetEntity: AppEntity, Hashable, Sendable {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Server")
    static let defaultQuery = ServerWidgetEntityQuery()

    let id: UUID
    let name: String
    let iconName: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)", image: .init(systemName: iconName, isTemplate: true))
    }

    init(_ descriptor: ServerDescriptor) {
        id = descriptor.id
        name = descriptor.name
        iconName = descriptor.iconName
    }
}
