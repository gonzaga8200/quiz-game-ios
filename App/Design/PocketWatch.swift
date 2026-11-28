import SwiftUI

/// Geometry of the web's pocket watch (`ClockFace.vue`), in its 200 x 232 viewBox.
enum PocketWatchGeometry {
    static let viewBox = CGSize(width: 200, height: 232)
    static let center = CGPoint(x: 100, y: 132)
    static let numerals = ["XII", "I", "II", "III", "IIII", "V", "VI", "VII", "VIII", "IX", "X", "XI"]
    /// Below this width the watch drops the numerals and minute marks, like the web's game bar.
    static let compactWidth: CGFloat = 128

    /// Degrees of the time-left ring still drawn, starting at twelve o'clock.
    static func remainingSweep(progress: Double) -> Double {
        360 * (1 - min(1, max(0, progress)))
    }
}

/// The pocket watch, the signature of the game. Decorative: the exact time is read elsewhere.
struct PocketWatch: View {
    /// 0 at the start of the game, 1 when time is up.
    var progress: Double
    /// Cover screen: the hand sweeps on its own (once a minute), like a clock on a wall.
    var idle = false
    /// Last ten seconds: the ring turns red.
    var urgent = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if idle && !reduceMotion {
                TimelineView(.animation) { context in
                    let seconds = context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 60)
                    face(hand: seconds / 60, ring: 0)
                }
            } else {
                face(hand: idle ? 0 : progress, ring: idle ? 0 : progress)
            }
        }
        .aspectRatio(PocketWatchGeometry.viewBox, contentMode: .fit)
        .accessibilityHidden(true)
    }

    private func face(hand: Double, ring: Double) -> some View {
        Canvas { context, size in
            let scale = min(size.width / PocketWatchGeometry.viewBox.width, size.height / PocketWatchGeometry.viewBox.height)
            let compact = size.width < PocketWatchGeometry.compactWidth
            context.translateBy(
                x: (size.width - PocketWatchGeometry.viewBox.width * scale) / 2,
                y: (size.height - PocketWatchGeometry.viewBox.height * scale) / 2
            )
            context.scaleBy(x: scale, y: scale)
            draw(in: &context, hand: hand, ring: ring, compact: compact)
        }
        .shadow(color: .black.opacity(0.5), radius: 6, y: 4)
    }

    private func draw(in context: inout GraphicsContext, hand: Double, ring: Double, compact: Bool) {
        let c = PocketWatchGeometry.center
        let brass = GraphicsContext.Shading.linearGradient(
            Gradient(stops: [.init(color: .latonClaro, location: 0), .init(color: .laton, location: 0.5),
                             .init(color: .latonOscuro, location: 1)]),
            startPoint: .zero, endPoint: CGPoint(x: 200, y: 232)
        )

        // Bow and crown.
        context.stroke(Path(ellipseIn: CGRect(x: 88, y: 3, width: 24, height: 24)), with: brass, lineWidth: 5)
        let crown = Path(roundedRect: CGRect(x: 90, y: 26, width: 20, height: 18), cornerRadius: 3)
        context.fill(crown, with: brass)
        context.stroke(crown, with: .color(.latonBorde), lineWidth: 1)

        // Case, inner ring and face.
        let caseCircle = Path(ellipseIn: CGRect(x: c.x - 92, y: c.y - 92, width: 184, height: 184))
        context.fill(caseCircle, with: brass)
        context.stroke(caseCircle, with: .color(.latonBorde), lineWidth: 2)
        context.stroke(Path(ellipseIn: CGRect(x: c.x - 84, y: c.y - 84, width: 168, height: 168)),
                       with: .color(.latonBorde.opacity(0.55)), lineWidth: 1.5)
        context.fill(
            Path(ellipseIn: CGRect(x: c.x - 80, y: c.y - 80, width: 160, height: 160)),
            with: .radialGradient(
                Gradient(stops: [.init(color: Color(hex: 0xF6ECD2), location: 0.6), .init(color: Color(hex: 0xDCC690), location: 1)]),
                center: CGPoint(x: 100, y: c.y - 80 + 160 * 0.42), startRadius: 0, endRadius: 160 * 0.62
            )
        )

        // Minute and hour marks.
        for i in 0..<60 {
            let major = i % 5 == 0
            if compact && !major { continue }
            var mark = Path()
            mark.move(to: CGPoint(x: c.x, y: 54))
            mark.addLine(to: CGPoint(x: c.x, y: major ? 62 : 58))
            let rotated = mark.applying(rotation(degrees: Double(i) * 6, around: c))
            context.stroke(rotated, with: .color(major ? .tinta : .tinta.opacity(0.55)),
                           style: StrokeStyle(lineWidth: major ? 2.4 : 0.9, lineCap: .round))
        }

        // Roman numerals (dropped on small watches).
        if !compact {
            for (i, label) in PocketWatchGeometry.numerals.enumerated() {
                let angle = Double(i) * .pi / 6
                let point = CGPoint(x: c.x + 50 * sin(angle), y: c.y - 50 * cos(angle))
                context.draw(
                    Text(verbatim: label).font(.custom(AppTypeface.display(weight: .bold, italic: false), fixedSize: 11))
                        .foregroundStyle(Color.tinta),
                    at: point, anchor: .center
                )
            }
        }

        // Time left: the ring empties clockwise from twelve o'clock.
        let sweep = PocketWatchGeometry.remainingSweep(progress: ring)
        if sweep > 0 {
            var arc = Path()
            arc.addArc(center: c, radius: 64, startAngle: .degrees(-90), endAngle: .degrees(-90 + sweep), clockwise: false)
            context.stroke(arc, with: .color(urgent ? .fallo : .oroSombra),
                           style: StrokeStyle(lineWidth: compact ? 8 : 5, lineCap: .round))
        }

        // Hand.
        var needle = Path()
        needle.move(to: CGPoint(x: c.x, y: 146))
        needle.addLine(to: CGPoint(x: c.x, y: 62))
        context.stroke(needle.applying(rotation(degrees: hand * 360, around: c)), with: .color(.aguja),
                       style: StrokeStyle(lineWidth: 2, lineCap: .round))
        let pin = Path(ellipseIn: CGRect(x: c.x - 5.5, y: c.y - 5.5, width: 11, height: 11))
        context.fill(pin, with: .color(.laton))
        context.stroke(pin, with: .color(.latonBorde), lineWidth: 1.5)
    }

    private func rotation(degrees: Double, around point: CGPoint) -> CGAffineTransform {
        CGAffineTransform(translationX: point.x, y: point.y)
            .rotated(by: degrees * .pi / 180)
            .translatedBy(x: -point.x, y: -point.y)
    }
}

#Preview("Watch") {
    HStack(spacing: 24) {
        PocketWatch(progress: 0.35).frame(width: 200)
        PocketWatch(progress: 0.92, urgent: true).frame(width: 56)
        PocketWatch(progress: 0, idle: true).frame(width: 120)
    }
    .padding()
    .background(Color.ground)
}
