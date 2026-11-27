import Foundation
import Testing
@testable import Contrarreloj

private final class Recorder {
    var correct = 0, wrong = 0, finished = 0
    var skips: [Int] = []
    var shown: [[String]] = []
    var failShown = false
}

struct GameSessionTests {
    private func make(
        questions: [Question] = GameFixtures.bank(.medium, count: 6),
        setup: GameSetup = .arcade(),
        clock: ManualScheduler,
        recorder: Recorder
    ) async -> GameSession {
        let effects = GameEffects(
            onCorrect: { recorder.correct += 1 },
            onWrong: { recorder.wrong += 1 },
            onSkip: { recorder.skips.append($0) },
            onFinish: { _ in recorder.finished += 1 }
        )
        let session = GameSession(
            setup: setup, questions: questions, seen: [:], now: { clock.now }, sleep: { await clock.sleep($0) },
            rng: mulberry32(seed: 3), onShown: { ids in
                if recorder.failShown { throw FakeRemoteError.offline }
                recorder.shown.append(ids)
            }, effects: effects
        )
        session.start()
        await clock.settle()
        return session
    }

    private func right(_ s: GameSession) -> Int { s.question!.correctIndex }
    private func wrong(_ s: GameSession) -> Int { (s.question!.correctIndex + 1) % 4 }

    @Test func presentsTheFirstQuestionWhenStarted() async {
        let clock = ManualScheduler(), rec = Recorder()
        let s = await make(clock: clock, recorder: rec)
        #expect(s.snapshot.status == .question)
        #expect(s.question != nil)
        #expect(s.remainingMs == 60_000)
        #expect(s.report == nil)
    }

    @Test func feedbackLastsSixHundredMs() async {
        let clock = ManualScheduler(), rec = Recorder()
        let s = await make(clock: clock, recorder: rec)
        let first = s.question
        s.answer(right(s))
        #expect(s.feedback?.correct == true)
        #expect(s.feedback?.points == 7)
        #expect(rec.correct == 1)
        #expect(s.question == first)
        #expect(s.snapshot.score == 7)
        await clock.advance(599)
        #expect(s.feedback != nil)
        await clock.advance(1)
        #expect(s.feedback == nil)
        #expect(s.question != first)
    }

    @Test func wrongChoiceRevealsTheRightAnswer() async {
        let clock = ManualScheduler(), rec = Recorder()
        let s = await make(clock: clock, recorder: rec)
        let (r, w) = (right(s), wrong(s))
        s.answer(w)
        #expect(s.feedback == AnswerFeedback(chosenIndex: w, correctIndex: r, correct: false, points: 0, bonus: 0, penalty: 0))
        #expect(rec.wrong == 1)
    }

    @Test func ignoresAnswersAndSkipsDuringFeedback() async {
        let clock = ManualScheduler(), rec = Recorder()
        let s = await make(clock: clock, recorder: rec)
        s.answer(right(s))
        s.answer(wrong(s))
        s.skip()
        #expect(rec.correct == 1)
        #expect(rec.wrong == 0)
        #expect(rec.skips.isEmpty)
        #expect(s.snapshot.score == 7)
    }

    @Test func skipMovesOnWithoutAPause() async {
        let clock = ManualScheduler(), rec = Recorder()
        let s = await make(clock: clock, recorder: rec)
        let first = s.question
        s.skip()
        #expect(rec.skips == [0])
        #expect(s.feedback == nil)
        #expect(s.question != first)
        #expect(s.snapshot.freeSkipsLeft == 1)
    }

    @Test func timeKeepsRunningDuringFeedbackAndEndsTheGame() async {
        let clock = ManualScheduler(), rec = Recorder()
        let s = await make(clock: clock, recorder: rec)
        s.answer(right(s))
        await clock.advance(600)
        await clock.advance(10_000)
        #expect(s.remainingMs < 50_000)
        #expect(s.report == nil)
        await clock.advance(60_000)
        #expect(s.report?.finishReason == .time)
        #expect(s.report?.rows.count == 1)
        #expect(s.question == nil)
        #expect(rec.finished == 1)
        #expect(clock.pending == 0)
    }

    @Test func expiryDuringFeedbackFinishesAfterFeedback() async {
        let clock = ManualScheduler(), rec = Recorder()
        let s = await make(clock: clock, recorder: rec)
        await clock.advance(59_900)
        s.answer(right(s))
        await clock.advance(200)
        #expect(s.report == nil)
        #expect(s.feedback != nil)
        await clock.advance(500)
        #expect(s.report?.rows.count == 1)
        #expect(s.report?.points == 7)
        #expect(rec.finished == 1)
    }

