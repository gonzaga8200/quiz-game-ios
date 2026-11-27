import FirebaseFirestore
import Foundation

/// Converts between Firestore documents and the shared models, with the same strictness as the
/// web's zod schemas: a malformed document becomes nil and is skipped.
nonisolated enum FirestoreMapping {
    private static let questionKeys: Set<String> = [
        "id", "text", "options", "correctIndex", "category", "difficulty", "explanation", "source", "createdAt", "status",
    ]
    private static let entryKeys: Set<String> = [
        "uid", "displayName", "photoURL", "points", "correct", "wrong", "skipped", "duration", "difficultyFilter",
        "category", "createdAt",
    ]

    static func question(id: String, data: [String: Any]) -> Question? {
        guard Set(data.keys).isSubset(of: questionKeys),
              let text = data["text"] as? String,
              let options = data["options"] as? [String],
              let correctIndex = integer(data["correctIndex"]),
              let category = (data["category"] as? String).flatMap(QuizCategory.init(rawValue:)),
              let difficulty = (data["difficulty"] as? String).flatMap(Difficulty.init(rawValue:)),
              let explanation = data["explanation"] as? String,
              let status = (data["status"] as? String).flatMap(QuestionStatus.init(rawValue:)),
              let createdAt = isoString(data["createdAt"])
        else { return nil }
        let source: String?
        switch data["source"] {
        case nil: source = nil
        case let value as String: source = value
        default: return nil
        }
        return Question.validated(Question(
            id: id, text: text, options: options, correctIndex: correctIndex, category: category,
            difficulty: difficulty, explanation: explanation, source: source, createdAt: createdAt, status: status
        ))
    }

    static func rankingEntry(_ data: [String: Any]) -> RankingEntry? {
        guard Set(data.keys).isSubset(of: entryKeys),
              let uid = data["uid"] as? String,
              let displayName = data["displayName"] as? String,
              let points = integer(data["points"]), let correct = integer(data["correct"]),
              let wrong = integer(data["wrong"]), let skipped = integer(data["skipped"]),
              let duration = integer(data["duration"]).flatMap(GameDuration.init(rawValue:)),
              let filter = (data["difficultyFilter"] as? String).flatMap(DifficultyFilter.init(rawValue:)),
              let createdAt = (data["createdAt"] as? Timestamp)?.dateValue()
        else { return nil }
        let photoURL: String?
        switch data["photoURL"] {
        case nil, is NSNull: photoURL = nil
        case let value as String: photoURL = value
        default: return nil
        }
        let category: QuizCategory?
        switch data["category"] {
        case nil: category = nil
        case let value as String:
            guard let parsed = QuizCategory(rawValue: value) else { return nil }
            category = parsed
        default: return nil
        }
        let entry = RankingEntry(
            uid: uid, displayName: displayName.trimmingCharacters(in: .whitespacesAndNewlines), photoURL: photoURL,
            points: points, correct: correct, wrong: wrong, skipped: skipped, duration: duration,
            difficultyFilter: filter, category: category, createdAt: createdAt
        )
        return entry.isValid ? entry : nil
    }

    /// The document written for a score. Every number is an `Int` (the rules require `int`), the
    /// time is the server's, `category` only when the game had one.
    static func submissionData(_ s: ScoreSubmission) -> [String: Any] {
        var data: [String: Any] = [
            "uid": s.uid,
            "displayName": s.displayName,
            "photoURL": s.photoURL.map { $0 as Any } ?? NSNull(),
            "points": s.points,
            "correct": s.correct,
            "wrong": s.wrong,
            "skipped": s.skipped,
            "duration": s.duration.rawValue,
            "difficultyFilter": s.difficultyFilter.rawValue,
            "createdAt": FieldValue.serverTimestamp(),
        ]
        if let category = s.category { data["category"] = category.rawValue }
        return data
    }

    /// An integral number (Firestore may hand back Int64 or a whole Double); nil otherwise.
    private static func integer(_ value: Any?) -> Int? {
        guard let number = value as? NSNumber, !(value is Bool), CFGetTypeID(number) != CFBooleanGetTypeID() else { return nil }
        let double = number.doubleValue
        guard double.rounded() == double, abs(double) < 9_007_199_254_740_992 else { return nil }
        return number.intValue
    }

    /// Timestamps become the ISO string of JavaScript's `toISOString` (milliseconds and `Z`).
    private static func isoString(_ value: Any?) -> String? {
        switch value {
        case let timestamp as Timestamp:
            return Date.ISO8601FormatStyle(includingFractionalSeconds: true).format(timestamp.dateValue())
        case let string as String:
            return string
        default:
            return nil
        }
    }
}
