import Foundation

/// The game's accounts, the same as the web's `app/content/social.ts` (clean URLs, no tracking).
enum SocialNetwork: CaseIterable {
    case instagram, x

    var name: String {
        switch self {
        case .instagram: "Instagram"
        case .x: "X"
        }
    }

    var handle: String {
        switch self {
        case .instagram: "@contrarrelojquiz"
        case .x: "@contrarrelojqz"
        }
    }

    var url: URL {
        switch self {
        case .instagram: URL(string: "https://www.instagram.com/contrarrelojquiz/")!
        case .x: URL(string: "https://x.com/contrarrelojqz")!
        }
    }

    var blurb: String {
        switch self {
        case .instagram: String(localized: "Preguntas nuevas y novedades del juego.")
        case .x: String(localized: "Novedades de Contrarreloj, al momento.")
        }
    }

    var icon: String {
        switch self {
        case .instagram: "IconInstagram"
        case .x: "IconX"
        }
    }
}
