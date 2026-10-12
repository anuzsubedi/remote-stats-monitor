import Foundation

enum ProcessRunner {
    struct Output: Sendable { var text: String; var error: String; var status: Int32 }

    static func run(_ executable: String, arguments: [String], environment: [String: String]? = nil) async throws -> Output {
        let execution = ProcessExecution()
        let process = execution.process
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.environment = environment
        process.standardInput = FileHandle.nullDevice
        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr
        // Drain both pipes while the child runs; process lists and ssh -G can
        // exceed a pipe buffer and otherwise deadlock before termination.
        let outputTask = Task.detached { stdout.fileHandleForReading.readDataToEndOfFile() }
        let errorTask = Task.detached { stderr.fileHandleForReading.readDataToEndOfFile() }
        let timeout = Task {
            do { try await Task.sleep(for: .seconds(20)); execution.cancel(timeout: true) }
            catch { }
        }
        defer {
            timeout.cancel()
            try? stdout.fileHandleForWriting.close()
            try? stderr.fileHandleForWriting.close()
        }
        let status: Int32 = try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                process.terminationHandler = { finished in
                    continuation.resume(returning: finished.terminationStatus)
                }
                do {
                    try execution.start()
                    try? stdout.fileHandleForWriting.close()
                    try? stderr.fileHandleForWriting.close()
                } catch { continuation.resume(throwing: error) }
            }
        } onCancel: { execution.cancel() }
        let out = await outputTask.value
        let err = await errorTask.value
        try Task.checkCancellation()
        if execution.didTimeOut { throw MonitorError.message("SSH request timed out. Check your server and network, then try again.") }
        return Output(text: String(decoding: out, as: UTF8.self), error: String(decoding: err, as: UTF8.self), status: status)
    }
}
