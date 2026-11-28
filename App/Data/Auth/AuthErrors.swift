import AuthenticationServices
import FirebaseAuth
import Foundation

/// A code safe to send to analytics (no personal data): `auth/network-request-failed` for
/// Firebase (the web's codes), `apple/<n>`, `google/<n>`, `network/<n>`, or `unknown`.
nonisolated func authErrorCode(_ error: any Error) -> String {
    let ns = error as NSError
    switch ns.domain {
    case AuthErrorDomain:
        if let name = ns.userInfo["FIRAuthErrorUserInfoNameKey"] as? String, name.hasPrefix("ERROR_") {
            return "auth/" + name.dropFirst("ERROR_".count).lowercased().replacingOccurrences(of: "_", with: "-")
        }
        return "auth/\(ns.code)"
    case ASAuthorizationError.errorDomain: return "apple/\(ns.code)"
    case "com.google.GIDSignIn": return "google/\(ns.code)"
    case NSURLErrorDomain: return "network/\(ns.code)"
    default: return "unknown"
    }
}

/// The message for the player, or nil when there is nothing to say (they closed the window).
/// Texts of the web's `auth-errors.ts`, without the browser pop-up cases.
nonisolated func authErrorMessage(_ error: any Error) -> String? {
    let ns = error as NSError
    let cancelled =
        (ns.domain == ASAuthorizationError.errorDomain && ns.code == ASAuthorizationError.canceled.rawValue)
        || (ns.domain == "com.google.GIDSignIn" && ns.code == -5)
        || (ns.domain == AuthErrorDomain && ns.code == AuthErrorCode.webContextCancelled.rawValue)
    if cancelled { return nil }
    let network =
        ns.domain == NSURLErrorDomain
        || (ns.domain == AuthErrorDomain && ns.code == AuthErrorCode.networkError.rawValue)
    if network {
        return String(localized: "No hay conexión. Revisa tu conexión a internet y vuelve a intentarlo.")
    }
    return String(localized: "No se ha podido iniciar sesión. Inténtalo de nuevo en unos minutos.")
}

nonisolated enum AuthFailure: Error, Equatable {
    case notConfigured
    case missingToken
    case noWindow
}
