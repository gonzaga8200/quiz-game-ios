/// Building the question order of a game. Port of `core/selection.ts`, line by line, consuming
/// the random generator in the same order so the same seed gives the same game as the web.

/// A question ready to be shown: options shuffled, `correctIndex` remapped.
public struct PlayableQuestion: Hashable, Sendable {
    public let id: String
    public let text: String
    public let options: [String]
    public let correctIndex: Int
    public let category: Category
    public let difficulty: Difficulty
    public let explanation: String
    public let source: String?

    public init(
        id: String, text: String, options: [String], correctIndex: Int, category: Category,
        difficulty: Difficulty, explanation: String, source: String?
    ) {
        self.id = id
        self.text = text
        self.options = options
        self.correctIndex = correctIndex
        self.category = category
        self.difficulty = difficulty
        self.explanation = explanation
        self.source = source
    }
}

/// Shuffles the options so the right answer's position is not fixed.
public func toPlayable(_ question: Question, rng: Rng) -> PlayableQuestion {
    let tagged = question.options.enumerated().map { (text: $0.element, correct: $0.offset == question.correctIndex) }
    let mixed = shuffled(tagged, rng: rng)
    return PlayableQuestion(
        id: question.id,
        text: question.text,
        options: mixed.map(\.text),
        correctIndex: mixed.firstIndex(where: \.correct) ?? -1,
        category: question.category,
        difficulty: question.difficulty,
        explanation: question.explanation,
        source: question.source
    )
}

/// A limit on how many consecutive items may share the same `key` value.
public struct SpreadRule<T> {
    public let key: (T) -> String
    public let max: Int

    public init(key: @escaping (T) -> String, max: Int) {
        self.key = key
        self.max = max
    }
}

/// Reorders `items` so no more than `rule.max` consecutive items share a key, for every rule,
/// keeping the original order as much as possible. Nothing is dropped: when the items left cannot
/// meet the limits, the lowest-priority rule (later in `rules`) gives way first.
public func spreadRuns<T>(_ items: [T], rules: [SpreadRule<T>]) -> [T] {
    var remaining = items
    var out: [T] = []
    out.reserveCapacity(items.count)

    func violations(_ item: T) -> Int {
        var penalty = 0
        for (index, rule) in rules.enumerated() where out.count >= rule.max {
            let key = rule.key(item)
            if out.suffix(rule.max).allSatisfy({ rule.key($0) == key }) {
                penalty += 1 << (rules.count - 1 - index)
            }
        }
        return penalty
    }

    while !remaining.isEmpty {
        var best = 0
        var bestViolations = Int.max
        var i = 0
        while i < remaining.count && bestViolations > 0 {
            let count = violations(remaining[i])
            if count < bestViolations {
                best = i
                bestViolations = count
            }
            i += 1
        }
        out.append(remaining.remove(at: best))
    }
    return out
}

/// Orders `pool` so the questions shown the fewest times come first. Stable, so the existing
/// (shuffled) order breaks ties. Counts are compared within each difficulty.
private func leastShownFirst(_ pool: [Question], seen: [String: Int]) -> [Question] {
    func shown(_ q: Question) -> Int { seen[q.id] ?? 0 }
    var floor: [Difficulty: Int] = [:]
    for q in pool {
        floor[q.difficulty] = min(floor[q.difficulty] ?? Int.max, shown(q))
    }
    func rank(_ q: Question) -> Int { shown(q) - (floor[q.difficulty] ?? 0) }
    return pool.enumerated()
        .sorted { lhs, rhs in
            let (a, b) = (rank(lhs.element), rank(rhs.element))
            return a != b ? a < b : lhs.offset < rhs.offset
        }
        .map(\.element)
}

/// The whole question order of a game: active questions matching the filter (and category),
/// first copy of each id only, shuffled, least shown first, spread out, options shuffled.
public func buildQueue(
    _ questions: [Question],
    filter: DifficultyFilter,
    rng: Rng,
    category: Category? = nil,
    seen: [String: Int]? = nil
) -> [PlayableQuestion] {
    let allowed = Set(filter.difficulties)
    var included = Set<String>()
    let pool = questions.filter { q in
        guard q.status == .active, allowed.contains(q.difficulty) else { return false }
        if let category, q.category != category { return false }
        guard !included.contains(q.id) else { return false }
        included.insert(q.id)
        return true
    }
    let shuffledPool = shuffled(pool, rng: rng)
    let order: [Question]
    if let seen, !seen.isEmpty {
        order = leastShownFirst(shuffledPool, seen: seen)
    } else {
        order = shuffledPool
    }

    var rules: [SpreadRule<Question>] = []
    if category == nil {
        rules.append(SpreadRule(key: { $0.category.rawValue }, max: Rules.maxSameCategoryInARow))
    }
    if filter == .random {
        rules.append(SpreadRule(key: { $0.difficulty.rawValue }, max: Rules.maxSameInARow))
    }
    let ordered = rules.isEmpty ? order : spreadRuns(order, rules: rules)
    return ordered.map { toPlayable($0, rng: rng) }
}
