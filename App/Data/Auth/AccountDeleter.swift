import Foundation
import OSLog

nonisolated enum AccountDeletionError: Error, Equatable {
    case notSignedIn
}

/// Deletes the player's account and everything public about them, as the App Store requires
/// (Guideline 5.1.1(v)): first the ranking entries on every board, then the account. If the
/// entries cannot be deleted, the account stays, so nothing is left half done.
struct AccountDeleter {
    let auth: any AuthService
    let ranking: any RankingStore
    var timeout: Duration = .seconds(10)
    var sleep: Sleeper = realSleeper

    /// Returns the provider of the deleted account, for the `account_deleted` event.
    func delete() async throws -> AuthProvider {
        guard let user = auth.user else { throw AccountDeletionError.notSignedIn }
        let proof = try await auth.reauthenticate()
        // Offline, Firestore queues the batch and never answers: give up so the player can retry.
        let ranking = ranking
        let uid = user.uid
        let boards = allBoards.map(\.id)
        try await withTimeout(timeout, sleep: sleep) { try await ranking.deleteEntries(uid: uid, boards: boards) }
        switch proof.provider {
        case .apple:
            do {
                try await auth.revokeAppleToken(proof)
            } catch {
                // Needs the "OAuth code flow" settings in Firebase (paid Apple account). The account
                // is still deleted below; the player can also remove the app in their Apple ID settings.
                Logger(subsystem: "com.contrarrelojquiz.app", category: "auth").error("Apple token revocation failed")
            }
        case .google:
            await auth.disconnectGoogle()
        }
        try await auth.deleteUser()
        try? auth.signOut()
        return proof.provider
    }
}
