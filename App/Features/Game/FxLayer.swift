import SwiftUI

/// Decorative effects over the game (the web's FxLayer): a red flash on mistakes, the streak
/// banner and confetti. VoiceOver hears the same events in words.
struct FxLayer: View {
    let fx: GameFx
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack(alignment: .top) {
            if fx.wrongFlash != nil {
                Rectangle()
                    .strokeBorder(Color(red: 0.94, green: 0.09, blue: 0.05), lineWidth: 10)
                    .shadow(color: Color(red: 0.94, green: 0.09, blue: 0.05), radius: 30)
                    .ignoresSafeArea()
                    .transition(.opacity)
            }
            if let banner = fx.banner {
                HStack(spacing: 8) {
                    Image(systemName: "flame.fill")
                    Text("¡Racha de \(banner.streak)!")
                    if banner.bonus > 0 {
                        Text("+\(banner.bonus) de bonus").font(.reading(.body, weight: .bold))
                    }
                }
                .font(.display(banner.big ? .title2 : .headline, weight: .heavy, italic: true))
                .foregroundStyle(Color.tinta)
                .padding(.horizontal, banner.big ? 20 : 14)
                .padding(.vertical, banner.big ? 12 : 8)
                .background(Color.oroClaro, in: Capsule())
                .overlay(Capsule().strokeBorder(Color.oroSombra, lineWidth: 2))
                .shadow(color: .black.opacity(0.4), radius: 8, y: 4)
                .padding(.top, 96)
                .id(banner.id)
                .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))
                if banner.big {
                    Confetti(kind: .pieces, count: 24).id(banner.id)
                }
            }
        }
        .animation(reduceMotion ? nil : .spring(duration: 0.3), value: fx.banner)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
