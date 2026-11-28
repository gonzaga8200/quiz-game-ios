/// The questions a category page shows. Port of `core/showcase.ts`: stable (no randomness, no
/// dependence on input order), so the selection only changes when the bank changes.

/// FNV-1a over UTF-16 code units, exactly like the web's `charCodeAt` loop.
private func hash(_ value: String) -> UInt32 {
    var h: UInt32 = 0x811C_9DC5
    for unit in value.utf16 {
        h ^= UInt32(unit)
        h = h &* 0x0100_0193
    }
    return h
}

/// A fixed order: by hash of the id, then by the id itself if two hashes collide.
private func stableOrder(_ a: Question, _ b: Question) -> Bool {
    let (ha, hb) = (hash(a.id), hash(b.id))
    return ha != hb ? ha < hb : a.id < b.id
}

/// Takes questions from each difficulty in turn, so a category whose bank is mostly one level
/// still shows a mix, and lists them from easiest to hardest.
public func pickShowcase(_ questions: [Question], category: QuizCategory, count: Int) -> [Question] {
    var seen = Set<String>()
    var buckets: [Difficulty: [Question]] = [:]
    for q in questions where q.category == category && q.status == .active && !seen.contains(q.id) {
        seen.insert(q.id)
        buckets[q.difficulty, default: []].append(q)
    }
    for difficulty in buckets.keys {
        buckets[difficulty]?.sort(by: stableOrder)
    }

    var picked: [Question] = []
    var round = 0
    while picked.count < count {
        var tookAny = false
        for difficulty in Difficulty.allCases {
            if let bucket = buckets[difficulty], round < bucket.count, picked.count < count {
                picked.append(bucket[round])
                tookAny = true
            }
        }
        if !tookAny { break }
        round += 1
    }

    return picked.sorted { a, b in
        a.difficulty != b.difficulty ? a.difficulty < b.difficulty : stableOrder(a, b)
    }
}

/// How many active questions each category has (a repeated id counts once).
public func countActiveByCategory(_ questions: [Question]) -> [QuizCategory: Int] {
    var counts = Dictionary(uniqueKeysWithValues: QuizCategory.allCases.map { ($0, 0) })
    var seen = Set<String>()
    for q in questions where q.status == .active && !seen.contains(q.id) {
        seen.insert(q.id)
        counts[q.category, default: 0] += 1
    }
    return counts
}
