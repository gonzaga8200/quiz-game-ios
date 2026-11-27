import Foundation

/// Contact by email, like the web (`app/utils/feedback.ts`): the app never sends anything itself,
/// it opens the player's mail app with the address, the subject and the text ready.
struct MailDraft: Equatable, Sendable {
    let to: String
    let subject: String
    let body: String

    var mailtoURL: URL {
        URL(string: mailtoHref(email: to, subject: subject, body: body))!
    }
}

enum ContactReason: CaseIterable {
    case suggestion, wrongAnswer, other

    var key: String {
        switch self {
        case .suggestion: "suggestion"
        case .wrongAnswer: "wrong-answer"
        case .other: "other"
        }
    }

    var label: String {
        switch self {
        case .suggestion: String(localized: "Una sugerencia")
        case .wrongAnswer: String(localized: "Una pregunta con una respuesta incorrecta")
        case .other: String(localized: "Otra consulta")
        }
    }

    var subject: String {
        switch self {
        case .suggestion: String(localized: "Sugerencia · Contrarreloj")
        case .wrongAnswer: String(localized: "Pregunta con respuesta incorrecta · Contrarreloj")
        case .other: String(localized: "Consulta · Contrarreloj")
        }
    }

    var draft: MailDraft {
        MailDraft(to: AppLinks.contactEmail, subject: subject, body: "")
    }
}

/// JavaScript's `encodeURIComponent`: only ASCII letters, digits and `-_.!~*'()` stay as they are.
private let uriComponentAllowed = CharacterSet(
    charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_.!~*'()"
)

func encodeURIComponent(_ value: String) -> String {
    value.addingPercentEncoding(withAllowedCharacters: uriComponentAllowed) ?? ""
}

/// `mailto:` link for an address, with an optional subject and body (same output as the web).
func mailtoHref(email: String, subject: String = "", body: String = "") -> String {
    var params: [String] = []
    if !subject.isEmpty { params.append("subject=\(encodeURIComponent(subject))") }
    if !body.isEmpty { params.append("body=\(encodeURIComponent(body))") }
    return "mailto:\(email)" + (params.isEmpty ? "" : "?" + params.joined(separator: "&"))
}

private nonisolated(unsafe) let questionIdPattern = #/[A-Za-z0-9_-]{1,64}/#

/// A report about a question in the game: subject and question filled in; the body ends after a
/// blank line, where the player writes what they see.
func questionReportDraft(id: String, text: String) -> MailDraft {
    let validId = id.wholeMatch(of: questionIdPattern) != nil ? id : ""
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    let cut = String(decoding: Array(trimmed.utf16.prefix(300)), as: UTF16.self)
    let subject = validId.isEmpty
        ? String(localized: "Pregunta con respuesta incorrecta")
        : String(localized: "Pregunta con respuesta incorrecta (pregunta \(validId))")
    var lines: [String] = []
    if !cut.isEmpty { lines.append(String(localized: "Pregunta: \(cut)")) }
    if !validId.isEmpty { lines.append(String(localized: "Identificador: \(validId)")) }
    let body = lines.isEmpty ? "" : lines.joined(separator: "\n") + "\n\n"
    return MailDraft(to: AppLinks.contactEmail, subject: subject, body: body)
}

/// A report about a player shown in the ranking (name or photo), for moderation.
func playerReportDraft(board: String, uid: String, name: String) -> MailDraft {
    let lines = [
        String(localized: "Tabla: \(board)"),
        String(localized: "Jugador: \(name)"),
        String(localized: "Identificador: \(uid)"),
    ]
    return MailDraft(
        to: AppLinks.contactEmail,
        subject: String(localized: "Jugador reportado en el ranking · Contrarreloj"),
        body: lines.joined(separator: "\n") + "\n\n"
    )
}
