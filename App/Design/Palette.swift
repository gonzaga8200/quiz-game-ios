import SwiftUI
import UIKit

/// Colours of the web's design tokens (`app/assets/css/main.css`): a reading room at night, dark
/// walnut ground, parchment cards, brass and gold for the clock. Dark mode is the web's walnut;
/// light mode turns the ground into parchment with ink text. Cards stay parchment in both.
extension Color {
    // MARK: Fixed palette (same in both modes)

    static let nogal = Color(hex: 0x261811)
    static let nogalAlto = Color(hex: 0x3A2619)
    static let nogalBorde = Color(hex: 0x5C3F29)
    static let papel = Color(hex: 0xF3E6C8)
    static let papelOscuro = Color(hex: 0xE6D3A8)
    static let papelBorde = Color(hex: 0xC9AE7C)
    static let papelLinea = Color(hex: 0xD9C497)
    static let papelClaro = Color(hex: 0xFBF3DD)
    static let tinta = Color(hex: 0x2A1B10)
    static let tintaSuave = Color(hex: 0x5A4430)
    static let crema = Color(hex: 0xF3E6C8)
    static let cremaSuave = Color(hex: 0xCDB791)
    static let oro = Color(hex: 0xD9A93F)
    static let oroHover = Color(hex: 0xE8BC55)
    static let oroClaro = Color(hex: 0xF2CB6A)
    static let oroSombra = Color(hex: 0x8E6A1E)
    static let enlacePapel = Color(hex: 0x7A4A12)
    static let acierto = Color(hex: 0x1F6A3D)
    static let aciertoLinea = Color(hex: 0x3E8E57)
    static let aciertoTinte = Color(hex: 0xDCE9C9)
    static let fallo = Color(hex: 0xB3342B)
    static let falloTinte = Color(hex: 0xF2D3C6)
    static let falloVivo = Color(hex: 0xD9170C)
    static let falloVivoTinte = Color(hex: 0xF8C7BB)
    static let falloSuelo = Color(hex: 0xF29A8A)
    static let pasarClaro = Color(hex: 0xE9B35A)
    static let pasarClaroBorde = Color(hex: 0xB8741F)
    static let pasarOscuro = Color(hex: 0x9A410D)
    static let latonClaro = Color(hex: 0xF6DC92)
    static let laton = Color(hex: 0xC89B3C)
    static let latonOscuro = Color(hex: 0x7A5714)
    static let latonBorde = Color(hex: 0x5C3F10)
    static let aguja = Color(hex: 0x7C2A22)

    // MARK: Semantic colours (adapt to light and dark mode)

    /// Page background.
    static let ground = Color(light: .papel, dark: .nogal)
    /// Bars, the game HUD, sheets.
    static let groundRaised = Color(light: .papelOscuro, dark: .nogalAlto)
    static let groundBorder = Color(light: .papelBorde, dark: .nogalBorde)
    /// Text on the page background.
    static let onGround = Color(light: .tinta, dark: .crema)
    static let onGroundSoft = Color(light: .tintaSuave, dark: .cremaSuave)
    /// Titles and links on the page background (gold at night, brown ink by day).
    static let accentOnGround = Color(light: .enlacePapel, dark: .oroClaro)
    static let errorOnGround = Color(light: .fallo, dark: .falloSuelo)
    /// Parchment cards: slightly lighter than the parchment ground in light mode.
    static let card = Color(light: .papelClaro, dark: .papel)
    static let cardText = Color.tinta
    static let cardTextSoft = Color.tintaSuave

    // MARK: Categories and answers

    /// The bookmark colour of each category.
    static func category(_ category: QuizCategory) -> Color {
        switch category {
        case .artAndLiterature: Color(hex: 0x8E2F4A)
        case .historyAndGeography: Color(hex: 0x8A5530)
        case .sports: Color(hex: 0x66742A)
        case .filmAndTV: Color(hex: 0x6A4380)
        case .science: Color(hex: 0x2A6F7B)
        case .languages: Color(hex: 0x40508F)
        case .music: Color(hex: 0xB8501C)
        }
    }

    /// Answer slots A to D, each with the text colour that keeps 4.5:1.
    static func answer(_ index: Int) -> (fill: Color, text: Color) {
        switch index {
        case 0: (Color(hex: 0xC89B3C), .tinta)
        case 1: (Color(hex: 0x0C5A42), .papel)
        case 2: (Color(hex: 0x46687F), .papel)
        default: (Color(hex: 0xA64B3B), .papel)
        }
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }

    /// A colour that follows the light/dark appearance.
    init(light: Color, dark: Color) {
        let light = UIColor(light)
        let dark = UIColor(dark)
        self.init(uiColor: UIColor { $0.userInterfaceStyle == .dark ? dark : light })
    }
}
