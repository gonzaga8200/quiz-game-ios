import Foundation

/// Resources bundled with the unit-test target (fixtures shared with the core package).
enum TestResources {
    private final class Token {}

    static func json<T: Decodable>(_ name: String, as type: T.Type) throws -> T {
        let bundle = Bundle(for: Token.self)
        guard let url = bundle.url(forResource: name, withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile, userInfo: [NSFilePathErrorKey: "\(name).json"])
        }
        return try JSONDecoder().decode(T.self, from: Data(contentsOf: url))
    }
}
