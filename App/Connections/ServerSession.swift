import SwiftUI

@MainActor @Observable
final class ServerSession: Identifiable {
    let id: UUID
    var connection: Connection
    var snapshot: MonitorSnapshot?
    var error: String?
    var isRefreshing = false
    var authenticationFailed = false
    var isSynthetic = false
    @ObservationIgnored let ssh = SSHService()
    @ObservationIgnored var pollTask: Task<Void, Never>?
    @ObservationIgnored var generation = 0

    init(connection: Connection, snapshot: MonitorSnapshot? = nil) {
        id = connection.id
        self.connection = connection
        self.snapshot = snapshot
    }
}
