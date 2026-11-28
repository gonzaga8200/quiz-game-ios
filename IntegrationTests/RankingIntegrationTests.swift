import FirebaseFirestore
import Foundation
import Testing
@testable import Contrarreloj

extension EmulatorTests {
    /// The app's ranking code (RankingService + FirestoreRankingStore) against the web's rules.
    @Suite struct Ranking {
        private let board = boardId(.short, .medium, .science)

        @Test func writesAreAcceptedByRules() async throws {
            try await Emulators.reset()
            let auth = Emulators.authService(sub: "ana", name: "Ana")
            try await auth.signIn(with: .google)
            let uid = try #require(auth.user?.uid)

            let result = try await RankingService(store: Emulators.store)
                .submit(player: Emulators.player(uid, "Ana"), report: Emulators.report(points: 42))

            #expect(result == .newBest(best: 42, position: 1))
            let data = try #require(try await Emulators.entry(board: board, uid: uid))
            #expect(data["uid"] as? String == uid)
            #expect(data["displayName"] as? String == "Ana")
            #expect(data["photoURL"] as? String == "https://example.com/\(uid).png")
            #expect(data["difficultyFilter"] as? String == "Medio")
            #expect(data["category"] as? String == "Ciencias")
            for field in ["points", "correct", "wrong", "skipped", "duration"] {
                let number = try #require(data[field] as? NSNumber, "\(field)")
                #expect(!CFNumberIsFloatType(number), "\(field) must be stored as an integer")
            }
            #expect(data["points"] as? Int == 42)
            #expect(data["duration"] as? Int == 60)
            #expect(data["createdAt"] is Timestamp, "createdAt comes from the server")
        }

        @Test func lowerScoreIsKept() async throws {
            try await Emulators.reset()
            let auth = Emulators.authService(sub: "ana", name: "Ana")
            try await auth.signIn(with: .google)
            let uid = try #require(auth.user?.uid)
            let service = RankingService(store: Emulators.store)

            _ = try await service.submit(player: Emulators.player(uid, "Ana"), report: Emulators.report(points: 50))
            let second = try await service.submit(player: Emulators.player(uid, "Ana"), report: Emulators.report(points: 30))

            #expect(second == .kept(best: 50, position: 1))
            #expect(try await Emulators.points(board: board, uid: uid) == 50)

            // The rules refuse a lower score even from a client that skipped that check.
            let lower = toScoreSubmission(player: Emulators.player(uid, "Ana"), report: Emulators.report(points: 10))
            do {
                try await Emulators.store.saveEntry(board: board, entry: lower)
                Issue.record("a lower score should be refused by the rules")
            } catch {
                #expect(isPermissionDenied(error), "\(error)")
            }
            #expect(try await Emulators.points(board: board, uid: uid) == 50)
        }

        @Test func positionCountsBetterPlayers() async throws {
            try await Emulators.reset()
            try await Emulators.seed("luis", name: "Luis", points: 90)
            try await Emulators.seed("marta", name: "Marta", points: 70)
            let auth = Emulators.authService(sub: "ana", name: "Ana")
            try await auth.signIn(with: .google)
            let uid = try #require(auth.user?.uid)
            let service = RankingService(store: Emulators.store)

            let result = try await service.submit(player: Emulators.player(uid, "Ana"), report: Emulators.report(points: 80))

            #expect(result == .newBest(best: 80, position: 2))
            let top = try await service.top(board: board, forceRefresh: true)
            #expect(top.map(\.displayName) == ["Luis", "Ana", "Marta"])
            #expect(top.map(\.points) == [90, 80, 70])
        }

        @Test func otherUidCannotWrite() async throws {
            try await Emulators.reset()
            try await Emulators.seed("luis", name: "Luis", points: 90)
            let luis = Emulators.authService(sub: "luis", name: "Luis")
            try await luis.signIn(with: .google)
            let luisUid = try #require(luis.user?.uid)
            try luis.signOut()

            let auth = Emulators.authService(sub: "ana", name: "Ana")
            try await auth.signIn(with: .google)
            let impostor = toScoreSubmission(player: Emulators.player(luisUid, "Ana"), report: Emulators.report(points: 120))

            do {
                try await Emulators.store.saveEntry(board: board, entry: impostor)
                Issue.record("writing another player's entry should be refused")
            } catch {
                #expect(isPermissionDenied(error), "\(error)")
            }
            do {
                try await Emulators.store.deleteEntries(uid: luisUid, boards: [board])
                Issue.record("deleting another player's entry should be refused")
            } catch {
                #expect(isPermissionDenied(error), "\(error)")
            }
            #expect(try await Emulators.points(board: board, uid: luisUid) == 90)
        }
    }
}
