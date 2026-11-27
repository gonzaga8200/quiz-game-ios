import SwiftUI

// Temporary screens of the shell (Task 14), replaced one by one in Tasks 15 to 20.

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
