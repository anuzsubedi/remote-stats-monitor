import AppIntents
import Foundation

struct ServerWidgetEntityQuery: EntityQuery, Sendable {
    func entities(for identifiers: [UUID]) async throws -> [ServerWidgetEntity] {
        var seen = Set<UUID>()
        return identifiers.compactMap { WidgetServerSource.record(for: $0).map { ServerWidgetEntity($0.server) } }.filter { seen.insert($0.id).inserted }
    }

    func suggestedEntities() async throws -> [ServerWidgetEntity] {
        WidgetServerSource.servers().map(ServerWidgetEntity.init)
    }
}
