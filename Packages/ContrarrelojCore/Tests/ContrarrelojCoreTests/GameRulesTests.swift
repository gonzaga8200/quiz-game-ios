import Testing
@testable import ContrarrelojCore

/// A game on a manual clock over `count` questions of one difficulty.
private final class Harness {
    let game: Game
    private let box = Box()
    private final class Box { var now = 0.0 }

    init(count: Int = 20, difficulty: Difficulty = .veryEasy, duration: GameDuration = .short) {
        let questions = (0..<count).map { i in
            Question(
                id: "pregunta-\(i)", text: "¿Pregunta número \(i) de prueba?", options: ["Uno", "Dos", "Tres", "Cuatro"],
                correctIndex: i % 4, category: QuizCategory.allCases[i % QuizCategory.allCases.count], difficulty: difficulty,
                explanation: "Explicación de la pregunta \(i).", source: nil, createdAt: "2026-11-16T00:00:00.000Z",
                status: .active
            )
        }
        let box = self.box
        game = Game(GameConfig(questions: questions, filter: .random, duration: duration, category: nil, seen: nil,
                               rng: mulberry32(seed: 9), now: { box.now }))
    }

    func advance(_ ms: Double) { box.now += ms }

    var correctIndex: Int { game.snapshot().current!.correctIndex }

    @discardableResult func right() -> Outcome {
        let outcome = game.answer(correctIndex)
        _ = game.next()
        return outcome
    }

    @discardableResult func wrong() -> Outcome {
        let outcome = game.answer((correctIndex + 1) % 4)
        _ = game.next()
        return outcome
    }

    @discardableResult func skip() -> Outcome {
        let outcome = game.skip()
        _ = game.next()
        return outcome
    }
}

private func penalty(_ outcome: Outcome) -> Int? {
    switch outcome {
    case .answered(_, _, _, _, _, let penalty, _), .skipped(_, let penalty, _): penalty
    default: nil
    }
}

private func bonus(_ outcome: Outcome) -> Int? {
    if case .answered(_, _, _, _, let bonus, _, _) = outcome { return bonus }
    return nil
}

@Test func scoreNeverGoesBelowZero() {
    let h = Harness()
    h.game.start()
    #expect(penalty(h.wrong()) == 0)
    #expect(h.game.snapshot().score == 0)
}

@Test func penaltyRecordsWhatWasActuallyDeducted() {
    let h = Harness()
    h.game.start()
    h.right() // +3
    #expect(penalty(h.wrong()) == 2) // 3 -> 1
    #expect(penalty(h.wrong()) == 1) // only 1 left to take
    #expect(h.game.snapshot().score == 0)
    #expect(h.game.results().map(\.penalty) == [0, 2, 1])
}

@Test func twoFreeSkipsThenOnePoint() {
    let h = Harness()
    h.game.start()
    h.right() // 3 points
    #expect(h.skip() == .skipped(free: true, penalty: 0, freeSkipsLeft: 1))
    #expect(h.skip() == .skipped(free: true, penalty: 0, freeSkipsLeft: 0))
    #expect(h.game.snapshot().skipCost == 1)
    #expect(h.skip() == .skipped(free: false, penalty: 1, freeSkipsLeft: 0))
    #expect(h.game.snapshot().score == 2)
}

@Test func skipKeepsTheStreak() {
    let h = Harness()
    h.game.start()
    h.right()
    h.right()
    h.skip()
    #expect(bonus(h.right()) == 2)
    #expect(h.game.snapshot().streak == 3)
}

@Test func eachComboBonusOncePerStreak() {
    let h = Harness(count: 30)
    h.game.start()
    let bonuses = (1...11).map { _ in bonus(h.right()) ?? -1 }
    #expect(bonuses == [0, 0, 2, 0, 4, 0, 0, 0, 0, 8, 0])
    h.wrong()
    #expect((1...3).map { _ in bonus(h.right()) ?? -1 } == [0, 0, 2])
    #expect(h.game.snapshot().bestStreak == 11)
}

@Test func openQuestionAtZeroIsDiscarded() {
    let h = Harness()
    h.game.start()
    h.advance(60_000)
    #expect(h.game.answer(0) == .expired)
    #expect(h.game.results().isEmpty)
    #expect(h.game.snapshot().status == .finished)
    #expect(h.game.snapshot().finishReason == .time)
    #expect(h.game.report()?.rows.isEmpty == true)
}

@Test func emptyBankFinishesExhausted() {
    let h = Harness(count: 0)
    h.game.start()
    #expect(h.game.snapshot().status == .finished)
    #expect(h.game.report()?.finishReason == .exhausted)
}

@Test func doubleAnswerIsIgnored() {
    let h = Harness()
    h.game.start()
    #expect(h.game.answer(9) == .ignored)
    let index = h.correctIndex
    if case .answered = h.game.answer(index) {} else { Issue.record("first answer should count") }
    #expect(h.game.answer(index) == .ignored)
    #expect(h.game.skip() == .ignored)
    #expect(h.game.results().count == 1)
}

@Test func reportIsNilWhileRunningAndTimeKeepsRunningDuringFeedback() {
    let h = Harness()
    h.game.start()
    #expect(h.game.report() == nil)
    _ = h.game.answer(h.correctIndex)
    h.advance(60_000)
    #expect(h.game.next() == .finished)
    #expect(h.game.report()?.finishReason == .time)
    #expect(h.game.report()?.correct == 1)
}
