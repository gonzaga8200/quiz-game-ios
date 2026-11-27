import Testing
@testable import ContrarrelojCore

private func submission(
    displayName: String = "Ana",
    photoURL: String? = "https://lh3.googleusercontent.com/a/foto",
    points: Int = 100, correct: Int = 20, wrong: Int = 5, skipped: Int = 2,
    duration: GameDuration = .short
) -> ScoreSubmission {
    ScoreSubmission(uid: "ana", displayName: displayName, photoURL: photoURL, points: points, correct: correct,
                    wrong: wrong, skipped: skipped, duration: duration, difficultyFilter: .medium, category: nil)
}

@Test(arguments: [
    submission(displayName: String(repeating: "x", count: 61)),
    submission(displayName: "   "),
    submission(photoURL: "http://example.org/a.png"),
    submission(photoURL: "javascript:alert(1)"),
    submission(photoURL: "https://example.org/" + String(repeating: "a", count: 490)),
    submission(points: -1),
    submission(correct: 50, wrong: 10, skipped: 1, duration: .short),
    submission(points: 20 * 17 + 1, correct: 20),
])
func submissionRangesRejectInvalid(_ invalid: ScoreSubmission) {
    #expect(!invalid.isValid)
}

@Test(arguments: [
    submission(),
    submission(displayName: String(repeating: "x", count: 60)),
    submission(photoURL: nil),
    submission(points: 0, correct: 0, wrong: 0, skipped: 0),
    submission(points: 40 * 17, correct: 40, wrong: 10, skipped: 10, duration: .short),
    submission(correct: 100, wrong: 10, skipped: 10, duration: .long),
])
func submissionRangesAcceptBoundaries(_ valid: ScoreSubmission) {
    #expect(valid.isValid)
}
