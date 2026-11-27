import Foundation

nonisolated struct TimeoutError: Error, Equatable {}

/// How a time limit waits. Injected so tests can make a timeout fire at once.
typealias Sleeper = @Sendable (Duration) async throws -> Void

nonisolated let realSleeper: Sleeper = { try await Task.sleep(for: $0) }

/// Runs `operation`, giving up with `TimeoutError` after `limit` (the web's `withTimeout`).
nonisolated func withTimeout<T: Sendable>(
    _ limit: Duration,
    sleep: @escaping Sleeper = realSleeper,
    _ operation: @escaping @Sendable () async throws -> T
) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask { try await operation() }
        group.addTask {
            try await sleep(limit)
            throw TimeoutError()
        }
        defer { group.cancelAll() }
        guard let first = try await group.next() else { throw TimeoutError() }
        return first
    }
}
