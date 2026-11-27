import SwiftUI

// Temporary screens of the shell (Task 14), replaced one by one in Tasks 15 to 20.

struct GamePlaceholder: View {
    let session: GameSession
    var body: some View {
        VStack(spacing: 12) {
            Text(session.question?.text ?? "")
            ForEach(Array((session.question?.options ?? []).enumerated()), id: \.offset) { index, option in
                Button(option) { session.answer(index) }.buttonStyle(SecondaryButtonStyle())
            }
        }
        .padding()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("game.screen")
    }
}

struct ReportPlaceholder: View {
    @Environment(AppEnvironment.self) private var env
    let report: GameReport
    var body: some View {
        VStack(spacing: 12) {
            Text(verbatim: "\(report.points)")
            Button("Jugar de nuevo") { env.play.playAgain() }.buttonStyle(PrimaryButtonStyle())
            Button("Volver al menú") { env.play.close() }.buttonStyle(SecondaryButtonStyle())
        }
        .padding()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("report.screen")
    }
}

struct HomePlaceholder: View {
    @Environment(AppEnvironment.self) private var env
    var body: some View {
        VStack(spacing: 16) {
            Text(verbatim: "Contrarreloj").font(.display(.largeTitle, weight: .heavy, italic: true))
            Button("Jugar arcade") { env.play.play(.arcade()) }
                .buttonStyle(PrimaryButtonStyle(large: true))
                .accessibilityIdentifier("home.playArcade")
        }
        .padding()
    }
}

struct TabPlaceholder: View {
    let title: LocalizedStringKey
    var body: some View {
        Text(title).font(.display(.title, weight: .heavy, italic: true))
    }
}
