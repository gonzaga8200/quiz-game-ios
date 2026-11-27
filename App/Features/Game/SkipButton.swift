import SwiftUI

/// "Pasar": light orange while free skips remain, dark orange once it costs points (the web's
/// SkipButton, same texts for sight and for VoiceOver).
struct SkipButton: View {
    let freeLeft: Int
    let cost: Int
    let locked: Bool
    let action: () -> Void

    private var isFree: Bool { freeLeft > 0 }

    var body: some View {
        Button {
            if !locked { action() }
        } label: {
            VStack(spacing: 2) {
                Text("Pasar").font(.reading(.body, weight: .bold))
                Text(verbatim: badge).font(.reading(.footnote))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .frame(minWidth: 152, minHeight: 48)
            .foregroundStyle(isFree ? Color.tinta : Color.papel)
            .background(isFree ? Color.pasarClaro : Color.pasarOscuro, in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(isFree ? Color.pasarClaroBorde : .clear, lineWidth: 2))
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel(Text(verbatim: accessibleName))
        .accessibilityIdentifier("skip")
    }

    private var badge: String {
        if isFree {
            return freeLeft == 1 ? String(localized: "Queda 1 gratis") : String(localized: "Quedan \(freeLeft) gratis")
        }
        return "😅 " + formatSigned(-cost) + " " + (cost == 1 ? String(localized: "punto") : String(localized: "puntos"))
    }

    private var accessibleName: String {
        if isFree {
            return freeLeft == 1
                ? String(localized: "Pasar pregunta. Te queda 1 pase gratis.")
                : String(localized: "Pasar pregunta. Te quedan \(freeLeft) pases gratis.")
        }
        return String(localized: "Pasar pregunta. Cuesta \(pointsText(cost)).")
    }
}
