import Foundation
import Observation

/// Runs a game from the moment the player taps "Jugar" to the report: loads the questions, starts
/// the session, and hands over to the report (the web's `/jugar` page).
@Observable
final class PlayCoordinator {
    enum Phase {
        case loading
        case failed
        case playing(GameSession)
        case finished(GameReport)
    }

    private(set) var setup: GameSetup?
    private(set) var phase: Phase = .loading
    /// Saving to the ranking (competitive games only; nil in arcade).
    private(set) var submission: SubmissionState?
    var isPresented: Bool { setup != nil }

    @ObservationIgnored private unowned let env: AppEnvironment
    @ObservationIgnored private var questions: [Question] = []
    @ObservationIgnored private var lastReport: GameReport?
    /// Changes with every game, retry and close: a load or a save that ends after it belongs to a
    /// game the player has left, and is ignored.
    @ObservationIgnored private var generation = 0

    init(env: AppEnvironment) {
        self.env = env
    }

    func play(_ setup: GameSetup) {
        generation += 1
        self.setup = setup
        submission = nil
        lastReport = nil
        phase = .loading
        let game = generation
        Task { await load(for: game) }
    }

    func retry() {
        generation += 1
        phase = .loading
        let game = generation
        Task { await load(for: game) }
    }

    /// "Jugar de nuevo": a fresh game with the questions already loaded.
    func playAgain() {
        generation += 1
        submission = nil
        lastReport = nil
        startGame()
    }

    /// Leaves the game or the report and goes back to the tabs.
    func close() {
        generation += 1
        if case .playing(let session) = phase { session.leave() }
        setup = nil
        submission = nil
        lastReport = nil
        phase = .loading
    }

    func trackShare(_ method: String) {
        guard let setup else { return }
        env.analytics.track(.share(method: method, mode: setup.mode))
    }

    func retrySubmission() {
        if let lastReport { submit(lastReport) }
    }

    /// Competitive games are saved to the ranking as soon as they end (like the web's /jugar).
    private func submit(_ report: GameReport) {
        guard let ranking = env.ranking, let user = env.auth.user else {
            submission = .error
            return
        }
        submission = .saving
        let player = RankingPlayer(uid: user.uid, displayName: user.displayName, photoURL: user.photoURL?.absoluteString)
        let game = generation
        Task {
            let state: SubmissionState
            do {
                state = .done(try await ranking.submit(player: player, report: report))
            } catch RankingError.invalidScore {
                state = .rejected
            } catch {
                state = .error
            }
            guard game == generation else { return } // the player has moved on to another game
            submission = state
        }
    }

    func sceneDidEnterBackground() {
        if case .playing(let session) = phase { session.appDidEnterBackground() }
    }

    private func load(for game: Int) async {
        let loaded = await env.questionBank.load().questions
        guard game == generation, setup != nil else { return } // closed, retried or replaced meanwhile
        guard !loaded.isEmpty else {
            phase = .failed
            return
        }
        questions = loaded
        startGame()
    }

    private func startGame() {
        guard let setup else { return }
        let bankIds = Set(questions.map(\.id))
        let seen = env.seen
        let player = env.player
        let session = GameSession(
            setup: setup, questions: questions, seen: seen.read(),
            now: { [env] in env.nowMs() },
            sleep: { try? await Task.sleep(for: $0) },
            rng: env.makeRng(),
            onShown: { ids in seen.record(shown: ids, bankIds: bankIds) },
            effects: GameEffects(
                onCorrect: { player.play(.correct) },
                onWrong: {
                    player.play(.wrong)
                    Haptics.wrong()
                },
                onSkip: { _ in player.play(.skip) },
                onFinish: { [weak self] report in
                    player.play(.end)
                    self?.finish(report)
                }
            ),
            feedback: .milliseconds(env.options.feedbackMs ?? 600)
        )
        phase = .playing(session)
        env.analytics.track(.gameStart(setup))
        player.prepare() // the audio starts now, not at the first answer
        session.start()
    }

    /// The session calls this when the game ends (internal for tests).
    func finish(_ report: GameReport) {
        guard let setup else { return }
        env.analytics.track(.gameEnd(setup, report))
        phase = .finished(report)
        if setup.mode == .competitive {
            lastReport = report
            submit(report)
        }
    }
}
