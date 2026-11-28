import Testing
@testable import Contrarreloj

/// iOS 26 SwiftUI compares `.animation(value:)` / `onChange` values and measures some layouts on
/// its `AsyncRenderer` thread. Values it compares must have nonisolated `Equatable`, or the
/// main-actor check traps there. These tests only compile while that stays true.
struct OffMainValueTests {
    @Test func answerFeedbackComparesOffMain() async {
        let a = AnswerFeedback(chosenIndex: 1, correctIndex: 1, correct: true, points: 7, bonus: 0, penalty: 0)
        let b = a
        #expect(await Task.detached { a == b }.value)
    }

    @Test func streakBannerComparesOffMain() async {
        let a: GameFx.Banner? = GameFx.Banner(id: 1, streak: 3, bonus: 2, big: true)
        #expect(await Task.detached { a == GameFx.Banner(id: 1, streak: 3, bonus: 2, big: true) }.value)
        #expect(await Task.detached { a != nil }.value)
    }

    @Test func optionStateComparesOffMain() async {
        let state = OptionState.revealed
        #expect(await Task.detached { state == .revealed }.value)
    }
}
