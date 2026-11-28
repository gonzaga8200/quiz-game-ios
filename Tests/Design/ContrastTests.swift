import SwiftUI
import Testing
import UIKit
@testable import Contrarreloj

/// WCAG 2 relative luminance of a colour resolved in a light or dark trait collection.
private func luminance(_ color: Color, _ style: UIUserInterfaceStyle) -> Double {
    let resolved = UIColor(color).resolvedColor(with: UITraitCollection(userInterfaceStyle: style))
    var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
    resolved.getRed(&r, green: &g, blue: &b, alpha: &a)
    func channel(_ c: CGFloat) -> Double {
        let c = Double(c)
        return c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
    }
    return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b)
}

private func contrast(_ text: Color, on background: Color, _ style: UIUserInterfaceStyle) -> Double {
    let (a, b) = (luminance(text, style), luminance(background, style))
    return (max(a, b) + 0.05) / (min(a, b) + 0.05)
}

private let textPairs: [(name: String, text: Color, background: Color)] = [
    ("text on ground", .onGround, .ground),
    ("soft text on ground", .onGroundSoft, .ground),
    ("accent on ground", .accentOnGround, .ground),
    ("error on ground", .errorOnGround, .ground),
    ("text on raised ground", .onGround, .groundRaised),
    ("text on card", .cardText, .card),
    ("soft text on card", .cardTextSoft, .card),
    ("tinta on papel", .tinta, .papel),
    ("primary button", .tinta, .oro),
    ("secondary button", .tinta, .papel),
    ("answer A", Color.answer(0).text, Color.answer(0).fill),
    ("answer B", Color.answer(1).text, Color.answer(1).fill),
    ("answer C", Color.answer(2).text, Color.answer(2).fill),
    ("answer D", Color.answer(3).text, Color.answer(3).fill),
    ("paid skip", .papel, .pasarOscuro),
    ("free skip", .tinta, .pasarClaro),
]

struct ContrastTests {
    @Test(arguments: [UIUserInterfaceStyle.light, .dark])
    func textPairsMeetAA(_ style: UIUserInterfaceStyle) {
        for pair in textPairs {
            let ratio = contrast(pair.text, on: pair.background, style)
            #expect(ratio >= 4.5, "\(pair.name) in \(style == .dark ? "dark" : "light"): \(ratio)")
        }
    }

    @Test func darkModeIsTheWebWalnutAndLightModeIsParchment() {
        #expect(luminance(.ground, .dark) == luminance(.nogal, .dark))
        #expect(luminance(.ground, .light) == luminance(.papel, .light))
    }

    @Test func everyCategoryAndAnswerHasAColour() {
        #expect(Set(QuizCategory.allCases.map { UIColor(Color.category($0)).description }).count == 7)
        #expect(Set((0..<4).map { UIColor(Color.answer($0).fill).description }).count == 4)
    }
}
