import SwiftUI

/// Where a competitive game left the player in the ranking (the web's RankingResult).
struct RankingResultView: View {
    let state: SubmissionState
    let board: String
    let onRetry: () -> Void

    var body: some View {
        PaperCard {
            Text("Ranking").font(.display(.title2, weight: .heavy, italic: true)).accessibilityAddTraits(.isHeader)
            switch state {
            case .done(.newBest(_, let position)), .done(.kept(_, let position)):
                HStack(spacing: 14) {
                    Text(verbatim: "\(position)")
                        .font(.display(.largeTitle, weight: .heavy, italic: true))
                        .monospacedDigit()
                        .frame(minWidth: 64, minHeight: 56)
                        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Color.tinta, lineWidth: 3))
                        .accessibilityHidden(true)
                    Text(verbatim: rankingResultText(state, board: board)).font(.reading(.body))
                }
            case .error:
                Text(verbatim: rankingResultText(state, board: board)).font(.reading(.body, weight: .bold))
                Button("Reintentar", action: onRetry).buttonStyle(SecondaryButtonStyle())
            default:
                Text(verbatim: rankingResultText(state, board: board)).font(.reading(.body))
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("report.ranking")
    }
}
