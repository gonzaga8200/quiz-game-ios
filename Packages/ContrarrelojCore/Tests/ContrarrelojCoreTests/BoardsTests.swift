import Testing
@testable import ContrarrelojCore

private struct BoardsFixture: Decodable {
    struct Entry: Decodable {
        let id: String
        let duration: Int
        let filter: String
        let category: String?
    }
    let boards: [Entry]
}

@Test func boardsMatchFixture() throws {
    let fixture = try Fixture.load("boards", as: BoardsFixture.self)
    #expect(allBoards.count == 64)
    #expect(allBoards.map(\.id) == fixture.boards.map(\.id))
    #expect(allBoards.map(\.duration.rawValue) == fixture.boards.map(\.duration))
    #expect(allBoards.map(\.filter.rawValue) == fixture.boards.map(\.filter))
    #expect(allBoards.map { $0.category?.rawValue } == fixture.boards.map(\.category))
}

@Test func boardIdExamples() {
    #expect(boardId(.short, .medium, nil) == "60_medio")
    #expect(boardId(.short, .medium, .science) == "60_medio_ciencias")
    #expect(boardId(.long, .random, .historyAndGeography) == "120_aleatorio_historia-y-geografia")
}

@Test func personalBestNeedsMorePoints() {
    #expect(isPersonalBest(previousBest: nil, points: 0))
    #expect(isPersonalBest(previousBest: 10, points: 11))
    #expect(!isPersonalBest(previousBest: 10, points: 10))
    #expect(!isPersonalBest(previousBest: 10, points: 9))
}
