import SwiftUI

/// The web's `.btn--primary`: gold with an ink label. Large = `.btn--large`.
struct PrimaryButtonStyle: ButtonStyle {
    var large = false

    func makeBody(configuration: Configuration) -> some View {
        AppButtonBody(
            configuration: configuration, large: large,
            fill: configuration.isPressed ? .oroHover : .oro, border: .oroSombra, text: .tinta
        )
    }
}

/// The web's `.btn--secondary`: parchment with an ink border and label.
struct SecondaryButtonStyle: ButtonStyle {
    var large = false

    func makeBody(configuration: Configuration) -> some View {
        AppButtonBody(
            configuration: configuration, large: large,
            fill: configuration.isPressed ? .papelOscuro : .papel, border: .tinta, text: .tinta
        )
    }
}

private struct AppButtonBody: View {
    let configuration: ButtonStyle.Configuration
    let large: Bool
    let fill: Color
    let border: Color
    let text: Color
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        configuration.label
            .font(.reading(large ? .title3 : .body, weight: .bold))
            .multilineTextAlignment(.center)
            .foregroundStyle(text)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, minHeight: large ? 60 : 52)
            .background(fill, in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(border, lineWidth: 2))
            .contentShape(RoundedRectangle(cornerRadius: 8))
            .offset(y: configuration.isPressed ? 1 : 0)
            .opacity(isEnabled ? 1 : 0.6)
    }
}

#Preview("Buttons") {
    VStack(spacing: 12) {
        Button("Jugar arcade") {}.buttonStyle(PrimaryButtonStyle(large: true))
        Button("Volver al menú") {}.buttonStyle(SecondaryButtonStyle())
        Button("Desactivado") {}.buttonStyle(PrimaryButtonStyle()).disabled(true)
    }
    .padding()
    .background(Color.ground)
}
