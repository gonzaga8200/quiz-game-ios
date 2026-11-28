import SwiftUI
import Testing
@testable import Contrarreloj

/// Playfair Display has no tabular figures ("1" is 15.5 pt wide at 40 pt, "0" is 26.4): the clock
/// must keep its width as it counts down, or the whole game screen shifts every second.
struct ClockTextTests {
    private func width(_ view: some View) -> CGFloat {
        let renderer = ImageRenderer(content: view)
        renderer.scale = 1
        return renderer.uiImage?.size.width ?? 0
    }

    @Test func everyDigitFitsItsSlot() {
        for size in [32.0, 40.0, 56.0] as [CGFloat] {
            let slot = ClockMetrics.digitSlot(size: size)
            for digit in 0...9 {
                #expect(ClockMetrics.advance(of: "\(digit)", size: size) <= slot, "\(digit) at \(size) pt")
            }
        }
    }

    @Test func theClockKeepsItsWidthAsItCountsDown() {
        let widths = Set((0...120).map { second in
            width(ClockText(clock: formatClock(ms: Double(second) * 1000), size: 40))
        })
        #expect(widths.count == 1, "widths: \(widths.sorted())")
    }
}
