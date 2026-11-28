/// Keyboard shortcuts while playing (hardware keyboard on iPad): 1-4 or A-D answer, P skips.
/// Port of the web's `app/utils/keyboard.ts`.
enum GameKeyAction: Equatable {
    case answer(Int)
    case skip
}

func actionForKey(_ key: String, optionCount: Int) -> GameKeyAction? {
    let lower = key.lowercased()
    if lower == "p" { return .skip }
    let index: Int
    if lower.count == 1, let digit = Int(lower), (1...9).contains(digit) {
        index = digit - 1
    } else {
        index = ["a", "b", "c", "d"].firstIndex(of: lower) ?? -1
    }
    return index >= 0 && index < optionCount ? .answer(index) : nil
}