    @Test func answerAfterTheTimeIsUpEndsAtOnce() async {
        let clock = ManualScheduler(), rec = Recorder()
        let s = await make(clock: clock, recorder: rec)
        clock.jump(70_000)
        s.answer(0)
        #expect(s.report?.rows.isEmpty == true)
        #expect(rec.correct == 0)
    }

    @Test func pauseFreezesTheClock() async {
        let clock = ManualScheduler(), rec = Recorder()
        let s = await make(clock: clock, recorder: rec)
        await clock.advance(5_000)
        s.pause()
        await clock.advance(30_000)
        #expect(s.remainingMs == 55_000)
        #expect(s.report == nil)
        s.resume()
        await clock.settle()
        await clock.advance(1_000)
        #expect(s.remainingMs == 54_000)
    }

    @Test func shownIdsReportedOnceAcrossFinishBackgroundAndLeave() async {
        let clock = ManualScheduler(), rec = Recorder()
        let s = await make(questions: GameFixtures.bank(.medium, count: 3), clock: clock, recorder: rec)
        s.appDidEnterBackground()
        s.appDidEnterBackground()
        #expect(rec.shown.count == 1)
        #expect(rec.shown[0].count == 1)
        s.skip()
        s.leave()
        #expect(rec.shown.count == 2)
        #expect(rec.shown[1].count == 1)
        s.leave()
        #expect(rec.shown.count == 2)
        #expect(Set(rec.shown.flatMap { $0 }).count == 2)
    }

    @Test func onShownFailureDoesNotBreakTheGame() async {
        let clock = ManualScheduler(), rec = Recorder()
        rec.failShown = true
        let s = await make(clock: clock, recorder: rec)
        s.appDidEnterBackground()
        s.answer(right(s))
        #expect(s.snapshot.score == 7)
    }

    @Test func effectsFireForCorrectWrongSkipAndFinish() async {
        let clock = ManualScheduler(), rec = Recorder()
        let s = await make(questions: GameFixtures.bank(.veryEasy, count: 6), clock: clock, recorder: rec)
        s.answer(right(s)); await clock.advance(600)
        s.answer(wrong(s)); await clock.advance(600)
        s.skip(); s.skip(); s.skip()
        #expect(rec.correct == 1)
        #expect(rec.wrong == 1)
        #expect(rec.skips == [0, 0, 1])
        s.answer(right(s)); await clock.advance(600)
        #expect(rec.finished == 1)
        #expect(s.report?.finishReason == .exhausted)
    }

    @Test func announcesResultAndThirtyAndTenSeconds() async {
        let clock = ManualScheduler(), rec = Recorder()
        let s = await make(questions: GameFixtures.bank(.veryEasy, count: 20), clock: clock, recorder: rec)
        s.answer(right(s))
        #expect(s.announcement == "Correcto. 3 puntos.")
        await clock.advance(600)
        let answer = s.question!.options[s.question!.correctIndex]
        s.answer(wrong(s))
        #expect(s.announcement == "Incorrecto. La respuesta correcta era: \(answer). Pierdes 2 puntos.")
        await clock.advance(600)
        s.skip(); s.skip(); s.skip()
        #expect(s.announcement == "Pasas la pregunta. Pierdes 1 punto.")
        await clock.advance(30_000)
        #expect(s.announcement == "Quedan 30 segundos")
        await clock.advance(20_000)
        #expect(s.announcement == "Quedan 10 segundos")
    }

    @Test func bonusIsAnnounced() async {
        let clock = ManualScheduler(), rec = Recorder()
        let s = await make(clock: clock, recorder: rec)
        for _ in 0..<2 { s.answer(right(s)); await clock.advance(600) }
        s.answer(right(s))
        #expect(s.announcement == "Correcto. 7 puntos y 2 de bonus por racha.")
    }

    @Test func resumingAfterExpiryFinishesOnNextTick() async {
        let clock = ManualScheduler(), rec = Recorder()
        let s = await make(clock: clock, recorder: rec)
        s.answer(right(s))
        await clock.advance(600)
        s.appDidEnterBackground()
        clock.jump(120_000) // suspended in the background, no timers ran
        await clock.advance(100)
        #expect(s.report?.finishReason == .time)
        #expect(rec.finished == 1)
        #expect(rec.shown.count == 1)
    }

    @Test func finishesAtOnceWhenNoQuestionMatches() async {
        let clock = ManualScheduler(), rec = Recorder()
        let s = await make(questions: GameFixtures.bank(.medium, count: 3),
                           setup: GameSetup(mode: .competitive, duration: .short, filter: .hard, category: nil),
                           clock: clock, recorder: rec)
        #expect(s.report?.finishReason == .exhausted)
        #expect(rec.finished == 1)
        #expect(clock.pending == 0)
    }
}
