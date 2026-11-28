import SwiftUI

/// The "Ranking" tab (the web's /ranking): the top 50 of each time × difficulty × category board.
struct RankingScreen: View {
    private enum Status: Equatable {
        case loading, ready, empty, error, unavailable
    }

    @Environment(AppEnvironment.self) private var env
    @State private var duration: GameDuration = .short
    @State private var filter: DifficultyFilter = .random
    @State private var category: CategoryChoice = .random
    @State private var status: Status = .loading
    @State private var entries: [RankingEntry] = []

    private var board: String { boardId(duration, filter, category.category) }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Ranking").font(.display(.largeTitle, weight: .heavy, italic: true))
                            .foregroundStyle(Color.accentOnGround).accessibilityAddTraits(.isHeader)
                        Text("Las 50 mejores puntuaciones de cada combinación de tiempo, dificultad y categoría.")
                            .font(.reading(.body))
                    }
                    RankingFiltersView(duration: $duration, filter: $filter, category: $category)
                    if !env.connectivity.isOnline {
                        Label("Sin conexión: puede que el ranking no esté al día.", systemImage: "wifi.slash")
                            .font(.reading(.subheadline, weight: .bold))
                            .foregroundStyle(Color.errorOnGround)
                    }
                    Text(verbatim: describeBoard(duration, filter, category.category))
                        .font(.display(.title2, weight: .heavy, italic: true))
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityIdentifier("ranking.heading")
                    content
                }
                .padding(20)
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
            }
            .refreshable { await load(force: true) }
            StatusBarBackdrop()
        }
        .task(id: board) { await load(force: false) }
    }

    @ViewBuilder private var content: some View {
        switch status {
        case .loading:
            ProgressView { Text("Cargando el ranking…") }.frame(maxWidth: .infinity, minHeight: 160)
        case .unavailable:
            Text("El ranking no está disponible en este momento.").font(.reading(.body))
        case .error:
            PaperCard {
                Text("No se ha podido cargar el ranking.").font(.reading(.body, weight: .bold))
                Button("Reintentar") { Task { await load(force: true) } }.buttonStyle(SecondaryButtonStyle())
            }
        case .empty:
            Text("Todavía no hay puntuaciones aquí. Juega en modo competitivo para ser el primero.").font(.reading(.body))
        case .ready:
            let positions = rankingPositions(entries)
            let me = env.auth.user?.uid
            LazyVStack(spacing: 8) {
                ForEach(Array(entries.enumerated()), id: \.element.uid) { index, entry in
                    if !env.hiddenPlayers.uids.contains(entry.uid) {
                        RankingRow(
                            entry: entry, position: positions[index], isMe: entry.uid == me,
                            onReport: {
                                Task { _ = await env.mail.compose(playerReportDraft(board: board, uid: entry.uid, name: entry.displayName)) }
                            },
                            onHide: { env.hiddenPlayers.hide(entry.uid, name: entry.displayName) }
                        )
                    }
                }
            }
        }
    }

    private func load(force: Bool) async {
        guard let ranking = env.ranking else {
            status = .unavailable
            return
        }
        let requested = board
        if entries.isEmpty || force { status = .loading }
        do {
            let top = try await ranking.top(board: requested, forceRefresh: force)
            guard requested == board else { return } // the player already moved to another board
            entries = top
            status = top.isEmpty ? .empty : .ready
        } catch {
            if requested == board { status = .error }
        }
    }
}
