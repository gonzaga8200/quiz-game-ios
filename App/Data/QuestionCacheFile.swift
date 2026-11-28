import Foundation

/// The 24 h copy of the question bank, in the Caches directory (public quiz content, nothing
/// personal; the system may purge it and the game just downloads again).
nonisolated struct QuestionCacheFile: QuestionCacheStore {
    let url: URL

    static var standard: QuestionCacheFile {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        return QuestionCacheFile(url: caches.appending(path: "contrarreloj-questions-v1.json"))
    }

    func read() -> CachedBank? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(CachedBank.self, from: data)
    }

    func write(_ bank: CachedBank) {
        guard let data = try? JSONEncoder().encode(bank) else { return }
        try? data.write(to: url, options: .atomic) // full or blocked storage: fetch again next time
    }
}
