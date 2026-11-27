import FirebaseFirestore
import Foundation

/// Active questions in Firestore (the security rules require the `status == active` filter).
nonisolated final class FirestoreQuestionSource: RemoteQuestionSource, @unchecked Sendable {
    private let db: Firestore

    init(db: Firestore) {
        self.db = db
    }

    private var active: Query {
        db.collection("questions").whereField("status", isEqualTo: "active")
    }

    func activeCount() async throws -> Int {
        let snapshot = try await active.count.getAggregation(source: .server)
        return snapshot.count.intValue
    }

    func fetchActive() async throws -> RemoteBank {
        let snapshot = try await active.getDocuments(source: .server)
        let questions = snapshot.documents.compactMap { FirestoreMapping.question(id: $0.documentID, data: $0.data()) }
        return RemoteBank(questions: questions, documentCount: snapshot.documents.count)
    }
}
