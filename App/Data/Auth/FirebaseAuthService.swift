import FirebaseAuth
import FirebaseCore
import Foundation
import GoogleSignIn
import Observation

/// Sign-in with Google (GoogleSignIn) or Apple (AuthenticationServices), both through Firebase
/// Auth, so a player has the same uid on every device where they use the same provider.
@Observable
final class FirebaseAuthService: AuthService {
    private(set) var user: AuthUser?
    let isAvailable = true

    @ObservationIgnored private var listener: AuthStateDidChangeListenerHandle?
    @ObservationIgnored private let apple = AppleSignInCoordinator()
    @ObservationIgnored private let auth: Auth
    @ObservationIgnored private let googleCredentialSource: (@MainActor () async throws -> AuthCredential)?

    /// The integration tests pass the Auth emulator's instance and a fake Google credential; the
    /// app uses the defaults (the configured Firebase app and the Google sign-in sheet).
    init(auth: Auth = Auth.auth(), googleCredential: (@MainActor () async throws -> AuthCredential)? = nil) {
        self.auth = auth
        googleCredentialSource = googleCredential
        user = auth.currentUser.map(Self.authUser)
        listener = auth.addStateDidChangeListener { [weak self] _, user in
            self?.user = user.map(Self.authUser)
        }
    }

    static func authUser(_ user: User) -> AuthUser {
        let isApple = user.providerData.contains { $0.providerID == "apple.com" }
        let name = user.displayName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return AuthUser(uid: user.uid, displayName: name.isEmpty ? String(localized: "Jugador") : name,
                        photoURL: user.photoURL, provider: isApple ? .apple : .google)
    }

    func signIn(with provider: AuthProvider) async throws {
        switch provider {
        case .google:
            _ = try await auth.signIn(with: try await googleCredential())
            user = auth.currentUser.map(Self.authUser)
        case .apple:
            let result = try await apple.request()
            let credential = OAuthProvider.appleCredential(withIDToken: result.idToken, rawNonce: result.nonce, fullName: result.fullName)
            let signedIn = try await auth.signIn(with: credential).user
            user = auth.currentUser.map(Self.authUser)
            // Apple shares the name only the first time: keep it in the Firebase profile.
            if (signedIn.displayName ?? "").isEmpty, let name = appleDisplayName(from: result.fullName) {
                let change = signedIn.createProfileChangeRequest()
                change.displayName = name
                try? await callback { done in change.commitChanges(completion: done) }
                try? await callback { done in signedIn.reload(completion: done) }
                user = auth.currentUser.map(Self.authUser)
            }
        }
    }

    func signOut() throws {
        try auth.signOut()
        GIDSignIn.sharedInstance.signOut()
    }

    func reauthenticate() async throws -> ReauthProof {
        guard let current = auth.currentUser else { throw AccountDeletionError.notSignedIn }
        switch Self.authUser(current).provider {
        case .google:
            let credential = try await googleCredential()
            try await callback { done in current.reauthenticate(with: credential) { _, error in done(error) } }
            return ReauthProof(provider: .google, appleAuthorizationCode: nil)
        case .apple:
            let result = try await apple.request()
            let credential = OAuthProvider.appleCredential(withIDToken: result.idToken, rawNonce: result.nonce, fullName: result.fullName)
            try await callback { done in current.reauthenticate(with: credential) { _, error in done(error) } }
            return ReauthProof(provider: .apple, appleAuthorizationCode: result.authorizationCode)
        }
    }

    func revokeAppleToken(_ proof: ReauthProof) async throws {
        guard let code = proof.appleAuthorizationCode else { throw AuthFailure.missingToken }
        try await auth.revokeToken(withAuthorizationCode: code)
    }

    func disconnectGoogle() async {
        try? await GIDSignIn.sharedInstance.disconnect()
    }

    func deleteUser() async throws {
        guard let current = auth.currentUser else { return }
        try await callback { done in current.delete(completion: done) }
    }

    /// Bridges Firebase's completion handlers. `User` is not Sendable, so its `async` methods
    /// cannot be called from the main actor in Swift 6; the callbacks keep it here.
    private func callback(_ start: (@escaping @Sendable ((any Error)?) -> Void) -> Void) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
            start { error in
                if let error { continuation.resume(throwing: error) } else { continuation.resume() }
            }
        }
    }

    private func googleCredential() async throws -> AuthCredential {
        if let googleCredentialSource { return try await googleCredentialSource() }
        guard let clientID = FirebaseApp.app()?.options.clientID else { throw AuthFailure.notConfigured }
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        guard let presenter = UIApplication.shared.topViewController else { throw AuthFailure.noWindow }
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presenter)
        guard let idToken = result.user.idToken?.tokenString else { throw AuthFailure.missingToken }
        return GoogleAuthProvider.credential(withIDToken: idToken, accessToken: result.user.accessToken.tokenString)
    }
}
