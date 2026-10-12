import Foundation

struct HostKeyProposal: Identifiable, Sendable {
    let id = UUID()
    let line: String
    let fingerprint: String
}
