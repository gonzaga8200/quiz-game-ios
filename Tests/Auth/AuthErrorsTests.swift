import AuthenticationServices
import FirebaseAuth
import Foundation
import Testing
@testable import Contrarreloj

struct AuthErrorsTests {
    @Test func cancelShowsNothing() {
        #expect(authErrorMessage(ASAuthorizationError(.canceled)) == nil)
        #expect(authErrorMessage(NSError(domain: "com.google.GIDSignIn", code: -5)) == nil)
        #expect(authErrorMessage(NSError(domain: AuthErrorDomain, code: AuthErrorCode.webContextCancelled.rawValue)) == nil)
    }

    @Test func networkErrorMessage() {
        let expected = "No hay conexión. Revisa tu conexión a internet y vuelve a intentarlo."
        #expect(authErrorMessage(NSError(domain: AuthErrorDomain, code: AuthErrorCode.networkError.rawValue)) == expected)
        #expect(authErrorMessage(URLError(.notConnectedToInternet)) == expected)
    }

    @Test func otherErrorsGetTheGenericMessage() {
        #expect(authErrorMessage(NSError(domain: AuthErrorDomain, code: AuthErrorCode.internalError.rawValue))
            == "No se ha podido iniciar sesión. Inténtalo de nuevo en unos minutos.")
    }

    @Test func errorCodesAreSafeForAnalytics() {
        #expect(authErrorCode(ASAuthorizationError(.canceled)) == "apple/1001")
        #expect(authErrorCode(NSError(domain: "com.google.GIDSignIn", code: -5)) == "google/-5")
        #expect(authErrorCode(NSError(domain: AuthErrorDomain, code: AuthErrorCode.networkError.rawValue,
                                      userInfo: ["FIRAuthErrorUserInfoNameKey": "ERROR_NETWORK_REQUEST_FAILED"]))
            == "auth/network-request-failed")
        #expect(authErrorCode(URLError(.timedOut)) == "network/-1001")
    }

    @Test func unknownErrorCodeIsUnknown() {
        struct Weird: Error {}
        #expect(authErrorCode(Weird()) == "unknown")
    }

    /// A refused second request leaves the first one running: nothing to tell the player.
    @Test func busyHasNoMessage() {
        #expect(authErrorMessage(AuthFailure.busy) == nil)
    }
}

struct AppleNameTests {
    @Test func appleNameJoinsGivenAndFamily() {
        var name = PersonNameComponents()
        name.givenName = " Ana "
        name.familyName = "García"
        #expect(appleDisplayName(from: name) == "Ana García")
        name.familyName = nil
        #expect(appleDisplayName(from: name) == "Ana")
    }

    @Test func appleNameNilWhenHidden() {
        #expect(appleDisplayName(from: nil) == nil)
        #expect(appleDisplayName(from: PersonNameComponents()) == nil)
        var blank = PersonNameComponents()
        blank.givenName = "  "
        #expect(appleDisplayName(from: blank) == nil)
    }
}
