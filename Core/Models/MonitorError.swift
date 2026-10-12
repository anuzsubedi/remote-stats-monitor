import Foundation

enum MonitorError: LocalizedError {
    case message(String)
    case authentication
    var errorDescription: String? {
        switch self {
        case .message(let message): message
        case .authentication: "SSH authentication failed. Check your username, password, or SSH key."
        }
    }
}
