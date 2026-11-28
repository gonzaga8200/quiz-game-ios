import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import Foundation
import Testing
@testable import Contrarreloj

/// Every emulator test, one at a time: they share the two emulators and empty them before each test.
@Suite(.serialized) struct EmulatorTests {}

enum EmulatorError: Error, CustomStringConvertible {
    case notRunning(String)

    var description: String {
        switch self {
        case .notRunning(let detail):
            "Firebase emulators not reachable (\(detail)). Run scripts/test-integration.sh, or start them with scripts/emulators.sh."
        }
    }
}

/// The emulators started by scripts/emulators.sh (the web's ports), reached through a Firebase app
/// of their own with a demo project ID, so nothing here can touch the real project.
enum Emulators {
    static let projectID = "demo-contrarreloj"
    static let host = FirebaseBootstrap.emulatorHost

    static let app: FirebaseApp = {
        let options = FirebaseOptions(googleAppID: "1:1234567890:ios:0123456789abcdef", gcmSenderID: "1234567890")
        options.projectID = projectID
        options.apiKey = "AIza" + String(repeating: "0", count: 35)
        FirebaseApp.configure(name: "emulators", options: options)
        let app = FirebaseApp.app(name: "emulators")!
        let settings = FirestoreSettings()
        settings.host = "\(host):\(FirebaseBootstrap.firestoreEmulatorPort)"
        settings.isSSLEnabled = false
        settings.cacheSettings = MemoryCacheSettings()
        Firestore.firestore(app: app).settings = settings
        Auth.auth(app: app).useEmulator(withHost: host, port: FirebaseBootstrap.authEmulatorPort)
        return app
    }()

    static var db: Firestore { Firestore.firestore(app: app) }
    static var auth: Auth { Auth.auth(app: app) }
    static var store: FirestoreRankingStore { FirestoreRankingStore(db: db) }

    /// Signs out and empties both emulators.
    static func reset() async throws {
        try? auth.signOut()
        try await clear("http://\(host):\(FirebaseBootstrap.firestoreEmulatorPort)/emulator/v1/projects/\(projectID)/databases/(default)/documents")
        try await clear("http://\(host):\(FirebaseBootstrap.authEmulatorPort)/emulator/v1/projects/\(projectID)/accounts")
    }

    private static func clear(_ address: String) async throws {
        var request = URLRequest(url: URL(string: address)!)
        request.httpMethod = "DELETE"
        let status: Int
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            status = (response as? HTTPURLResponse)?.statusCode ?? 0
        } catch {
            throw EmulatorError.notRunning(error.localizedDescription)
        }
        guard status == 200 else { throw EmulatorError.notRunning("HTTP \(status) from \(address)") }
    }

    /// An unsigned Google ID token written as JSON, which only the Auth emulator accepts. The same
    /// `sub` always signs in to the same account.
    static func googleCredential(sub: String, name: String) -> AuthCredential {
        let token = #"{"sub":"\#(sub)","email":"\#(sub)@example.com","email_verified":true,"name":"\#(name)"}"#
        return GoogleAuthProvider.credential(withIDToken: token, accessToken: "")
    }

    /// The app's own sign-in service, on the emulator, signing in as `sub`.
    static func authService(sub: String, name: String) -> FirebaseAuthService {
        FirebaseAuthService(auth: auth, googleCredential: { googleCredential(sub: sub, name: name) })
    }

    static func player(_ uid: String, _ name: String) -> RankingPlayer {
        RankingPlayer(uid: uid, displayName: name, photoURL: "https://example.com/\(uid).png")
    }

    /// Another player's best on a board, written by that player (the rules let no one else).
    static func seed(_ sub: String, name: String, points: Int, like model: GameReport? = nil) async throws {
        let service = authService(sub: sub, name: name)
        try await service.signIn(with: .google)
        let uid = try #require(service.user?.uid)
        let base = model ?? report(points: points)
        let game = report(points: points, correct: base.correct, wrong: base.wrong, skipped: base.skipped,
                          duration: base.duration, filter: base.filter, category: base.category)
        _ = try await RankingService(store: store).submit(player: player(uid, name), report: game)
        try service.signOut()
    }

    /// A finished competitive game with these numbers (RankingService builds the entry from it).
    static func report(points: Int, correct: Int = 6, wrong: Int = 1, skipped: Int = 2,
                       duration: GameDuration = .short, filter: DifficultyFilter = .medium,
                       category: QuizCategory? = .science) -> GameReport {
        GameReport(
            points: points, correct: correct, wrong: wrong, skipped: skipped, bestStreak: correct,
            breakdown: ReportBreakdown(correctPoints: points, comboBonuses: [], comboBonusTotal: 0, wrongPenalty: 0,
                                       skipPenalty: 0, penaltyTotal: 0),
            rows: [], finishReason: .time, duration: duration, filter: filter, category: category,
            celebration: celebrationFor(points: points, duration: duration)
        )
    }

    /// The stored document, read from the server (nil when there is none).
    static func entry(board: String, uid: String) async throws -> [String: Any]? {
        try await db.collection("rankings").document(board).collection("entries").document(uid)
            .getDocument(source: .server).data()
    }

    static func points(board: String, uid: String) async throws -> Int? {
        try await entry(board: board, uid: uid)?["points"] as? Int
    }
}

/// True for a Firestore "permission denied" (a write the security rules rejected).
func isPermissionDenied(_ error: any Error) -> Bool {
    let error = error as NSError
    return error.domain == FirestoreErrorDomain && error.code == FirestoreErrorCode.permissionDenied.rawValue
}
