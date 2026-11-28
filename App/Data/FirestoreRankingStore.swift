import FirebaseFirestore
import Foundation

/// The ranking in Firestore: `rankings/{board}/entries/{uid}`, one document per player per board.
nonisolated final class FirestoreRankingStore: RankingStore, @unchecked Sendable {
    private let db: Firestore

    init(db: Firestore) {
        self.db = db
    }

    private func entries(_ board: String) -> CollectionReference {
        db.collection("rankings").document(board).collection("entries")
    }

    func getBestPoints(board: String, uid: String) async throws -> Int? {
        let snapshot = try await entries(board).document(uid).getDocument(source: .server)
        return (snapshot.get("points") as? NSNumber)?.intValue
    }

    func saveEntry(board: String, entry: ScoreSubmission) async throws {
        try await entries(board).document(entry.uid).setData(FirestoreMapping.submissionData(entry))
    }

    func countBetter(board: String, points: Int) async throws -> Int {
        let snapshot = try await entries(board).whereField("points", isGreaterThan: points).count.getAggregation(source: .server)
        return snapshot.count.intValue
    }

    func topEntries(board: String) async throws -> [RankingEntry] {
        let snapshot = try await entries(board)
            .order(by: "points", descending: true)
            .limit(to: Rules.rankingSize)
            .getDocuments(source: .server)
        return snapshot.documents.compactMap { FirestoreMapping.rankingEntry($0.data()) }
    }

    func deleteEntries(uid: String, boards: [String]) async throws {
        let batch = db.batch()
        for board in boards {
            batch.deleteDocument(entries(board).document(uid))
        }
        try await batch.commit()
    }
}
