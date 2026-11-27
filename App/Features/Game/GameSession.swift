import Foundation
import Observation

/// What the screen shows for the ~600 ms after an answer.
struct AnswerFeedback: Equatable {
    let chosenIndex: Int
    let correctIndex: Int
    let correct: Bool
    let points: Int
    let bonus: Int
    let penalty: Int
}

/// Sounds, haptics and the end of the game, wired by the screen.
struct GameEffects {
    var onCorrect: () -> Void = {}
    var onWrong: () -> Void = {}
    /// Points the skip cost (0 while free skips remain).
    var onSkip: (Int) -> Void = { _ in }
    var onFinish: (GameReport) -> Void = { _ in }
}

/// The game's clock: a pause freezes it and resuming subtracts the paused time, so reporting a
/// question never costs the player seconds.
private final class PausableClock {
    private let read: () -> Double
    private var pausedTotal = 0.0
    private(set) var pausedAt: Double?

    init(read: @escaping () -> Double) {
        self.read = read
    }

    func now() -> Double { (pausedAt ?? read()) - pausedTotal }

    func pause() { pausedAt = read() }

    func resume() {
        guard let pausedAt else { return }
        pausedTotal += read() - pausedAt
        self.pausedAt = nil
    }
}

/// Connects the framework-agnostic `Game` to SwiftUI: observable state, the countdown and the
/// short feedback pause after each answer. Port of the web's `useGameSession`; every rule stays in
/// ContrarrelojCore.
@Observable
final class GameSession {
    let setup: GameSetup
    private(set) var snapshot: GameSnapshot
    /// The question on screen; it stays during the feedback, when the core has none.
    private(set) var question: PlayableQuestion?
    private(set) var remainingMs: Double
    private(set) var feedback: AnswerFeedback?
    private(set) var report: GameReport?
    /// What VoiceOver should say: the result of an answer, the cost of a skip, the time left.
    private(set) var announcement = ""
    private(set) var isPaused = false

    @ObservationIgnored private let game: Game
    @ObservationIgnored private let clock: PausableClock
    @ObservationIgnored private let sleep: (Duration) async -> Void
    @ObservationIgnored private let onShown: ([String]) throws -> Void
    @ObservationIgnored private let effects: GameEffects
    @ObservationIgnored private let feedbackDuration: Duration
    @ObservationIgnored private let tickInterval: Duration
    @ObservationIgnored private var tickTask: Task<Void, Never>?
    @ObservationIgnored private var feedbackTask: Task<Void, Never>?
    @ObservationIgnored private var reportedCount = 0
    @ObservationIgnored private var started = false

    init(
        setup: GameSetup,
        questions: [Question],
        seen: [String: Int],
        now: @escaping () -> Double,
        sleep: @escaping (Duration) async -> Void,
        rng: @escaping Rng,
        onShown: @escaping ([String]) throws -> Void,
        effects: GameEffects,
        feedback: Duration = .milliseconds(600),
        tick: Duration = .milliseconds(100)
    ) {
        self.setup = setup
        let clock = PausableClock(read: now)
        self.clock = clock
        self.sleep = sleep
        self.onShown = onShown
        self.effects = effects
        feedbackDuration = feedback
        tickInterval = tick
        let game = Game(GameConfig(
            questions: questions, filter: setup.filter, duration: setup.duration, category: setup.category,
            seen: seen.isEmpty ? nil : seen, rng: rng,
            now: { MainActor.assumeIsolated { clock.now() } }
        ))
        self.game = game
        let initial = game.snapshot()
        snapshot = initial
        remainingMs = initial.remainingMs
    }

    // MARK: Player actions

    func start() {
        guard !started else { return }
        started = true
        game.start()
        refresh()
        if snapshot.status == .finished {
            finalize()
            return
        }
        startTicking()
    }

