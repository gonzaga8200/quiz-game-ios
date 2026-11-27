import SwiftUI

/// Links to the game's accounts (the web's SocialLinks), written out without a ForEach.
struct SocialLinks: View {
    var showBlurb = false

    var body: some View {
        VStack(spacing: 10) {
            link(.instagram)
            link(.x)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Redes sociales de Contrarreloj"))
    }

    private func link(_ network: SocialNetwork) -> some View {
        Link(destination: network.url) {
            HStack(spacing: 12) {
                Image(network.icon).renderingMode(.template).resizable().frame(width: 24, height: 24)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: network.name).font(.reading(.body, weight: .bold))
                    Text(verbatim: network.handle).font(.reading(.subheadline))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    if showBlurb { Text(verbatim: network.blurb).font(.reading(.footnote)) }
                }
                Spacer(minLength: 0)
                Image(systemName: "arrow.up.right").font(.footnote.weight(.bold)).accessibilityHidden(true)
            }
            .padding(12)
            .foregroundStyle(Color.cardText)
            .background(Color.card, in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.papelBorde, lineWidth: 1))
        }
        .accessibilityIdentifier("social.\(network.name.lowercased())")
    }
}
