import SwiftUI

/// Time and difficulty as segmented controls, category as a menu (the web's RankingFilters).
struct RankingFiltersView: View {
    @Binding var duration: GameDuration
    @Binding var filter: DifficultyFilter
    @Binding var category: CategoryChoice

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Tiempo", selection: $duration) {
                Text("60 s").tag(GameDuration.short)
                Text("120 s").tag(GameDuration.long)
            }
            .pickerStyle(.segmented)

            Picker("Dificultad", selection: $filter) {
                Text("Aleatorio").tag(DifficultyFilter.random)
                Text("Fácil").tag(DifficultyFilter.easy)
                Text("Medio").tag(DifficultyFilter.medium)
                Text("Difícil").tag(DifficultyFilter.hard)
            }
            .pickerStyle(.segmented)

            HStack {
                Text("Categoría").font(.reading(.body, weight: .bold))
                Spacer()
                Picker("Categoría", selection: $category) {
                    Text("Aleatorio").tag(CategoryChoice.random)
                    Text(verbatim: QuizCategory.artAndLiterature.rawValue).tag(CategoryChoice.only(.artAndLiterature))
                    Text(verbatim: QuizCategory.historyAndGeography.rawValue).tag(CategoryChoice.only(.historyAndGeography))
                    Text(verbatim: QuizCategory.sports.rawValue).tag(CategoryChoice.only(.sports))
                    Text(verbatim: QuizCategory.filmAndTV.rawValue).tag(CategoryChoice.only(.filmAndTV))
                    Text(verbatim: QuizCategory.science.rawValue).tag(CategoryChoice.only(.science))
                    Text(verbatim: QuizCategory.languages.rawValue).tag(CategoryChoice.only(.languages))
                    Text(verbatim: QuizCategory.music.rawValue).tag(CategoryChoice.only(.music))
                }
                .pickerStyle(.menu)
                .tint(Color.accentOnGround)
                .accessibilityIdentifier("ranking.category")
            }
        }
    }
}
