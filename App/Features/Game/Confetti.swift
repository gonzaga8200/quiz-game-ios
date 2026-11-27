import SwiftUI

/// Falling confetti: coloured pieces for a streak bonus, emojis for the end-of-game celebration.
/// Deterministic positions (like the web's), drawn in a Canvas; nothing shows under Reduce Motion.
struct Confetti: View {
    enum Kind {
        case pieces
        case emojis([String])
    }

    let kind: Kind
    let count: Int
    var duration: Double = 2.2
    @State private var start = Date()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let colors: [Color] = [.oroClaro, .falloSuelo, Color(hex: 0x5FC7A0), Color(hex: 0x7FB3D5), .papel]

    var body: some View {
        if !reduceMotion {
            TimelineView(.animation) { context in
                let elapsed = context.date.timeIntervalSince(start)
                Canvas { canvas, size in
                    guard elapsed < duration + 1 else { return }
                    for i in 0..<count {
                        let x = Double((i * 37 + 11) % 100) / 100 * size.width
                        let drift = Double((i * 53) % 41 - 20) / 100 * size.width
                        let delay = Double(i % 8) * 0.05
                        let t = max(0, elapsed - delay) / duration
                        guard t > 0, t < 1 else { continue }
                        let point = CGPoint(x: x + drift * t, y: -20 + (size.height + 40) * t * t)
                        let angle = Angle.degrees(Double(240 + (i * 71) % 360) * t)
                        switch kind {
                        case .pieces:
                            var piece = canvas
                            piece.translateBy(x: point.x, y: point.y)
                            piece.rotate(by: angle)
                            piece.fill(Path(CGRect(x: -4, y: -7, width: 8, height: 14)),
                                       with: .color(Self.colors[i % Self.colors.count]))
                        case .emojis(let emojis):
                            guard !emojis.isEmpty else { continue }
                            canvas.draw(Text(verbatim: emojis[i % emojis.count]).font(.system(size: 26)), at: point)
                        }
                    }
                }
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .onAppear { start = Date() }
        }
    }
}
