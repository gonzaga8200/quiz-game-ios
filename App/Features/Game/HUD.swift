import SwiftUI

/// Clock, score, streak and the combo hint (the web's GameHud). A slim bar on phones, a side panel
/// on wide screens. The bar fits a 375-pt-wide iPhone up to the "xLarge" text size; from
/// "xxLarge" (where the game screen also starts to scroll) it uses two rows. A bar wider than the
/// screen gets centred again whenever its width changes, and the whole screen shifts.
struct HUD: View {
    let session: GameSession
    let fx: GameFx
    let wide: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize

    private var durationMs: Double { session.setup.duration.milliseconds }
    private var progress: Double { 1 - session.remainingMs / durationMs }
    private var urgent: Bool { session.remainingMs <= 10_000 }
    private var clock: String { formatClock(ms: session.remainingMs) }

    var body: some View {
        Group {
            if wide {
                VStack(spacing: 16) {
                    PocketWatch(progress: progress, urgent: urgent).frame(maxWidth: 220)
                    clockText(size: 56)
                    HStack(spacing: 12) { scoreTile; streakTile }
                    comboHint
                }
                .padding(20)
            } else if typeSize >= .xxLarge {
                // Large text: clock on one row, score and streak on the next.
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 10) {
                        PocketWatch(progress: progress, urgent: urgent).frame(width: 40)
                        clockText(size: 40)
                        Spacer(minLength: 0)
                    }
                    HStack(spacing: 8) {
                        scoreTile
                        streakTile
                        Spacer(minLength: 0)
                    }
                    comboHint
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
            } else {
                VStack(spacing: 6) {
                    HStack(spacing: 8) {
                        PocketWatch(progress: progress, urgent: urgent).frame(width: 40)
                        clockText(size: 34)
                        Spacer(minLength: 4)
                        scoreTile
                        streakTile
                    }
                    comboHint
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
            }
        }
        .background(Color.groundRaised, in: RoundedRectangle(cornerRadius: wide ? 16 : 12))
        .overlay(RoundedRectangle(cornerRadius: wide ? 16 : 12).strokeBorder(Color.oroSombra, lineWidth: 2))
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
    }

    private func clockText(size: CGFloat) -> some View {
        let pulse: CGFloat = urgent && !reduceMotion && Int(session.remainingMs / 500) % 2 == 0 ? 1.06 : 1
        return ClockText(clock: clock, size: size)
            .foregroundStyle(urgent ? Color.errorOnGround : Color.accentOnGround)
            .layoutPriority(1)
            // Only the urgent pulse animates, not the clock's frame.
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.25)) { $0.scaleEffect(pulse) }
            .accessibilityElement(children: .ignore)
            .accessibilityAddTraits(.isStaticText)
            .accessibilityLabel(Text("Tiempo restante: \(clock)"))
            .accessibilityIdentifier("hud.clock")
    }

    private func tileLabel(_ title: LocalizedStringKey) -> some View {
        Text(title).font(.reading(.caption, weight: .bold)).foregroundStyle(Color.onGroundSoft)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .accessibilityHidden(true)
    }

    private var scoreTile: some View {
        VStack(spacing: 0) {
            tileLabel("Puntos")
            Text(verbatim: "\(session.snapshot.score)")
                .font(.display(.title2, weight: .heavy))
                .monospacedDigit()
                .accessibilityLabel(Text("Puntos: \(session.snapshot.score)"))
                .accessibilityIdentifier("hud.score")
        }
        .frame(minWidth: 48)
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
        .background(fx.hit != nil ? Color.fallo.opacity(0.35) : Color.clear, in: RoundedRectangle(cornerRadius: 8))
        .overlay(alignment: .topTrailing) {
            if let hit = fx.hit {
                Text(verbatim: formatSigned(-hit.amount))
                    .font(.reading(.caption, weight: .bold))
                    .foregroundStyle(Color.errorOnGround)
                    .offset(x: 6, y: -6)
                    .accessibilityHidden(true)
            }
        }
    }

    private var streakTile: some View {
        let streak = session.snapshot.streak
        let hot = streak >= GameFx.cheerFrom
        return VStack(spacing: 0) {
            tileLabel("Racha")
            HStack(spacing: 2) {
                if hot { Image(systemName: "flame.fill").foregroundStyle(Color.oroClaro) }
                Text(verbatim: "\(streak)").font(.display(.title2, weight: .heavy)).monospacedDigit()
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("Racha: \(streak)"))
            .accessibilityIdentifier("hud.streak")
        }
        .frame(minWidth: 48)
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
        .background(fx.brokenStreak ? Color.fallo.opacity(0.35) : (hot ? Color.oroSombra.opacity(0.35) : Color.clear),
                    in: RoundedRectangle(cornerRadius: 8))
    }

    private var comboHint: some View {
        let streak = session.snapshot.streak
        let text: String
        if let milestone = nextComboMilestone(streak: streak) {
            let missing = milestone.at - streak
            let need = missing == 1
                ? String(localized: "Te falta 1 acierto seguido")
                : String(localized: "Te faltan \(missing) aciertos seguidos")
            text = String(localized: "\(need) para +\(milestone.bonus)")
        } else {
            text = String(localized: "Racha máxima de bonus alcanzada")
        }
        return Text(verbatim: text)
            .font(.reading(.footnote))
            .foregroundStyle(Color.onGroundSoft)
            .frame(maxWidth: .infinity, alignment: wide ? .center : .leading)
    }
}
