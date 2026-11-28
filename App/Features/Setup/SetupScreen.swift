import SwiftUI

/// Competitive setup (the web's /competitivo): time, difficulty and category, with a recap of the
/// ranking the game counts for.
struct SetupScreen: View {
    let onStart: (GameSetup) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var duration: GameDuration = .short
    @State private var filter: DifficultyFilter = .random
    @State private var category: CategoryChoice = .random

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Modo competitivo")
                        .font(.display(.largeTitle, weight: .heavy, italic: true))
                        .foregroundStyle(Color.accentOnGround)
                        .accessibilityAddTraits(.isHeader)
                    Text("Tu puntuación entra en el ranking de la combinación de tiempo, dificultad y categoría que elijas.")
                        .font(.reading(.body))
                }

                section("Tiempo") {
                    HStack(spacing: 12) {
                        durationTile(.short)
                        durationTile(.long)
                    }
                }

                section("Dificultad") {
                    VStack(spacing: 10) {
                        filterRow(.random, hint: nil)
                        filterRow(.easy, hint: String(localized: "Muy fácil y fácil"))
                        filterRow(.medium, hint: String(localized: "Solo nivel medio"))
                        filterRow(.hard, hint: String(localized: "Difícil y muy difícil"))
                    }
                }

                section("Categoría") {
                    Grid(horizontalSpacing: 10, verticalSpacing: 10) {
                        GridRow { categoryTile(.random); categoryTile(.only(.artAndLiterature)) }
                        GridRow { categoryTile(.only(.historyAndGeography)); categoryTile(.only(.sports)) }
                        GridRow { categoryTile(.only(.filmAndTV)); categoryTile(.only(.science)) }
                        GridRow { categoryTile(.only(.languages)); categoryTile(.only(.music)) }
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Juegas por el ranking de").font(.reading(.subheadline)).foregroundStyle(Color.onGroundSoft)
                    Text(verbatim: describeBoard(duration, filter, category.category))
                        .font(.reading(.headline, weight: .bold))
                        .accessibilityIdentifier("setup.recap")
                }
                .padding(.leading, 12)
                .overlay(alignment: .leading) { Rectangle().fill(Color.oro).frame(width: 3) }

                VStack(spacing: 12) {
                    Button("Empezar partida") {
                        onStart(GameSetup(mode: .competitive, duration: duration, filter: filter, category: category.category))
                    }
                    .buttonStyle(PrimaryButtonStyle(large: true))
                    .accessibilityIdentifier("setup.start")
                    Button("Volver al menú") { dismiss() }.buttonStyle(SecondaryButtonStyle())
                }
            }
            .padding(20)
            .frame(maxWidth: 640)
            .frame(maxWidth: .infinity)
        }
        .foregroundStyle(Color.onGround)
        .background(Color.ground.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .trackScreen("Modo competitivo")
    }

    private func section(_ title: LocalizedStringKey, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.display(.title3, weight: .heavy, italic: true)).accessibilityAddTraits(.isHeader)
            content()
        }
    }

    private func durationTile(_ value: GameDuration) -> some View {
        ChoiceTile(title: "\(value.rawValue) s", hint: nil, selected: duration == value, ribbon: nil) { duration = value }
            .accessibilityIdentifier("setup.duration.\(value.rawValue)")
    }

    private func filterRow(_ value: DifficultyFilter, hint: String?) -> some View {
        ChoiceTile(title: value.rawValue, hint: hint, selected: filter == value, ribbon: nil) { filter = value }
            .accessibilityIdentifier("setup.filter.\(value.slug)")
    }

    private func categoryTile(_ value: CategoryChoice) -> some View {
        let title = value.category?.rawValue ?? String(localized: "Aleatorio")
        return ChoiceTile(title: title, hint: nil, selected: category == value, ribbon: value.category.map { Color.category($0) } ?? .oro) {
            category = value
        }
        .accessibilityIdentifier("setup.category.\(value.category?.urlSlug ?? "aleatorio")")
    }
}

/// A selectable tile: parchment with a gold ring and a check when chosen.
struct ChoiceTile: View {
    let title: String
    let hint: String?
    let selected: Bool
    let ribbon: Color?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let ribbon {
                    RoundedRectangle(cornerRadius: 2).fill(ribbon).frame(width: 6).accessibilityHidden(true)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: title).font(.reading(.body, weight: .bold))
                    if let hint { Text(verbatim: hint).font(.reading(.footnote)).foregroundStyle(Color.cardTextSoft) }
                }
                Spacer(minLength: 4)
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selected ? Color.acierto : Color.cardTextSoft)
                    .accessibilityHidden(true)
            }
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
            .foregroundStyle(Color.cardText)
            .background(Color.card, in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(selected ? Color.oro : Color.papelBorde, lineWidth: selected ? 3 : 1))
        }
        .buttonStyle(PressableStyle())
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
