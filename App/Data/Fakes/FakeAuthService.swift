import Foundation
import Observation

/// An ordered record of calls, shared between fakes to check the order of operations.
nonisolated final class EventLog: @unchecked Sendable {
    private let lock = NSLock()
    private var _events: [String] = []
    var events: [String] { lock.withLock { _events } }
    func append(_ event: String) { lock.withLock { _events.append(event) } }
}

/// Sign-in for previews, tests and UI tests: no network, configurable failures.
@Observable
final class FakeAuthService: AuthService {
    var user: AuthUser?
    var isAvailable = true
    @ObservationIgnored var reauthFails = false
    @ObservationIgnored var revokeFails = false
    @ObservationIgnored var signInFails = false
    @ObservationIgnored let log: EventLog

    init(log: EventLog = EventLog(), user: AuthUser? = nil) {
        self.log = log
        self.user = user
    }

    func signIn(with provider: AuthProvider) async throws {
        log.append("signIn:\(provider.rawValue)")
        if signInFails { throw URLError(.notConnectedToInternet) }
        user = AuthUser(uid: "fake-\(provider.rawValue)", displayName: "Jugadora de prueba", photoURL: nil, provider: provider)
    }

    func signOut() throws {
        log.append("signOut")
        user = nil
    }

    func reauthenticate() async throws -> ReauthProof {
        log.append("reauthenticate")
        if reauthFails { throw FakeRemoteError.offline }
        return ReauthProof(provider: user?.provider ?? .google, appleAuthorizationCode: user?.provider == .apple ? "code" : nil)
    }

    func revokeAppleToken(_ proof: ReauthProof) async throws {
        log.append("revokeAppleToken")
        if revokeFails { throw FakeRemoteError.offline }
    }

    func disconnectGoogle() async {
        log.append("disconnectGoogle")
    }

    func deleteUser() async throws {
        log.append("deleteUser")
    }
}
