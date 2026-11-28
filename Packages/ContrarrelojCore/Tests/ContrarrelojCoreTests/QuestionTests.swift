import Foundation
import Testing
@testable import ContrarrelojCore

private func question(
    id: String = "capital-francia",
    text: String = "¿Cuál es la capital de Francia?",
    options: [String] = ["París", "Lyon", "Marsella", "Burdeos"],
    correctIndex: Int = 0,
    source: String? = nil,
    createdAt: String = "2026-11-16T00:00:00.000Z"
) -> Question {
    Question(
        id: id, text: text, options: options, correctIndex: correctIndex, category: .historyAndGeography,
        difficulty: .medium, explanation: "París es la capital de Francia.", source: source,
        createdAt: createdAt, status: .active
    )
}

@Test func validatedAcceptsAGoodQuestionAndTrimsIt() throws {
    let valid = try #require(Question.validated(question(text: "  ¿Cuál es la capital de Francia?  ", options: [" París", "Lyon ", "Marsella", "Burdeos"])))
    #expect(valid.text == "¿Cuál es la capital de Francia?")
    #expect(valid.options == ["París", "Lyon", "Marsella", "Burdeos"])
}

@Test(arguments: [
    question(id: "Bad Id"),
    question(id: "ab"),
    question(options: ["París", "Lyon", "Marsella"]),
    question(options: ["París", "parís", "Marsella", "Burdeos"]),
    question(options: ["París", "   ", "Marsella", "Burdeos"]),
    question(text: "123456789"),
    question(correctIndex: 4),
    question(correctIndex: -1),
    question(source: ""),
    question(createdAt: "16/11/2026"),
])
func validatedRejectsBadQuestions(_ bad: Question) {
    #expect(Question.validated(bad) == nil)
}

@Test func validatedAcceptsMinutePrecisionAndFractionalSeconds() {
    #expect(Question.validated(question(createdAt: "2026-11-16T10:30Z")) != nil)
    #expect(Question.validated(question(createdAt: "2026-11-16T10:30:00Z")) != nil)
    #expect(Question.validated(question(createdAt: "2026-11-16T10:30:00.123456Z")) != nil)
    #expect(Question.validated(question(createdAt: "2026-11-16T10:30:00+01:00")) == nil)
}

@Test func decodingRejectsUnknownFields() throws {
    let json = """
    {"id":"capital-francia","text":"¿Cuál es la capital de Francia?","options":["París","Lyon","Marsella","Burdeos"],
     "correctIndex":0,"category":"Historia y Geografía","difficulty":"medio","explanation":"París es la capital de Francia.",
     "createdAt":"2026-11-16T00:00:00.000Z","status":"active","admin":true}
    """
    #expect(throws: (any Error).self) { try JSONDecoder().decode(Question.self, from: Data(json.utf8)) }
}

@Test func sampleQuestionsDecodeAndValidate() throws {
    let fixture = try QuestionsFixture.load()
    #expect(fixture.questions.count == 143)
    for q in fixture.questions {
        #expect(Question.validated(q) == q, "\(q.id)")
    }
}
