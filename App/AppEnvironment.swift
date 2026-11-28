import FirebaseFirestore
import Foundation
import Observation

/// Everything the screens need, built once at launch: live (Firebase, system services) or for UI
/// tests (fakes, no network). Views read it from the SwiftUI environment.
@Observable
final class AppEnvironment {
    let questionBank: QuestionBank
    let ranking: RankingService?
    let rankingStore: (any RankingStore)?
    let auth: any AuthService
    let analytics: any AnalyticsService
    let seen: SeenMemory
    let sound: SoundPreference
    let player: any SoundPlayer
    let consent: ConsentStore
    let hiddenPlayers: HiddenPlayers
    let mail: any MailComposer
    let connectivity: Connectivity
    let firebaseAvailable: Bool
    let options: LaunchOptions

    @ObservationIgnored private let clockStart = ContinuousClock.now
    @ObservationIgnored private var gamesStarted: UInt32 = 0
    @ObservationIgnored private(set) lazy var play = PlayCoordinator(env: self)

    init(
        questionBank: QuestionBank, rankingStore: (any RankingStore)?, auth: any AuthService,
        analytics: any AnalyticsService, defaults: UserDefaults, player: (SoundPreference) -> any SoundPlayer,
        mail: any MailComposer, connectivity: Connectivity, firebaseAvailable: Bool, options: LaunchOptions
    ) {
        self.questionBank = questionBank
        self.rankingStore = rankingStore
        ranking = rankingStore.map { RankingService(store: $0) }
        self.auth = auth
        self.analytics = analytics
        seen = SeenMemory(defaults: defaults)
        let sound = SoundPreference(defaults: defaults)
        self.sound = sound
        self.player = player(sound)
        consent = ConsentStore(defaults: defaults)
        hiddenPlayers = HiddenPlayers(defaults: defaults)
        self.mail = mail
        self.connectivity = connectivity
        self.firebaseAvailable = firebaseAvailable
        self.options = options
        analytics.apply(consent.status)
    }

    /// Milliseconds on a monotonic clock that keeps counting while the app is suspended, so the
    /// game time is real time (like the web's).
    func nowMs() -> Double {
        let elapsed = clockStart.duration(to: .now).components
        return Double(elapsed.seconds) * 1000 + Double(elapsed.attoseconds) / 1e15
    }

    /// A random source for a new game: seeded and reproducible in UI tests.
    func makeRng() -> Rng {
        gamesStarted &+= 1
        if let seed = options.seed { return mulberry32(seed: seed &+ gamesStarted) }
        return { Double.random(in: 0..<1) }
    }

    // MARK: Factories

    static func live(_ options: LaunchOptions = .current) -> AppEnvironment {
        let configured = !options.noFirebase && FirebaseBootstrap.configureIfPossible(useEmulators: options.useEmulators)
        let db: Firestore? = configured ? Firestore.firestore() : nil
        return AppEnvironment(
            questionBank: QuestionBank(
                remote: db.map { FirestoreQuestionSource(db: $0) }, cache: QuestionCacheFile.standard,
                bundled: { BundledQuestions.all }
            ),
            rankingStore: db.map { FirestoreRankingStore(db: $0) },
            auth: configured ? FirebaseAuthService() : UnavailableAuthService(),
            analytics: FirebaseAnalyticsService(),
            defaults: .standard,
            player: { SynthPlayer(preference: $0) },
            mail: SystemMailComposer(),
            connectivity: Connectivity(),
            firebaseAvailable: configured,
            options: options
        )
    }

    static func uiTesting(_ options: LaunchOptions = .current) -> AppEnvironment {
        let suite = "com.contrarrelojquiz.app.uitests"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        let consent = ConsentStore(defaults: defaults)
        switch options.consent ?? "rejected" {
        case "accepted": consent.decide(accepted: true)
        case "rejected": consent.decide(accepted: false)
        default: break
        }

        let failing = options.bank == "failing"
        let tiny = UITestBank.tiny
        let remote: (any RemoteQuestionSource)? = switch options.bank {
        case "tiny": FakeQuestionSource(count: .success(tiny.count), fetch: .success(RemoteBank(questions: tiny, documentCount: tiny.count)))
        case "failing": FakeQuestionSource(count: .failure(.offline), fetch: .failure(.offline))
        case "slow": FakeQuestionSource(count: .delayed(tiny.count, seconds: 3),
                                        fetch: .delayed(RemoteBank(questions: tiny, documentCount: tiny.count), seconds: 3))
        default: nil
        }
        let available = !options.noFirebase
        let rankingStore: (any RankingStore)? = available ? UITestBank.ranking(options.rankingFake) : nil
        let auth: any AuthService
        if available {
            let fake = FakeAuthService(user: options.fakeUser.map { AuthUser(uid: "me", displayName: "Yo", photoURL: nil, provider: $0) })
            // Longer than any test step, even on a slow CI runner: the sign-in stays under way.
            if options.slowSignIn { fake.signInDelay = .seconds(60) }
            auth = fake
        } else {
            auth = UnavailableAuthService()
        }
        return AppEnvironment(
            questionBank: QuestionBank(remote: remote, cache: InMemoryQuestionCache(nil),
                                       bundled: { failing ? [] : BundledQuestions.all }),
            rankingStore: rankingStore,
            auth: auth,
            analytics: FakeAnalytics(),
            defaults: defaults,
            player: { SynthPlayer(preference: $0, output: SilentOutput()) },
            mail: FakeMailComposer(),
            connectivity: Connectivity(monitoring: false),
            firebaseAvailable: available,
            options: options
        )
    }
}

/// When Firebase is not configured: no sign-in, so no competitive mode or ranking.
@Observable
final class UnavailableAuthService: AuthService {
    let user: AuthUser? = nil
    let isAvailable = false
    func signIn(with provider: AuthProvider) async throws { throw AuthFailure.notConfigured }
    func signOut() throws {}
    func reauthenticate() async throws -> ReauthProof { throw AuthFailure.notConfigured }
    func revokeAppleToken(_ proof: ReauthProof) async throws {}
    func disconnectGoogle() async {}
    func deleteUser() async throws { throw AuthFailure.notConfigured }
}

/// No sound in UI tests.
final class SilentOutput: SoundOutput {
    func prepare(sampleRate: Double) {}
    func play(_ sound: SoundName, samples: [Float], sampleRate: Double) {}
}
