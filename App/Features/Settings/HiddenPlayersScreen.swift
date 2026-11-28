import SwiftUI

/// Players hidden from the ranking on this device, with a way to show them again.
struct HiddenPlayersScreen: View {
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        let players = env.hiddenPlayers.players.sorted { $0.value.localizedCompare($1.value) == .orderedAscending }
        List {
            if players.isEmpty {
                Text("No has ocultado a ningún jugador.").listRowBackground(Color.card)
            } else {
                ForEach(players, id: \.key) { uid, name in
                    HStack {
                        Text(verbatim: name.isEmpty ? String(localized: "Jugador") : name)
                        Spacer()
                        Button("Mostrar") { env.hiddenPlayers.unhide(uid) }
                            .foregroundStyle(Color.enlacePapel)
                    }
                    .listRowBackground(Color.card)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.ground.ignoresSafeArea())
        .foregroundStyle(Color.cardText)
        .font(.reading(.body))
        .navigationTitle("Jugadores ocultos")
        .navigationBarTitleDisplayMode(.inline)
    }
}
