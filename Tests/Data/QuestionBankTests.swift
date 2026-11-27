import Foundation
import Testing
@testable import Contrarreloj

private let day: TimeInterval = 86_400
private let start = Date(timeIntervalSince1970: 1_800_000_000)

nonisolated private final class SleepRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var _requested: [Duration] = []
    var requested: [Duration] { lock.withLock { _requested } }
    /// Returns at once, so any timeout fires immediately.
    var sleeper: @Sendable (Duration) async throws -> Void {
        { [self] duration in lock.withLock { _requested.append(duration) } }
    }
}

struct QuestionBankTests {
    let cached = GameFixtures.bank(count: 3)
    let fresh = GameFixtures.bank(.hard, count: 4)
    let bundled = GameFixtures.bank(.easy, count: 2)

    private func bank(
        remote: FakeQuestionSource?, cache: InMemoryQuestionCache, now: Date = start,
        sleep: @escaping @Sendable (Duration) async throws -> Void = { try await Task.sleep(for: $0) }
    ) -> QuestionBank {
        let bundled = bundled
        return QuestionBank(remote: remote, cache: cache, bundled: { bundled }, now: { now }, sleep: sleep)
    }

    @Test func freshCacheWithSameCountUsesCache() async {
        let remote = FakeQuestionSource(count: .success(3), fetch: .success(RemoteBank(questions: fresh, documentCount: 4)))
        let cache = InMemoryQuestionCache(CachedBank(savedAt: start.addingTimeInterval(-3_600), count: 3, questions: cached))
        let result = await bank(remote: remote, cache: cache).load()
        #expect(result.origin == .cache)
        #expect(result.questions == cached)
        #expect(remote.fetchCalls == 0)
    }

    @Test func countChangedRefetches() async {
        let remote = FakeQuestionSource(count: .success(4), fetch: .success(RemoteBank(questions: fresh, documentCount: 4)))
        let cache = InMemoryQuestionCache(CachedBank(savedAt: start.addingTimeInterval(-3_600), count: 3, questions: cached))
        let result = await bank(remote: remote, cache: cache).load()
        #expect(result.origin == .network)
        #expect(result.questions == fresh)
        #expect(cache.stored?.count == 4)
        #expect(cache.stored?.savedAt == start)
    }

    @Test func cacheStoresTheServerDocumentCountNotTheValidQuestions() async {
        // 5 active documents on the server, one malformed: the next count check must still match.
        let remote = FakeQuestionSource(count: .success(5), fetch: .success(RemoteBank(questions: fresh, documentCount: 5)))
        let cache = InMemoryQuestionCache(nil)
        _ = await bank(remote: remote, cache: cache).load()
        #expect(cache.stored?.count == 5)
        let again = await bank(remote: remote, cache: cache).load()
        #expect(again.origin == .cache)
        #expect(remote.fetchCalls == 1)
    }

    @Test func countFailsOfflineWithFreshCacheUsesCache() async {
        let remote = FakeQuestionSource(count: .failure(.offline), fetch: .failure(.offline))
        let cache = InMemoryQuestionCache(CachedBank(savedAt: start.addingTimeInterval(-60), count: 3, questions: cached))
        let result = await bank(remote: remote, cache: cache).load()
        #expect(result.origin == .cache)
        #expect(result.questions == cached)
        #expect(remote.fetchCalls == 0)
    }

    @Test func expiredCacheRefetchesAndSaves() async {
        let remote = FakeQuestionSource(count: .success(3), fetch: .success(RemoteBank(questions: fresh, documentCount: 4)))
        let cache = InMemoryQuestionCache(CachedBank(savedAt: start.addingTimeInterval(-day - 1), count: 3, questions: cached))
        let result = await bank(remote: remote, cache: cache).load()
        #expect(result.origin == .network)
        #expect(remote.countCalls == 0)
        #expect(cache.stored?.questions == fresh)
    }

    @Test func fetchFailsUsesStaleCache() async {
        let remote = FakeQuestionSource(count: .failure(.offline), fetch: .failure(.offline))
        let cache = InMemoryQuestionCache(CachedBank(savedAt: start.addingTimeInterval(-3 * day), count: 3, questions: cached))
        let result = await bank(remote: remote, cache: cache).load()
        #expect(result.origin == .staleCache)
        #expect(result.questions == cached)
    }

    @Test func fetchFailsWithoutCacheUsesBundled() async {
        let remote = FakeQuestionSource(count: .failure(.offline), fetch: .failure(.offline))
        let result = await bank(remote: remote, cache: InMemoryQuestionCache(nil)).load()
        #expect(result.origin == .bundled)
        #expect(result.questions == bundled)
    }

    @Test func emptyRemoteUsesFallback() async {
        let remote = FakeQuestionSource(count: .success(0), fetch: .success(RemoteBank(questions: [], documentCount: 0)))
        let cache = InMemoryQuestionCache(nil)
        let result = await bank(remote: remote, cache: cache).load()
        #expect(result.origin == .bundled)
        #expect(cache.stored == nil)
    }

    @Test func slowRemoteTimesOutAfterSixSeconds() async {
        let remote = FakeQuestionSource(count: .hang, fetch: .hang)
        let recorder = SleepRecorder()
        let result = await bank(remote: remote, cache: InMemoryQuestionCache(nil), sleep: recorder.sleeper).load()
        #expect(result.origin == .bundled)
        #expect(recorder.requested == [.seconds(6)])
    }

    @Test func noRemoteUsesBundled() async {
        let result = await bank(remote: nil, cache: InMemoryQuestionCache(nil)).load()
        #expect(result.origin == .bundled)
        #expect(result.questions == bundled)
    }
}
