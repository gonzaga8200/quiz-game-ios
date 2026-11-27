import Testing
@testable import ContrarrelojCore

private struct QueuesFixture: Decodable {
    struct Entry: Decodable {
        let id: String
        let order: [Int]
        let correctIndex: Int
    }
    struct Case: Decodable {
        let seed: UInt32
        let filter: DifficultyFilter
        let category: QuizCategory?
        let seen: Bool
        let queue: [Entry]
    }
    let cases: [Case]
}

@Test func queuesMatchFixture() throws {
    let sample = try QuestionsFixture.load()
    let fixture = try Fixture.load("queues", as: QueuesFixture.self)
    #expect(fixture.cases.count == 80)
    var firstById: [String: Question] = [:]
    for q in sample.questions where firstById[q.id] == nil { firstById[q.id] = q }

    for testCase in fixture.cases {
        let queue = buildQueue(
            sample.questions, filter: testCase.filter, rng: mulberry32(seed: testCase.seed),
            category: testCase.category, seen: testCase.seen ? sample.seen : nil
        )
        let label = "seed \(testCase.seed) \(testCase.filter) \(testCase.category?.rawValue ?? "-") seen \(testCase.seen)"
        #expect(queue.map(\.id) == testCase.queue.map(\.id), "\(label)")
        guard queue.count == testCase.queue.count else { continue }
        for (playable, expected) in zip(queue, testCase.queue) {
            let original = try #require(firstById[playable.id])
            #expect(playable.options == expected.order.map { original.options[$0] }, "\(label) \(playable.id)")
            #expect(playable.correctIndex == expected.correctIndex, "\(label) \(playable.id)")
        }
    }
}

@Test func disabledAndDuplicatesAreDropped() throws {
    let sample = try QuestionsFixture.load()
    let active = sample.questions[0]
    var disabled = sample.questions[1]
    disabled = Question(
        id: disabled.id, text: disabled.text, options: disabled.options, correctIndex: disabled.correctIndex,
        category: disabled.category, difficulty: disabled.difficulty, explanation: disabled.explanation,
        source: disabled.source, createdAt: disabled.createdAt, status: .disabled
    )
    let queue = buildQueue([active, active, disabled], filter: .random, rng: mulberry32(seed: 1))
    #expect(queue.map(\.id) == [active.id])
}

@Test func playableKeepsTheRightAnswer() throws {
    let sample = try QuestionsFixture.load()
    let rng = mulberry32(seed: 3)
    for q in sample.questions.prefix(20) {
        let playable = toPlayable(q, rng: rng)
        #expect(playable.options.sorted() == q.options.sorted())
        #expect(playable.options[playable.correctIndex] == q.options[q.correctIndex])
    }
}

@Test func spreadRunsNeverDropsItems() {
    let items = ["a1", "a2", "a3", "a4", "b1"]
    let rule = SpreadRule<String>(key: { String($0.prefix(1)) }, max: 1)
    let out = spreadRuns(items, rules: [rule])
    #expect(out.count == items.count)
    #expect(Set(out) == Set(items))
    #expect(Array(out.prefix(3)) == ["a1", "b1", "a2"])
}
