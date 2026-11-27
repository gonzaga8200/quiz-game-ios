import Foundation
@testable import ContrarrelojCore

/// The question sample and "seen" map every fixture was generated from (questions.json).
struct QuestionsFixture: Decodable {
    let questions: [Question]
    let seen: [String: Int]

    static func load() throws -> QuestionsFixture {
        try Fixture.load("questions", as: QuestionsFixture.self)
    }
}
