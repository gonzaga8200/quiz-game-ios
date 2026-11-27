import Foundation
import Testing
@testable import Contrarreloj

extension EmulatorTests {
    /// Account deletion (Guideline 5.1.1(v)) with the app's AccountDeleter and FirebaseAuthService
    /// against the web's rules: the player's entries on every board go, then the account.
    @Suite struct AccountDeletion {
        @Test func deleteAccountRemovesAllBoards() async throws {
            try await Emulators.reset()
            let games: [GameReport] = [
                Emulators.report(points: 40, duration: .short, filter: .medium, category: .science),
                Emulators.report(points: 75, duration: .long, filter: .random, category: nil),
                Emulators.report(points: 12, duration: .short, filter: .easy, category: .music),
            ]
            let boards = games.map { boardId($0.duration, $0.filter, $0.category) }
            try await Emulators.seed("luis", name: "Luis", points: 90, like: games[0])

            let auth = Emulators.authService(sub: "ana", name: "Ana")
            try await auth.signIn(with: .google)
            let uid = try #require(auth.user?.uid)
            let service = RankingService(store: Emulators.store)
            for game in games {
                _ = try await service.submit(player: Emulators.player(uid, "Ana"), report: game)
            }
            for board in boards {
                #expect(try await Emulators.entry(board: board, uid: uid) != nil)
            }

            let provider = try await AccountDeleter(auth: auth, ranking: Emulators.store).delete()

            #expect(provider == .google)
            for board in boards {
                #expect(try await Emulators.entry(board: board, uid: uid) == nil, "\(board)")
            }
            #expect(auth.user == nil)
            #expect(Emulators.auth.currentUser == nil)
            // Other players keep their entries.
            #expect(try await Emulators.store.topEntries(board: boards[0]).map(\.displayName) == ["Luis"])
            // The account is gone: the same Google identity now gets a brand-new account.
            let again = Emulators.authService(sub: "ana", name: "Ana")
            try await again.signIn(with: .google)
            #expect(try #require(again.user?.uid) != uid)
        }
    }
}
