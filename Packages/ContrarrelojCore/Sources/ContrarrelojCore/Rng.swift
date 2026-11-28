/// A random source returning a value in [0, 1), like JavaScript's `Math.random`.
public typealias Rng = () -> Double

/// mulberry32, bit for bit the same as `core/rng.ts`: `UInt32` wrapping arithmetic reproduces
/// `Math.imul` and `>>>`, so the same seed gives the same sequence on the web and here.
public func mulberry32(seed: UInt32) -> Rng {
    var state = seed
    return {
        state = state &+ 0x6D2B_79F5
        var t = state
        t = (t ^ (t >> 15)) &* (t | 1)
        t ^= t &+ ((t ^ (t >> 7)) &* (t | 61))
        return Double(t ^ (t >> 14)) / 4_294_967_296
    }
}

/// Fisher-Yates shuffle consuming the generator exactly like the web. Leaves the input untouched.
public func shuffled<T>(_ items: [T], rng: Rng) -> [T] {
    var out = items
    var i = out.count - 1
    while i > 0 {
        let j = Int((rng() * Double(i + 1)).rounded(.down))
        out.swapAt(i, j)
        i -= 1
    }
    return out
}
