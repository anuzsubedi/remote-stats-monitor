import Foundation

// Process's callback API runs outside Swift concurrency. The lock protects its
// start/cancel race; the wrapper never exposes mutable state to callers.
final class ProcessExecution: @unchecked Sendable {
    let process = Process()
    private let lock = NSLock()
    private var cancelled = false
    private var timedOut = false

    func start() throws {
        try lock.withLock {
            guard !cancelled else { throw CancellationError() }
            try process.run()
        }
    }

    func cancel(timeout: Bool = false) {
        lock.withLock {
            cancelled = true
            timedOut = timeout
            if process.isRunning { process.terminate() }
        }
    }

    var didTimeOut: Bool { lock.withLock { timedOut } }
}
