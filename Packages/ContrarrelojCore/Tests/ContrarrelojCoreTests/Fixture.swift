import Foundation

/// Reads a JSON fixture generated from the web's TypeScript core (see Tools/parity).
enum Fixture {
    static func load<T: Decodable>(_ name: String, as type: T.Type) throws -> T {
        guard let url = Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures") else {
            throw FixtureError.missing(name)
        }
        return try JSONDecoder().decode(T.self, from: Data(contentsOf: url))
    }
}

enum FixtureError: Error {
    case missing(String)
}
