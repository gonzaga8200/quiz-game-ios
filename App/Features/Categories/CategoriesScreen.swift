import SwiftUI

/// The "Categorías" tab (the web's /preguntas): one card per category with its blurb and how many
/// questions it has, and a game with every category mixed.
struct CategoriesScreen: View {
    @Environment(AppEnvironment.self) private var env
    @State private var questions: [Question] = []

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
                    let counts = countActiveByCategory(questions)
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 300), spacing: 14)], spacing: 14) {
                        ForEach(QuizCategory.allCases, id: \.self) { category in
                            NavigationLink(value: category) {
                                CategoryCard(category: category, count: counts[category] ?? 0)
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
                CategoryDetailScreen(category: category, questions: questions)
            }
            .task { questions = await env.questionBank.load().questions }
        }
    }
}

private struct CategoryCard: View {
    let category: QuizCategory
    let count: Int

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 3).fill(Color.category(category)).frame(width: 8).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 6) {
                Text(verbatim: copy(for: category).title).font(.display(.title3, weight: .heavy, italic: true))
                Text(verbatim: copy(for: category).blurb).font(.reading(.subheadline))
                Text("\(count) preguntas en el juego").font(.reading(.footnote, weight: .bold)).foregroundStyle(Color.cardTextSoft)
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
