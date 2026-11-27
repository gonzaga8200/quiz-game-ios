import Foundation

/// A quiz question as stored in `data/questions/*.json` and in Firestore. Port of `QuestionSchema`
/// in `core/schema.ts`. Decoding is strict like the web's `z.strictObject`: an unknown field fails.
public struct Question: Codable, Hashable, Sendable {
    public let id: String
    public let text: String
    public let options: [String]
    public let correctIndex: Int
    public let category: Category
    public let difficulty: Difficulty
    public let explanation: String
    public let source: String?
    /// ISO-8601 UTC string (`2026-11-16T00:00:00.000Z`), like the web's schema.
    public let createdAt: String
    public let status: QuestionStatus

    public init(
        id: String, text: String, options: [String], correctIndex: Int, category: Category,
        difficulty: Difficulty, explanation: String, source: String?, createdAt: String, status: QuestionStatus
    ) {
        self.id = id
        self.text = text
        self.options = options
        self.correctIndex = correctIndex
        self.category = category
        self.difficulty = difficulty
        self.explanation = explanation
        self.source = source
        self.createdAt = createdAt
        self.status = status
    }

    /// The question as the web's schema would accept it (strings trimmed), or nil if it would not.
    public static func validated(_ q: Question) -> Question? {
        let text = trimmedJS(q.text)
        let explanation = trimmedJS(q.explanation)
        let options = q.options.map(trimmedJS)
        let source = q.source.map(trimmedJS)

        guard q.id.wholeMatch(of: idPattern) != nil,
              (10...300).contains(text.utf16.count),
              (10...300).contains(explanation.utf16.count),
              options.count == Rules.optionsPerQuestion,
              options.allSatisfy({ (1...120).contains($0.utf16.count) }),
              Set(options.map { $0.lowercased(with: spanish) }).count == options.count,
              (0...3).contains(q.correctIndex),
              source.map({ (1...500).contains($0.utf16.count) }) ?? true,
              q.createdAt.wholeMatch(of: isoDateTimePattern) != nil
        else { return nil }

        return Question(
            id: q.id, text: text, options: options, correctIndex: q.correctIndex, category: q.category,
            difficulty: q.difficulty, explanation: explanation, source: source, createdAt: q.createdAt, status: q.status
        )
    }

    // MARK: Strict decoding

    private enum CodingKeys: String, CodingKey, CaseIterable {
        case id, text, options, correctIndex, category, difficulty, explanation, source, createdAt, status
    }

    public init(from decoder: any Decoder) throws {
        try rejectUnknownKeys(in: decoder, known: CodingKeys.allCases.map(\.rawValue))
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: try c.decode(String.self, forKey: .id),
            text: try c.decode(String.self, forKey: .text),
            options: try c.decode([String].self, forKey: .options),
            correctIndex: try c.decode(Int.self, forKey: .correctIndex),
            category: try c.decode(Category.self, forKey: .category),
            difficulty: try c.decode(Difficulty.self, forKey: .difficulty),
            explanation: try c.decode(String.self, forKey: .explanation),
            source: try c.decodeIfPresent(String.self, forKey: .source),
            createdAt: try c.decode(String.self, forKey: .createdAt),
            status: try c.decode(QuestionStatus.self, forKey: .status)
        )
    }
}

private nonisolated(unsafe) let idPattern = #/[a-z0-9][a-z0-9-]{2,79}/#
private nonisolated(unsafe) let isoDateTimePattern =
    #/[0-9]{4}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])T([01][0-9]|2[0-3]):[0-5][0-9](:[0-5][0-9](\.[0-9]+)?)?Z/#
private let spanish = Locale(identifier: "es")

/// `String.prototype.trim`: whitespace and line terminators at both ends.
func trimmedJS(_ value: String) -> String {
    value.trimmingCharacters(in: .whitespacesAndNewlines)
}

/// Throws when the decoded object has a key outside `known` (zod's `strictObject`).
func rejectUnknownKeys(in decoder: any Decoder, known: [String]) throws {
    let container = try decoder.container(keyedBy: AnyCodingKey.self)
    let allowed = Set(known)
    if let unknown = container.allKeys.first(where: { !allowed.contains($0.stringValue) }) {
        throw DecodingError.dataCorrupted(
            .init(codingPath: decoder.codingPath + [unknown], debugDescription: "unknown field '\(unknown.stringValue)'")
        )
    }
}

struct AnyCodingKey: CodingKey {
    let stringValue: String
    var intValue: Int? { nil }
    init(stringValue: String) { self.stringValue = stringValue }
    init?(intValue: Int) { nil }
}
