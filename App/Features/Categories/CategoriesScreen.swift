import SwiftUI

/// The "Categorías" tab (the web's /preguntas): one card per category with its blurb and how many
/// questions it has, and a game with every category mixed.
struct CategoriesScreen: View {
    @Environment(AppEnvironment.self) private var env
    /// nil while the bank loads (it can be a full download on first launch).
    @State private var catalog: CategoryCatalog?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text(verbatim: hubCopy.heading)
                        .font(.display(.largeTitle, weight: .heavy, italic: true))
                        .foregroundStyle(Color.accentOnGround)
                        .accessibilityAddTraits(.isHeader)
                    ForEach(hubCopy.intro, id: \.self) { paragraph in
                        Text(verbatim: paragraph).font(.reading(.body))
                    }
                    Button("Jugar con todas las categorías") { env.play.play(.arcade()) }
                        .buttonStyle(PrimaryButtonStyle(large: true))
                        .accessibilityIdentifier("categories.playAll")
                    if catalog == nil {
                        ProgressView { Text("Cargando preguntas…") }
                            .frame(maxWidth: .infinity)
                    } else if catalog?.isEmpty == true {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("No se han podido cargar las preguntas.").font(.reading(.body, weight: .bold))
                            Button("Reintentar") { Task { await load() } }.buttonStyle(SecondaryButtonStyle())
                        }
                    }
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 300), spacing: 14)], spacing: 14) {
                        ForEach(QuizCategory.allCases, id: \.self) { category in
                            NavigationLink(value: category) {
                                CategoryCard(category: category, count: catalog.map { $0.counts[category] ?? 0 })
                            }
                            .buttonStyle(PressableStyle())
                            .accessibilityIdentifier("categories.card.\(category.urlSlug)")
                        }
                    }
                }
                .padding(20)
                .frame(maxWidth: 900)
                .frame(maxWidth: .infinity)
            }
            .foregroundStyle(Color.onGround)
            .background(Color.ground.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: QuizCategory.self) { category in
                CategoryDetailScreen(category: category, catalog: catalog)
            }
            .task { await load() }
        }
    }
}

extension CategoriesScreen {
    private func load() async {
        catalog = nil
        let questions = await env.questionBank.load().questions
        catalog = await Task.detached(priority: .userInitiated) { CategoryCatalog(questions: questions) }.value
    }
}

private struct CategoryCard: View {
    let category: QuizCategory
    /// nil while the questions load.
    let count: Int?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 3).fill(Color.category(category)).frame(width: 8).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 6) {
                Text(verbatim: copy(for: category).title).font(.display(.title3, weight: .heavy, italic: true))
                Text(verbatim: copy(for: category).blurb).font(.reading(.subheadline))
                if let count {
                    Text("\(count) preguntas en el juego").font(.reading(.footnote, weight: .bold)).foregroundStyle(Color.cardTextSoft)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: "chevron.right").foregroundStyle(Color.cardTextSoft).accessibilityHidden(true)
        }
        .padding(14)
        .foregroundStyle(Color.cardText)
        .background(Color.card, in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.papelBorde, lineWidth: 1))
        .multilineTextAlignment(.leading)
    }
}
