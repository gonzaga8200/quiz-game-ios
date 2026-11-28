import CoreText
import Testing
import UIKit
@testable import Contrarreloj

nonisolated private let bundledFonts = [
    "PlayfairDisplay-Bold", "PlayfairDisplay-ExtraBold", "PlayfairDisplay-BoldItalic", "PlayfairDisplay-ExtraBoldItalic",
    "AtkinsonHyperlegibleNext-Regular", "AtkinsonHyperlegibleNext-Bold",
    "AtkinsonHyperlegibleNext-Italic", "AtkinsonHyperlegibleNext-BoldItalic",
]

struct FontTests {
    @Test(arguments: bundledFonts)
    func fontIsRegisteredAndCoversSpanish(_ name: String) throws {
        let font = try #require(UIFont(name: name, size: 17), "\(name) is not registered (UIAppFonts)")
        let sample = Array("¿¡áéíóúüñÁÉÍÓÚÜÑ€«»—·0123456789".utf16)
        var glyphs = [CGGlyph](repeating: 0, count: sample.count)
        #expect(CTFontGetGlyphsForCharacters(font as CTFont, sample, &glyphs, sample.count), "\(name) misses Spanish glyphs")
    }

    @Test func typographyUsesTheBundledFaces() {
        #expect(AppTypeface.display(weight: .heavy, italic: true) == "PlayfairDisplay-ExtraBoldItalic")
        #expect(AppTypeface.display(weight: .bold, italic: false) == "PlayfairDisplay-Bold")
        #expect(AppTypeface.reading(weight: .regular, italic: false) == "AtkinsonHyperlegibleNext-Regular")
        #expect(AppTypeface.reading(weight: .bold, italic: true) == "AtkinsonHyperlegibleNext-BoldItalic")
    }
}
