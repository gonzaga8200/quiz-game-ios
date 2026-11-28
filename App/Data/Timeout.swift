import Foundation
import os

nonisolated struct TimeoutError: Error, Equatable {}

/// How a time limit waits. Injected so tests can make a timeout fire at once.
typealias Sleeper = @Sendable (Duration) async throws -> Void

nonisolated let realSleeper: Sleeper = { try await Task.sleep(for: $0) }

/// Runs `operation`, giving up with `TimeoutError` after `limit` (the web's `withTimeout`).
///
/// Firebase's async APIs are bridges over completion handlers and ignore cancellation, so a task
/// group (which always waits for its children) would only return when Firestore answered. Here the
/// operation and the timer race in their own tasks and the first to finish answers; the loser is
/// cancelled and left to end on its own. Cancelling the caller ends the wait too.
nonisolated func withTimeout<T: Sendable>(
    _ limit: Duration,
    sleep: @escaping Sleeper = realSleeper,
    _ operation: @escaping @Sendable () async throws -> T
) async throws -> T {
    let race = Race<T>()
    return try await withTaskCancellationHandler {
        try await withCheckedThrowingContinuation { continuation in
            let work = Task {
                do {
                    race.finish(.success(try await operation()))
                } catch {
                    race.finish(.failure(error))
                }
            }
            let timer = Task {
                do {
                    try await sleep(limit)
                    race.finish(.failure(TimeoutError()))
                } catch {
                    // Cancelled: the operation already answered.
                }
            }
            race.start(continuation, tasks: [work, timer])
        }
    } onCancel: {
        race.finish(.failure(CancellationError()))
    }
}

/// Resumes a continuation exactly once with the first result, whichever side produces it, even if
/// that happens before the continuation is in place (a caller cancelled before starting).
nonisolated private final class Race<T: Sendable>: Sendable {
    private struct State: Sendable {
        var continuation: CheckedContinuation<T, any Error>?
        var result: Result<T, any Error>?
        var tasks: [Task<Void, Never>] = []
    }

    private let state = OSAllocatedUnfairLock(initialState: State())

    func start(_ continuation: CheckedContinuation<T, any Error>, tasks: [Task<Void, Never>]) {
        let early: Result<T, any Error>? = state.withLock { state in
            if let result = state.result { return result }
            state.continuation = continuation
            state.tasks = tasks
            return nil
        }
        if let early {
            tasks.forEach { $0.cancel() }
            continuation.resume(with: early)
        }
    }

    func finish(_ result: Result<T, any Error>) {
        let pending: (CheckedContinuation<T, any Error>?, [Task<Void, Never>])? = state.withLock { state in
            guard state.result == nil else { return nil }
            state.result = result
            defer {
                state.continuation = nil
                state.tasks = []
            }
            return (state.continuation, state.tasks)
        }
        guard let (continuation, tasks) = pending else { return }
        tasks.forEach { $0.cancel() }
        continuation?.resume(with: result)
    }
}
