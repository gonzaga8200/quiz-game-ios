import Foundation

/// What a client sends to the ranking after a competitive game. Port of `ScoreSubmissionSchema`
/// in `core/schema.ts`; the Firestore rules enforce the same bounds.
public struct ScoreSubmission: Codable, Equatable, Sendable {
    public let uid: String
    public let displayName: String
    public let photoURL: String?
    public let points: Int
    public let correct: Int
    public let wrong: Int
    public let skipped: Int
    public let duration: GameDuration
    public let difficultyFilter: DifficultyFilter
    /// Only when the game was limited to one category; nil when it mixed them all.
    public let category: QuizCategory?

    public init(
        uid: String, displayName: String, photoURL: String?, points: Int, correct: Int, wrong: Int,
        skipped: Int, duration: GameDuration, difficultyFilter: DifficultyFilter, category: QuizCategory?
    ) {
        self.uid = uid
        self.displayName = displayName
        self.photoURL = photoURL
        self.points = points
        self.correct = correct
        self.wrong = wrong
        self.skipped = skipped
        self.duration = duration
        self.difficultyFilter = difficultyFilter
        self.category = category
    }

    /// Whether the web's schema (and the security rules) would accept it.
    public var isValid: Bool {
        scoreFieldsAreValid(
            uid: uid, displayName: displayName, photoURL: photoURL, points: points, correct: correct,
            wrong: wrong, skipped: skipped, duration: duration
        )
    }
}

/// A ranking entry as stored in Firestore: the submission plus the server's timestamp.
public struct RankingEntry: Codable, Equatable, Sendable {
    public let uid: String
    public let displayName: String
    public let photoURL: String?
    public let points: Int
    public let correct: Int
    public let wrong: Int
    public let skipped: Int
    public let duration: GameDuration
    public let difficultyFilter: DifficultyFilter
    public let category: QuizCategory?
    public let createdAt: Date

    public init(
        uid: String, displayName: String, photoURL: String?, points: Int, correct: Int, wrong: Int,
        skipped: Int, duration: GameDuration, difficultyFilter: DifficultyFilter, category: QuizCategory?,
        createdAt: Date
    ) {
        self.uid = uid
        self.displayName = displayName
        self.photoURL = photoURL
        self.points = points
        self.correct = correct
        self.wrong = wrong
        self.skipped = skipped
        self.duration = duration
        self.difficultyFilter = difficultyFilter
        self.category = category
        self.createdAt = createdAt
    }

    public var isValid: Bool {
        scoreFieldsAreValid(
            uid: uid, displayName: displayName, photoURL: photoURL, points: points, correct: correct,
            wrong: wrong, skipped: skipped, duration: duration
        )
    }
}

private func scoreFieldsAreValid(
    uid: String, displayName: String, photoURL: String?, points: Int, correct: Int, wrong: Int,
    skipped: Int, duration: GameDuration
) -> Bool {
    let name = trimmedJS(displayName)
    guard (1...128).contains(uid.utf16.count),
          (1...60).contains(name.utf16.count),
          [points, correct, wrong, skipped].allSatisfy({ $0 >= 0 }),
          correct + wrong + skipped <= duration.rawValue,
          points <= correct * Rules.maxPointsPerCorrect
    else { return false }
    if let photoURL {
        return photoURL.utf16.count <= 500 && photoURL.hasPrefix("https://")
    }
    return true
}
