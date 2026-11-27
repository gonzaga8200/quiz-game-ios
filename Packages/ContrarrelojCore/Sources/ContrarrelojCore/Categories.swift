/// The seven categories, in the web's order. Port of `core/constants.ts` and `core/categories.ts`.
public enum Category: String, CaseIterable, Codable, Sendable {
    case artAndLiterature = "Arte y Literatura"
    case historyAndGeography = "Historia y Geografía"
    case sports = "Deportes"
    case filmAndTV = "Cine y televisión"
    case science = "Ciencias"
    case languages = "Lengua e Idiomas"
    case music = "Música"

    /// ASCII slug used in public URLs (`/preguntas/<slug>`) and in ranking board ids.
    public var urlSlug: String {
        switch self {
        case .artAndLiterature: "arte-y-literatura"
        case .historyAndGeography: "historia-y-geografia"
        case .sports: "deportes"
        case .filmAndTV: "cine-y-television"
        case .science: "ciencias"
        case .languages: "lengua-e-idiomas"
        case .music: "musica"
        }
    }

    /// The category for a URL slug, or nil for anything that is not exactly one of them.
    public init?(urlSlug: String) {
        guard let match = Category.allCases.first(where: { $0.urlSlug == urlSlug }) else { return nil }
        self = match
    }
}

/// What the setup and ranking screens offer: every category ("Aleatorio") or a single one.
public enum CategoryChoice: Hashable, Sendable {
    case random
    case only(Category)

    public var category: Category? {
        switch self {
        case .random: nil
        case .only(let category): category
        }
    }
}
