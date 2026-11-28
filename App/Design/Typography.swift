import SwiftUI

/// The bundled typefaces (OFL), all scaling with Dynamic Type through `relativeTo:`: the web's
/// Playfair Display for titles and numbers and Atkinson Hyperlegible Next for reading, plus
/// Newsreader Display for the question on the card.
nonisolated enum AppTypeface {
    /// Newsreader at its display optical size (72) and weight 600, cut to a static font. It
    /// replaces Playfair's italic on the card, whose capital Q reads as a "2".
    static let question = "NewsreaderDisplay-SemiBold"

    static func display(weight: Font.Weight, italic: Bool) -> String {
        let heavy = weight == .heavy || weight == .black
        switch (heavy, italic) {
        case (true, true): return "PlayfairDisplay-ExtraBoldItalic"
        case (true, false): return "PlayfairDisplay-ExtraBold"
        case (false, true): return "PlayfairDisplay-BoldItalic"
        case (false, false): return "PlayfairDisplay-Bold"
        }
    }

    static func reading(weight: Font.Weight, italic: Bool) -> String {
        let bold = [Font.Weight.semibold, .bold, .heavy, .black].contains(weight)
        switch (bold, italic) {
        case (true, true): return "AtkinsonHyperlegibleNext-BoldItalic"
        case (true, false): return "AtkinsonHyperlegibleNext-Bold"
        case (false, true): return "AtkinsonHyperlegibleNext-Italic"
        case (false, false): return "AtkinsonHyperlegibleNext-Regular"
        }
    }

    /// Default point size of each text style at the standard ("Large") content size.
    static func baseSize(_ style: Font.TextStyle) -> CGFloat {
        switch style {
        case .largeTitle: 34
        case .title: 28
        case .title2: 22
        case .title3: 20
        case .headline, .body: 17
        case .callout: 16
        case .subheadline: 15
        case .footnote: 13
        case .caption: 12
        case .caption2: 11
        default: 17
        }
    }
}

extension Font {
    /// Titles, the clock digits and big numbers (Playfair Display).
    static func display(_ style: Font.TextStyle, weight: Font.Weight = .bold, italic: Bool = false) -> Font {
        .custom(AppTypeface.display(weight: weight, italic: italic), size: AppTypeface.baseSize(style), relativeTo: style)
    }

    /// Display face at an explicit size that still scales with Dynamic Type.
    static func display(size: CGFloat, relativeTo style: Font.TextStyle, weight: Font.Weight = .bold, italic: Bool = false) -> Font {
        .custom(AppTypeface.display(weight: weight, italic: italic), size: size, relativeTo: style)
    }

    /// Body text, buttons and labels (Atkinson Hyperlegible Next).
    static func reading(_ style: Font.TextStyle, weight: Font.Weight = .regular, italic: Bool = false) -> Font {
        .custom(AppTypeface.reading(weight: weight, italic: italic), size: AppTypeface.baseSize(style), relativeTo: style)
    }

    /// The question on the card (Newsreader Display). Its x-height is smaller than Playfair's, so
    /// it is set a little larger than the style's default to read at the same size.
    static func question(_ style: Font.TextStyle) -> Font {
        .custom(AppTypeface.question, size: AppTypeface.baseSize(style) * 1.14, relativeTo: style)
    }
}
