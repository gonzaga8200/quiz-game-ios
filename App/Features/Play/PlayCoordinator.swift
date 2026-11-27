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

    init(env: AppEnvironment) {
        self.env = env
    }

    func play(_ setup: GameSetup) {
        self.setup = setup
        phase = .loading
        Task { await load() }
    }

    func retry() {
        phase = .loading
        Task { await load() }
    }

    /// "Jugar de nuevo": a fresh game with the questions already loaded.
    func playAgain() {
        startGame()
    }

    /// Leaves the game or the report and goes back to the tabs.
    func close() {
        if case .playing(let session) = phase { session.leave() }
        setup = nil
        phase = .loading
    }

    func trackShare(_ method: String) {
        guard let setup else { return }
        env.analytics.track(.share(method: method, mode: setup.mode))
    }

    func retrySubmission() {}

    func sceneDidEnterBackground() {
        if case .playing(let session) = phase { session.appDidEnterBackground() }
    }

    private func load() async {
        let loaded = await env.questionBank.load().questions
        guard setup != nil else { return }
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
        session.start()
    }

    private func finish(_ report: GameReport) {
        guard let setup else { return }
        env.analytics.track(.gameEnd(setup, report))
        phase = .finished(report)
    }
}
