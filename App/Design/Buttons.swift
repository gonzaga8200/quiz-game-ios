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

/// A square parchment button with an icon, for secondary actions beside a primary one (the
/// report's bar). The label must be a `Label`, so VoiceOver and UI tests read its title.
struct IconButtonStyle: ButtonStyle {
    /// Wide: shares the row's width (the stacked bar at large text sizes) instead of a square.
    var wide = false
    @ScaledMetric(relativeTo: .title3) private var scaledSide: CGFloat = 60
    /// Grows with the text a little, then stops: a bigger icon adds nothing to recognise it.
    private var side: CGFloat { min(scaledSide, 76) }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .labelStyle(.iconOnly)
            .font(.system(size: side * 0.36, weight: .semibold))
            .foregroundStyle(Color.tinta)
            .frame(width: wide ? nil : side, height: side)
            .frame(maxWidth: wide ? .infinity : nil)
            .background(configuration.isPressed ? Color.papelOscuro : Color.papel, in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.tinta, lineWidth: 2))
            .contentShape(RoundedRectangle(cornerRadius: 8))
            .offset(y: configuration.isPressed ? 1 : 0)
            .accessibilityShowsLargeContentViewer()
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
