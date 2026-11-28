import AuthenticationServices
import Foundation
import Testing
@testable import Contrarreloj

/// A second "Sign in with Apple" while one is open must not replace (and strand) the first.
struct AppleSignInCoordinatorTests {
    @Test func secondRequestWhileOneIsOpenIsRefused() async throws {
        let coordinator = AppleSignInCoordinator(perform: { _ in }) // the system sheet stays open
        let first = Task { try await coordinator.request() }
        try await Task.sleep(for: .milliseconds(50))
        let second = Task { try await coordinator.request() }

        // Bounded waits: a refused request answers at once; a stranded one never does.
        let secondOutcome = try? await withTimeout(.seconds(1)) { await second.result }
        #expect(throws: AuthFailure.busy) { try #require(secondOutcome).get() }

        let controller = ASAuthorizationController(authorizationRequests: [ASAuthorizationAppleIDProvider().createRequest()])
        coordinator.authorizationController(controller: controller, didCompleteWithError: ASAuthorizationError(.canceled))
        let firstOutcome = try? await withTimeout(.seconds(1)) { await first.result }
        #expect(throws: ASAuthorizationError.self) { try #require(firstOutcome).get() }
    }
}
