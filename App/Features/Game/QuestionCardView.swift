import SwiftUI

/// The parchment question card (the web's QuestionCard): category bookmark and tags, difficulty
/// pips, the question, the four answers and a one-line summary after answering.
struct QuestionCardView: View {
    let question: PlayableQuestion
    let feedback: AnswerFeedback?
    let onAnswer: (Int) -> Void
    var fillHeight = true
    @AccessibilityFocusState.Binding var questionFocused: Bool
    @Environment(\.dynamicTypeSize) private var typeSize

    private var level: Int { (Difficulty.allCases.firstIndex(of: question.difficulty) ?? 0) + 1 }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if typeSize.isAccessibilitySize {
                // Largest text sizes: one tag per line, clear of the bookmark.
                VStack(alignment: .leading, spacing: 6) {
                    categoryTag
                    difficultyTag
                }
                .padding(.trailing, 40)
            } else {
                HStack(spacing: 8) {
                    categoryTag
                    difficultyTag
                    Spacer(minLength: 0)
                }
            }

            Spacer(minLength: 0).frame(maxHeight: fillHeight ? .infinity : 0)

            ZStack(alignment: .top) {
                Text(verbatim: question.text)
                    .font(.question(.title2))
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.top, feedback?.correct == false ? 30 : 0)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("question.text")
                    .accessibilityFocused($questionFocused)
                if let feedback, !feedback.correct {
                    stamp(penalty: feedback.penalty)
                }
            }
            .layoutPriority(1)

            Spacer(minLength: 0).frame(maxHeight: fillHeight ? .infinity : 0)

            Rectangle().fill(Color.tinta.opacity(0.25)).frame(height: 1).accessibilityHidden(true)

            VStack(spacing: 8) {
                answer(0)
                answer(1)
                answer(2)
                answer(3)
            }

            Text(verbatim: summary.isEmpty ? " " : summary)
                .font(.reading(.body, weight: .bold))
                .foregroundStyle(feedback?.correct == true ? Color.acierto : Color.fallo)
                .frame(maxWidth: .infinity)
                .opacity(summary.isEmpty ? 0 : 1)
                .accessibilityHidden(summary.isEmpty)
                .accessibilityIdentifier(summary.isEmpty ? "" : "card.summary")
        }
        .padding(16)
        .foregroundStyle(Color.cardText)
        // The shadow goes on the paper only: on the whole card it would blur every glyph.
        .background(RoundedRectangle(cornerRadius: 10).fill(tint).shadow(color: .black.opacity(0.35), radius: 10, y: 6))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(feedback.map { $0.correct && $0.bonus > 0 } == true ? Color.oro : Color.tinta,
                                                                 lineWidth: feedback.map { $0.correct && $0.bonus > 0 } == true ? 4 : 2))
        .overlay(alignment: .topTrailing) {
            // The bookmark: its colour tells the category at a glance; the name is in the tag.
            Rectangle().fill(Color.category(question.category)).frame(width: 18, height: 34)
                .mask(BookmarkShape())
                .padding(.trailing, 18)
                .accessibilityHidden(true)
        }
    }

    private var categoryTag: some View {
        tag(Text(verbatim: question.category.rawValue).accessibilityIdentifier("question.category"))
    }

    private var difficultyTag: some View {
        tag(HStack(spacing: 6) {
            DifficultyPips(level: level)
                .frame(width: 42, height: 6)
                .accessibilityHidden(true)
            Text(verbatim: question.difficulty.rawValue)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Dificultad: \(question.difficulty.rawValue)")))
    }

    /// One answer slot, written out instead of a `ForEach` (see GameScreen.scrolls).
    @ViewBuilder private func answer(_ index: Int) -> some View {
        if question.options.indices.contains(index) {
            AnswerButton(index: index, text: question.options[index], state: state(of: index),
                         locked: feedback != nil, action: { onAnswer(index) })
        }
    }

    private var tint: Color {
        guard let feedback else { return .card }
        return feedback.correct ? .aciertoTinte : .falloTinte
    }

    private func state(of index: Int) -> OptionState {
        guard let feedback else { return .idle }
        if index == feedback.chosenIndex { return feedback.correct ? .correct : .wrong }
        if index == feedback.correctIndex { return .revealed }
        return .idle
    }

    private var summary: String {
        guard let feedback else { return "" }
        if feedback.correct {
            return feedback.bonus > 0
                ? String(localized: "¡Correcto! \(formatSigned(feedback.points)) y \(formatSigned(feedback.bonus)) de racha")
                : String(localized: "¡Correcto! \(formatSigned(feedback.points))")
        }
        return feedback.penalty > 0 ? String(localized: "Incorrecto \(formatSigned(-feedback.penalty))") : String(localized: "Incorrecto")
    }

    private func tag(_ content: some View) -> some View {
        content
            .font(.reading(.footnote, weight: .bold))
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.papelOscuro, in: Capsule())
            .overlay(Capsule().strokeBorder(Color.papelBorde, lineWidth: 1))
    }

    private func stamp(penalty: Int) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "xmark").font(.headline.weight(.black)).accessibilityHidden(true)
            Text("¡Fallo!")
            if penalty > 0 {
                Text(verbatim: formatSigned(-penalty)).accessibilityHidden(true)
            }
        }
        .font(.display(.title3, weight: .heavy, italic: true))
        .foregroundStyle(Color.falloVivo)
        .padding(.horizontal, 10)
        .padding(.vertical, 2)
        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Color.falloVivo, lineWidth: 2.5))
        .rotationEffect(.degrees(-4))
    }
}

/// Five dots, the first `level` filled: the difficulty at a glance (drawn as one shape).
private struct DifficultyPips: View {
    let level: Int

    var body: some View {
        ZStack {
            PipsShape(range: 0..<level).fill(Color.tinta)
            PipsShape(range: level..<5).fill(Color.tinta.opacity(0.2))
        }
    }
}

private struct PipsShape: Shape {
    let range: Range<Int>

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let size = rect.height
        let gap = (rect.width - size * 5) / 4
        for i in range {
            path.addEllipse(in: CGRect(x: rect.minX + CGFloat(i) * (size + gap), y: rect.minY, width: size, height: size))
        }
        return path
    }
}

private struct BookmarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: .zero)
        path.addLine(to: CGPoint(x: rect.maxX, y: 0))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY - rect.width / 2))
        path.addLine(to: CGPoint(x: 0, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