    func answer(_ index: Int) {
        switch game.answer(index) {
        case .expired:
            finalize()
        case let .answered(result, chosenIndex, correctIndex, points, bonus, penalty, _):
            let correct = result == .correct
            feedback = AnswerFeedback(chosenIndex: chosenIndex, correctIndex: correctIndex, correct: correct,
                                      points: points, bonus: bonus, penalty: penalty)
            let rightAnswer = question.map { $0.options[correctIndex] } ?? ""
            refresh()
            if correct {
                effects.onCorrect()
                let bonusText = bonus > 0 ? String(localized: " y \(bonus) de bonus por racha") : ""
                announcement = String(localized: "Correcto. \(points) puntos\(bonusText).")
            } else {
                effects.onWrong()
                let lost = penalty > 0 ? String(localized: " Pierdes \(pointsText(penalty)).") : ""
                announcement = String(localized: "Incorrecto. La respuesta correcta era: \(rightAnswer).\(lost)")
            }
            let sleep = sleep
            let wait = feedbackDuration
            feedbackTask = Task { [weak self] in
                await sleep(wait)
                guard !Task.isCancelled, let self else { return }
                self.feedback = nil
                self.advance()
            }
        default:
            return
        }
    }

    func skip() {
        switch game.skip() {
        case .expired:
            finalize()
        case let .skipped(_, penalty, _):
            effects.onSkip(penalty)
            announcement = penalty > 0 ? String(localized: "Pasas la pregunta. Pierdes \(pointsText(penalty)).") : ""
            advance()
        default:
            return
        }
    }

    /// Stops the clock, e.g. while a question report is open. `resume` carries on.
    func pause() {
        guard started, clock.pausedAt == nil, report == nil else { return }
        clock.pause()
        isPaused = true
        tickTask?.cancel()
        tickTask = nil
    }

    func resume() {
        guard clock.pausedAt != nil else { return }
        clock.resume()
        isPaused = false
        if started, report == nil, tickTask == nil { startTicking() }
    }

    /// The app went to the background: save what was shown (the game itself keeps running, like
    /// the web's, because the clock is real time).
    func appDidEnterBackground() {
        reportShown()
    }

    /// The player left the game: stop everything and save what was shown.
    func leave() {
        stopTimers()
        reportShown()
    }

    // MARK: Internals

    private func startTicking() {
        let sleep = sleep
        let interval = tickInterval
        tickTask = Task { [weak self] in
            while !Task.isCancelled {
                await sleep(interval)
                guard !Task.isCancelled, let self else { return }
                self.onTick()
            }
        }
    }

    private func onTick() {
        game.tick()
        let before = remainingMs
        remainingMs = game.remainingMs()
        for mark in [30.0, 10.0] where before > mark * 1000 && remainingMs <= mark * 1000 {
            announcement = String(localized: "Quedan \(Int(mark)) segundos")
        }
        // If time ran out during the feedback, let it finish: the feedback task ends the game.
        if game.snapshot().status == .finished && feedback == nil { finalize() }
    }

    private func advance() {
        game.next()
        refresh()
        if snapshot.status == .finished { finalize() }
    }

    private func refresh() {
        snapshot = game.snapshot()
        remainingMs = snapshot.remainingMs
        if let current = snapshot.current { question = current }
    }

    private func stopTimers() {
        tickTask?.cancel()
        feedbackTask?.cancel()
        tickTask = nil
        feedbackTask = nil
    }

    /// Hands `onShown` the questions presented since the last call; never the same one twice, and
    /// a failing save never breaks the game.
    private func reportShown() {
        let ids = Array(game.shownIds().dropFirst(reportedCount))
        guard !ids.isEmpty else { return }
        reportedCount += ids.count
        try? onShown(ids)
    }

    /// Ends the session once: freezes the state and builds the report.
    private func finalize() {
        guard report == nil else { return }
        stopTimers()
        reportShown()
        feedback = nil
        refresh()
        question = nil
        if let finished = game.report() {
            report = finished
            effects.onFinish(finished)
        }
    }
}
