import AppIntents
import Foundation

struct ServerWidgetEntity: AppEntity, Hashable, Sendable {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Server")
    static let defaultQuery = ServerWidgetEntityQuery()

    let id: UUID
    let name: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }

    init(_ descriptor: ServerDescriptor) {
        id = descriptor.id
        name = descriptor.name
    }
}
