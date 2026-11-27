import Testing
@testable import ContrarrelojCore

private struct ShowcaseFixture: Decodable {
    struct Entry: Decodable {
        let category: QuizCategory
        let ids: [String]
    }
    let categories: [Entry]
    let counts: [String: Int]
}

@Test func showcaseMatchesFixture() throws {
    let sample = try QuestionsFixture.load()
    let fixture = try Fixture.load("showcase", as: ShowcaseFixture.self)
    #expect(fixture.categories.count == 7)
    for entry in fixture.categories {
        #expect(pickShowcase(sample.questions, category: entry.category, count: 20).map(\.id) == entry.ids,
                "\(entry.category.rawValue)")
    }
}

@Test func countsMatchFixture() throws {
    let sample = try QuestionsFixture.load()
    let fixture = try Fixture.load("showcase", as: ShowcaseFixture.self)
    let counts = countActiveByCategory(sample.questions)
    #expect(Dictionary(uniqueKeysWithValues: counts.map { ($0.key.rawValue, $0.value) }) == fixture.counts)
}

@Test func showcaseIsStableRegardlessOfInputOrder() throws {
    let sample = try QuestionsFixture.load()
    let forward = pickShowcase(sample.questions, category: .music, count: 20)
    let backward = pickShowcase(sample.questions.reversed(), category: .music, count: 20)
    #expect(forward.map(\.id) == backward.map(\.id))
}
