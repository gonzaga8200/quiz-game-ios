import SwiftUI

/// Position of each entry (sorted by points, best first): players with more points + 1, so ties
/// share a position, the same rule as the report's "puesto".
func rankingPositions(_ entries: [RankingEntry]) -> [Int] {
    var positions: [Int] = []
    positions.reserveCapacity(entries.count)
    for (index, entry) in entries.enumerated() {
        if index > 0, entries[index - 1].points == entry.points {
            positions.append(positions[index - 1])
        } else {
            positions.append(index + 1)
        }
    }
    return positions
}

/// One player on a board (the web's RankingList row) with report / hide for other players.
struct RankingRow: View {
    let entry: RankingEntry
    let position: Int
    let isMe: Bool
    let onReport: () -> Void
    let onHide: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            HStack(spacing: 12) {
                Text(verbatim: "\(position)")
                    .font(.display(.title3, weight: .heavy, italic: true))
                    .monospacedDigit()
                    .frame(minWidth: 40, minHeight: 36)
                    .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(Color.tinta, lineWidth: 2))
                Avatar(url: entry.photoURL.flatMap(URL.init(string:)), name: entry.displayName, size: 40)
                VStack(alignment: .leading, spacing: 0) {
                    Text(verbatim: entry.displayName).font(.reading(.body, weight: .bold)).lineLimit(2)
                    if isMe { Text("(tú)").font(.reading(.footnote, weight: .bold)).foregroundStyle(Color.enlacePapel) }
                }
                Spacer(minLength: 4)
                Text(verbatim: "\(entry.points)").font(.display(.title2, weight: .heavy)).monospacedDigit()
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(verbatim: accessibilityText))
            .accessibilityIdentifier("ranking.row.\(entry.uid)")

            if !isMe {
                Menu {
                    Button("Reportar jugador", systemImage: "flag", action: onReport)
                    Button("Ocultar jugador", systemImage: "eye.slash", role: .destructive, action: onHide)
                } label: {
                    Image(systemName: "ellipsis.circle").font(.title3).frame(width: 44, height: 44)
                }
                .foregroundStyle(Color.cardTextSoft)
                .accessibilityLabel(Text("Opciones de \(entry.displayName)"))
                .accessibilityIdentifier("ranking.more.\(entry.uid)")
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .foregroundStyle(Color.cardText)
        .background(isMe ? Color.oroClaro.opacity(0.55) : Color.card, in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(isMe ? Color.oro : Color.papelBorde, lineWidth: isMe ? 2 : 1))
    }

    private var accessibilityText: String {
        let name = isMe ? "\(entry.displayName) " + String(localized: "(tú)") : entry.displayName
        return String(localized: "Puesto \(position): \(name), \(pointsText(entry.points))")
    }
}
