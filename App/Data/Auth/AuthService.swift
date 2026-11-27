import Foundation
import Observation

nonisolated enum AuthProvider: String, Sendable {
    case google, apple
}

nonisolated struct AuthUser: Equatable, Sendable {
    let uid: String
    let displayName: String
    let photoURL: URL?
    let provider: AuthProvider
}

/// Proof of a fresh sign-in, required by Firebase before deleting an account. For Apple it carries
/// the authorization code that revokes the app's access to the Apple ID.
nonisolated struct ReauthProof: Sendable {
    let provider: AuthProvider
    let appleAuthorizationCode: String?
}

/// Sign-in with Apple or Google through Firebase Auth (the real one is FirebaseAuthService).
protocol AuthService: AnyObject, Observable {
    var user: AuthUser? { get }
    /// False when Firebase is not configured: competitive mode and the ranking stay hidden.
    var isAvailable: Bool { get }
    func signIn(with provider: AuthProvider) async throws
    func signOut() throws
    func reauthenticate() async throws -> ReauthProof
    func revokeAppleToken(_ proof: ReauthProof) async throws
    func disconnectGoogle() async
    func deleteUser() async throws
}

/// Display name for an Apple ID, which Apple only shares on the first sign-in.
nonisolated func appleDisplayName(from components: PersonNameComponents?) -> String? {
    let parts = [components?.givenName, components?.familyName]
        .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
    return parts.isEmpty ? nil : parts.joined(separator: " ")
}
