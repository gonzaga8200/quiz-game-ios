import SwiftUI

/// One category (the web's /preguntas/<categoria>): its intro, 20 questions with their answer and
/// explanation (the same stable selection as the web, easiest first), and an arcade game of it.
struct CategoryDetailScreen: View {
    let category: QuizCategory
    /// nil while the bank loads.
    let catalog: CategoryCatalog?
    @Environment(AppEnvironment.self) private var env

    private static let showcaseSize = CategoryCatalog.showcaseSize

    var body: some View {
        let text = copy(for: category)
        let items = catalog?.showcase(for: category) ?? []
        let total = catalog.map { $0.counts[category] ?? 0 }
        let lower = category.rawValue.lowercased()
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(verbatim: text.heading)
                    .font(.display(.largeTitle, weight: .heavy, italic: true))
                    .foregroundStyle(Color.accentOnGround)
                    .accessibilityAddTraits(.isHeader)
                Text(verbatim: text.intro[0]).font(.reading(.body))
                Text(verbatim: text.intro[1]).font(.reading(.body))
                if let total {
                    Text("En el juego hay \(total) preguntas de \(lower). Aquí ves \(items.count), de las más fáciles a las más difíciles.")
                        .font(.reading(.body, weight: .bold))
                } else {
                    ProgressView { Text("Cargando preguntas…") }.frame(maxWidth: .infinity)
                }
                playButton(lower)

                if !items.isEmpty {
                    Text(items.count == Self.showcaseSize ? "\(Self.showcaseSize) preguntas de \(lower) con respuesta" : "Preguntas de \(lower) con respuesta")
                        .font(.display(.title2, weight: .heavy, italic: true))
                        .accessibilityAddTraits(.isHeader)
                    VStack(spacing: 10) {
                        ForEach(Array(items.enumerated()), id: \.element.id) { index, question in
                            ShowcaseItem(number: index + 1, question: question)
                                .accessibilityIdentifier("category.item.\(index)")
                        }
                    }
                }

                Text("¿Cuántas aciertas en 60 segundos?").font(.display(.title2, weight: .heavy, italic: true))
                playButton(lower)

                Text("Más preguntas con respuestas").font(.display(.title3, weight: .heavy, italic: true))
                ForEach(QuizCategory.allCases.filter { $0 != category }, id: \.self) { other in
                    NavigationLink(value: other) {
                        Label(copy(for: other).title, systemImage: "chevron.right")
                            .labelStyle(TrailingIconLabelStyle())
                            .font(.reading(.body, weight: .bold))
                            .foregroundStyle(Color.accentOnGround)
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
        }
        .foregroundStyle(Color.onGround)
        .background(Color.ground.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .trackScreen("Categoría: \(category.urlSlug)")
    }

    private func playButton(_ lower: String) -> some View {
        Button { env.play.play(.arcade(category: category)) } label: { Text("Jugar con preguntas de \(lower)") }
            .buttonStyle(PrimaryButtonStyle(large: true))
            .accessibilityIdentifier("category.play")
    }
}

private struct ShowcaseItem: View {
    let number: Int
    let question: Question

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(verbatim: "\(number). \(question.text)").font(.reading(.body, weight: .bold))
            (Text("Respuesta: ").bold() + Text(verbatim: question.options[question.correctIndex])).font(.reading(.body))
            Text(verbatim: question.explanation).font(.reading(.subheadline, italic: true)).foregroundStyle(Color.cardTextSoft)
            Text("Dificultad: \(question.difficulty.rawValue)").font(.reading(.footnote)).foregroundStyle(Color.cardTextSoft)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .foregroundStyle(Color.cardText)
        .background(Color.card, in: RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .combine)
    }
}

private struct TrailingIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 6) {
            configuration.title
            configuration.icon.font(.footnote)
        }
    }
}
