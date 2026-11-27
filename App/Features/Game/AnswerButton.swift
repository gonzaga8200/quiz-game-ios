import SwiftUI

nonisolated enum OptionState: Equatable, Sendable {
    case idle, correct, wrong, revealed
}

/// One answer slot (the web's AnswerOption): a fixed colour per letter; the state adds a solid
/// ring and a tick (right), a dashed ring and a cross (wrong); the others fade. Never colour alone.
struct AnswerButton: View {
    let index: Int
    let text: String
    let state: OptionState
    let locked: Bool
    let action: () -> Void

    private static let letters = ["A", "B", "C", "D"]
    private var letter: String { Self.letters[index] }

    var body: some View {
        let colors = Color.answer(index)
        Button {
            if !locked { action() }
        } label: {
            HStack(spacing: 12) {
                mark
                Text(verbatim: text)
                    .font(.reading(.body, weight: .bold))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 8)
            .padding(.leading, 8)
            .padding(.trailing, 12)
            .frame(minHeight: 52)
            .foregroundStyle(colors.text)
            .background(colors.fill, in: RoundedRectangle(cornerRadius: 8))
            .overlay(border)
            .opacity(locked && state == .idle ? 0.45 : 1)
            .contentShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel(Text(accessibilityText))
        .accessibilityIdentifier("answer.\(index)")
    }

    private var accessibilityText: String {
        let base = String(localized: "Respuesta \(letter): \(text)")
        switch state {
        case .idle: return base
        case .correct: return base + ". " + String(localized: "Respuesta correcta")
        case .wrong: return base + ". " + String(localized: "Respuesta incorrecta")
        case .revealed: return base + ". " + String(localized: "Esta era la respuesta correcta")
        }
    }

    @ViewBuilder private var mark: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6).fill(state == .idle ? Color.tinta : Color.papel)
            switch state {
            case .correct, .revealed:
                Image(systemName: "checkmark").font(.body.weight(.black)).foregroundStyle(Color.acierto)
            case .wrong:
                Image(systemName: "xmark").font(.body.weight(.black)).foregroundStyle(Color.falloVivo)
            case .idle:
                Text(verbatim: letter).font(.display(.headline, weight: .heavy)).foregroundStyle(Color.papel)
            }
        }
        .frame(width: 36, height: 36)
        .accessibilityHidden(true)
    }

    @ViewBuilder private var border: some View {
        switch state {
        case .correct, .revealed:
            RoundedRectangle(cornerRadius: 8).strokeBorder(Color.papel, lineWidth: 3)
                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.tinta, lineWidth: 1).padding(3))
        case .wrong:
            RoundedRectangle(cornerRadius: 8).strokeBorder(Color.papel, style: StrokeStyle(lineWidth: 3, dash: [6, 4]))
        case .idle:
            RoundedRectangle(cornerRadius: 8).strokeBorder(Color.black.opacity(0.28), lineWidth: 3)
        }
    }
}

/// Presses sink by a point, like the web's buttons.
struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.offset(y: configuration.isPressed ? 1 : 0)
    }
}
