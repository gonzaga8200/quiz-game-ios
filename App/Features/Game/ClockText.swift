import SwiftUI
import UIKit

/// Measurements of the clock's typeface (Playfair Display ExtraBold), which has proportional
/// figures only: at 40 pt a "1" is 15.5 pt wide and a "0" 26.4.
nonisolated enum ClockMetrics {
    static let fontName = AppTypeface.display(weight: .heavy, italic: false)

    /// Width of `text` set in the clock's typeface at `size` points, rounded up.
    static func advance(of text: String, size: CGFloat) -> CGFloat {
        guard let font = UIFont(name: fontName, size: size) else { return 0 }
        return ceil((text as NSString).size(withAttributes: [.font: font]).width)
    }

    /// The widest digit per point of size: glyph advances grow linearly with the size.
    private static let widestDigitPerPoint: CGFloat = {
        let reference: CGFloat = 100
        return ((0...9).map { advance(of: "\($0)", size: reference) }.max() ?? 0) / reference
    }()

    /// Width of one digit's slot: as wide as the widest digit.
    static func digitSlot(size: CGFloat) -> CGFloat {
        ceil(widestDigitPerPoint * size)
    }
}

/// The game clock ("M:SS"). Each digit sits in a slot as wide as the widest one, so the clock
/// keeps its width as it counts down; otherwise everything laid out around it shifted every second.
struct ClockText: View {
    let clock: String
    let size: CGFloat
    @ScaledMetric private var scaledSize: CGFloat

    init(clock: String, size: CGFloat) {
        self.clock = clock
        self.size = size
        _scaledSize = ScaledMetric(wrappedValue: size, relativeTo: .title)
    }

    var body: some View {
        let slot = ClockMetrics.digitSlot(size: scaledSize)
        let parts = clock.split(separator: ":", maxSplits: 1).map(String.init)
        Group {
            if parts.count == 2, parts[1].count == 2 {
                let minutes = parts[0]
                let seconds = Array(parts[1])
                // Written out without a ForEach (see GameScreen.scrolls on iOS 26's renderer).
                HStack(spacing: 0) {
                    Text(verbatim: minutes).fixedSize()
                        .frame(width: slot * CGFloat(max(minutes.count, 1)), alignment: .trailing)
                    Text(verbatim: ":").fixedSize()
                    digit(seconds[0], slot: slot)
                    digit(seconds[1], slot: slot)
                }
            } else {
                Text(verbatim: clock).fixedSize()
            }
        }
        .font(.display(size: size, relativeTo: .title, weight: .heavy))
    }

    /// One digit, drawn whole (never "…") and centred in its slot.
    private func digit(_ character: Character, slot: CGFloat) -> some View {
        Text(verbatim: String(character)).fixedSize().frame(width: slot)
    }
}
