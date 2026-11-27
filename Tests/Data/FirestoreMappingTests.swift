import FirebaseFirestore
import Foundation
import Testing
@testable import Contrarreloj

struct FirestoreMappingTests {
    private let submission = ScoreSubmission(
        uid: "ana", displayName: "Ana", photoURL: nil, points: 120, correct: 15, wrong: 3, skipped: 1,
        duration: .long, difficultyFilter: .hard, category: nil
    )

    private func questionData(_ overrides: [String: Any] = [:]) -> [String: Any] {
        var data: [String: Any] = [
            "text": "¿Cuál es la capital de Francia?", "options": ["París", "Lyon", "Marsella", "Burdeos"],
            "correctIndex": 0, "category": "Historia y Geografía", "difficulty": "medio",
            "explanation": "París es la capital de Francia.", "status": "active",
            "createdAt": Timestamp(date: Date(timeIntervalSince1970: 1_763_251_200.25)),
        ]
        for (key, value) in overrides { data[key] = value }
        return data
    }

    @Test func submissionDataUsesIntegers() {
        let data = FirestoreMapping.submissionData(submission)
        for key in ["points", "correct", "wrong", "skipped", "duration"] {
            #expect(type(of: data[key]!) == Int.self, "\(key) must be an Int")
        }
        #expect(data["duration"] as? Int == 120)
        #expect(data["difficultyFilter"] as? String == "Difícil")
        #expect(data["photoURL"] is NSNull)
        #expect(data["createdAt"] is FieldValue)
        #expect(Set(data.keys) == ["uid", "displayName", "photoURL", "points", "correct", "wrong", "skipped",
                                   "duration", "difficultyFilter", "createdAt"])
    }

    @Test func categoryOmittedWhenNilAndPresentWhenSet() {
        #expect(FirestoreMapping.submissionData(submission)["category"] == nil)
        let limited = ScoreSubmission(uid: "ana", displayName: "Ana", photoURL: "https://x.example/a.png", points: 1,
                                      correct: 1, wrong: 0, skipped: 0, duration: .short, difficultyFilter: .random,
                                      category: .music)
        #expect(FirestoreMapping.submissionData(limited)["category"] as? String == "Música")
        #expect(FirestoreMapping.submissionData(limited)["photoURL"] as? String == "https://x.example/a.png")
    }

    @Test func timestampBecomesISOString() throws {
        let q = try #require(FirestoreMapping.question(id: "capital-francia", data: questionData()))
        #expect(q.createdAt == "2025-11-16T00:00:00.250Z")
        #expect(q.id == "capital-francia")
    }

    @Test func malformedQuestionIsDropped() {
        #expect(FirestoreMapping.question(id: "capital-francia", data: questionData(["admin": true])) == nil)
        #expect(FirestoreMapping.question(id: "capital-francia", data: questionData(["options": ["París", "Lyon"]])) == nil)
        #expect(FirestoreMapping.question(id: "capital-francia", data: questionData(["difficulty": "imposible"])) == nil)
        #expect(FirestoreMapping.question(id: "Bad Id", data: questionData()) == nil)
        #expect(FirestoreMapping.question(id: "capital-francia", data: questionData(["correctIndex": "0"])) == nil)
    }

    @Test func rankingEntryIsReadAndValidated() throws {
        var data = FirestoreMapping.submissionData(submission)
        data["createdAt"] = Timestamp(date: Date(timeIntervalSince1970: 1_800_000_000))
        let entry = try #require(FirestoreMapping.rankingEntry(data))
        #expect(entry.points == 120)
        #expect(entry.photoURL == nil)
        #expect(entry.createdAt == Date(timeIntervalSince1970: 1_800_000_000))
        data["points"] = 15 * 17 + 1
        #expect(FirestoreMapping.rankingEntry(data) == nil)
    }
}
