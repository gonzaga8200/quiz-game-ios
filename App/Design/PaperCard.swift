import SwiftUI

/// A parchment panel (the web's `.panel`): ink text on paper, in both light and dark mode.
struct PaperCard<Content: View>: View {
    var padding: CGFloat = 16
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) { content }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(padding)
            .foregroundStyle(Color.cardText)
            .background(Color.card, in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.papelBorde.opacity(0.6), lineWidth: 1))
    }
}

#Preview("Card") {
    PaperCard {
        Text(verbatim: "Respuestas").font(.display(.title2, weight: .heavy, italic: true))
        Text(verbatim: "Correctas 12 · Incorrectas 3").font(.reading(.body))
    }
    .padding()
    .background(Color.ground)
}
