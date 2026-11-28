import AuthenticationServices
import CryptoKit
import Foundation
import UIKit

/// Runs the system "Sign in with Apple" sheet and returns what Firebase needs.
final class AppleSignInCoordinator: NSObject {
    nonisolated struct Result: Sendable {
        let idToken: String
        /// The raw nonce; its SHA-256 went into the request.
        let nonce: String
        let fullName: PersonNameComponents?
        let authorizationCode: String?
    }

    private var continuation: CheckedContinuation<ASAuthorization, any Error>?
    /// Shows the system sheet; tests replace it.
    private let perform: (ASAuthorizationController) -> Void

    init(perform: @escaping (ASAuthorizationController) -> Void = { $0.performRequests() }) {
        self.perform = perform
    }

    func request() async throws -> Result {
        // One sheet at a time: a second request would replace the first's continuation and leave
        // that caller waiting for ever.
        guard continuation == nil else { throw AuthFailure.busy }
        let nonce = Self.randomNonce()
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = Self.sha256(nonce)

        let authorization = try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            perform(controller)
        }
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let tokenData = credential.identityToken,
              let idToken = String(data: tokenData, encoding: .utf8)
        else { throw AuthFailure.missingToken }
        return Result(
            idToken: idToken, nonce: nonce, fullName: credential.fullName,
            authorizationCode: credential.authorizationCode.flatMap { String(data: $0, encoding: .utf8) }
        )
    }

    static func randomNonce(length: Int = 32) -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var bytes = [UInt8](repeating: 0, count: length)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        precondition(status == errSecSuccess, "SecRandomCopyBytes failed")
        return String(bytes.map { charset[Int($0) % charset.count] })
    }

    static func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}

extension AppleSignInCoordinator: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        continuation?.resume(returning: authorization)
        continuation = nil
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: any Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        UIApplication.shared.activeKeyWindow ?? ASPresentationAnchor()
    }
}

extension UIApplication {
    /// The window the player is looking at.
    var activeKeyWindow: UIWindow? {
        connectedScenes.compactMap { $0 as? UIWindowScene }.flatMap(\.windows).first(where: \.isKeyWindow)
    }

    /// The view controller to present system sheets (Google sign-in, mail, share) from.
    var topViewController: UIViewController? {
        var top = activeKeyWindow?.rootViewController
        while let presented = top?.presentedViewController { top = presented }
        return top
    }
}
