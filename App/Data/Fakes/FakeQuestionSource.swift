import Foundation

nonisolated enum FakeRemoteError: Error, Equatable {
    case offline
}

/// How a fake answers: a value, an error, or never (until cancelled).
nonisolated enum FakeReply<T: Sendable>: Sendable {
    case success(T)
    case failure(FakeRemoteError)
    case hang

    func resolve() async throws -> T {
        switch self {
        case .success(let value): return value
        case .failure(let error): throw error
        case .hang:
            try await Task.sleep(for: .seconds(3_600))
            throw FakeRemoteError.offline
        }
    }
}

/// A question source for previews, tests and UI tests.
nonisolated final class FakeQuestionSource: RemoteQuestionSource, @unchecked Sendable {
    private let lock = NSLock()
    private let count: FakeReply<Int>
    private let fetch: FakeReply<RemoteBank>
    private var _countCalls = 0
    private var _fetchCalls = 0

    var countCalls: Int { lock.withLock { _countCalls } }
    var fetchCalls: Int { lock.withLock { _fetchCalls } }

    init(count: FakeReply<Int>, fetch: FakeReply<RemoteBank>) {
        self.count = count
        self.fetch = fetch
    }

    func activeCount() async throws -> Int {
        lock.withLock { _countCalls += 1 }
        return try await count.resolve()
    }

    func fetchActive() async throws -> RemoteBank {
        lock.withLock { _fetchCalls += 1 }
        return try await fetch.resolve()
    }
}

/// A question cache kept in memory.
nonisolated final class InMemoryQuestionCache: QuestionCacheStore, @unchecked Sendable {
    private let lock = NSLock()
    private var _stored: CachedBank?

    var stored: CachedBank? { lock.withLock { _stored } }

    init(_ initial: CachedBank?) {
        _stored = initial
    }

    func read() -> CachedBank? { stored }

    func write(_ bank: CachedBank) {
        lock.withLock { _stored = bank }
    }
}
