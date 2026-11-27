import Foundation

/// What Firestore answers about the question bank.
nonisolated struct RemoteBank: Sendable {
    let questions: [Question]
    /// Active documents on the server, malformed ones included (what `count()` will report).
    let documentCount: Int
}

nonisolated protocol RemoteQuestionSource: Sendable {
    /// Number of active question documents, read with a cheap aggregate query.
    func activeCount() async throws -> Int
    func fetchActive() async throws -> RemoteBank
}

nonisolated struct CachedBank: Codable, Sendable {
    let savedAt: Date
    /// Server document count when it was saved, compared with `activeCount()`.
    let count: Int
    let questions: [Question]
}

nonisolated protocol QuestionCacheStore: Sendable {
    func read() -> CachedBank?
    func write(_ bank: CachedBank)
}

nonisolated enum QuestionOrigin: Sendable {
    case cache, network, staleCache, bundled
}

/// Where the questions of a game come from. Firestore is the source of truth; a local copy is
/// kept for 24 h and reused while the server still has the same number of active questions (a
/// count costs ~3 reads instead of one per question). If Firestore is unavailable, the last copy
/// (even an old one) or the questions bundled with the app are used, so the game always plays.
actor QuestionBank {
    private let remote: (any RemoteQuestionSource)?
    private let cache: any QuestionCacheStore
    private let bundled: @Sendable () -> [Question]
    private let now: @Sendable () -> Date
    private let ttl: TimeInterval
    private let timeout: Duration
    private let sleep: Sleeper

    init(
        remote: (any RemoteQuestionSource)?,
        cache: any QuestionCacheStore,
        bundled: @escaping @Sendable () -> [Question],
        now: @escaping @Sendable () -> Date = { Date() },
        ttl: TimeInterval = 86_400,
        timeout: Duration = .seconds(6),
        sleep: @escaping Sleeper = realSleeper
    ) {
        self.remote = remote
        self.cache = cache
        self.bundled = bundled
        self.now = now
        self.ttl = ttl
        self.timeout = timeout
        self.sleep = sleep
    }

    func load() async -> (questions: [Question], origin: QuestionOrigin) {
        guard let remote else { return (bundled(), .bundled) }
        let cached = cache.read()

        if let cached, isFresh(cached) {
            do {
                let count = try await withTimeout(timeout, sleep: sleep) { try await remote.activeCount() }
                if count == cached.count { return (cached.questions, .cache) }
            } catch {
                return (cached.questions, .cache) // offline: a fresh copy is good enough
            }
        }

        do {
            let fresh = try await withTimeout(timeout, sleep: sleep) { try await remote.fetchActive() }
            if !fresh.questions.isEmpty {
                cache.write(CachedBank(savedAt: now(), count: fresh.documentCount, questions: fresh.questions))
                return (fresh.questions, .network)
            }
        } catch {
            // Offline, blocked, slow or misconfigured: fall back below.
        }

        if let cached, !cached.questions.isEmpty { return (cached.questions, .staleCache) }
        return (bundled(), .bundled)
    }

    private func isFresh(_ cached: CachedBank) -> Bool {
        let age = now().timeIntervalSince(cached.savedAt)
        return age >= 0 && age < ttl
    }
}
