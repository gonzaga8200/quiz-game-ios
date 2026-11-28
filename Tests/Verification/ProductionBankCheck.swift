import CryptoKit
import FirebaseCore
import FirebaseFirestore
import Foundation
import Testing
@testable import Contrarreloj

/// One-off, read-only check of the production question bank through the app's own code path
/// (FirestoreQuestionSource + FirestoreMapping), to compare with what the web's SDK reads.
/// Runs only when PRODUCTION_BANK_CHECK names an output file and the real
/// Config/GoogleService-Info.plist is bundled; writes counts and SHA-256 digests there as JSON.
struct ProductionBankCheck {
    nonisolated private static let output = ProcessInfo.processInfo.environment["PRODUCTION_BANK_CHECK"]

    @Test(.enabled(if: ProductionBankCheck.output != nil))
    func productionBankDigest() async throws {
        let path = try #require(Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
                                "Config/GoogleService-Info.plist is not bundled")
        let options = try #require(FirebaseOptions(contentsOfFile: path))
        if FirebaseApp.app(name: "production-check") == nil {
            FirebaseApp.configure(name: "production-check", options: options)
        }
        let app = try #require(FirebaseApp.app(name: "production-check"))
        let db = Firestore.firestore(app: app)
        let settings = FirestoreSettings()
        settings.cacheSettings = MemoryCacheSettings()
        db.settings = settings

        let source = FirestoreQuestionSource(db: db)
        let bank = try await source.fetchActive()
        let count = try await source.activeCount()
        let sorted = bank.questions.sorted { $0.id < $1.id }
        let result: [String: Any] = [
            "project": options.projectID ?? "",
            "documents": bank.documentCount,
            "countAggregate": count,
            "questions": bank.questions.count,
            "idsSha256": Self.sha256(sorted.map(\.id).joined(separator: "\n")),
            "idAnswerSha256": Self.sha256(sorted.map { "\($0.id):\($0.correctIndex)" }.joined(separator: "\n")),
        ]
        let data = try JSONSerialization.data(withJSONObject: result, options: [.prettyPrinted, .sortedKeys])
        try data.write(to: URL(fileURLWithPath: try #require(Self.output)))
        #expect(bank.questions.count == bank.documentCount, "every active document should map to a question")
    }

    nonisolated private static func sha256(_ text: String) -> String {
        SHA256.hash(data: Data(text.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}
