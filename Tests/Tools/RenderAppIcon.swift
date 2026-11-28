import SwiftUI
import Testing
import UIKit
@testable import Contrarreloj

/// Draws the app icon from the game's own pocket watch. Not a regular test: it runs only when
/// RENDER_APP_ICON names an output folder (Tools/render-icon.sh passes it), and writes
/// icon-light.png, icon-dark.png and icon-tinted.png (1024 x 1024, opaque).
struct RenderAppIcon {
    nonisolated private static let output = ProcessInfo.processInfo.environment["RENDER_APP_ICON"]

    @Test(.enabled(if: RenderAppIcon.output != nil))
    func renderAppIcon() throws {
        let folder = URL(fileURLWithPath: try #require(Self.output))
        for variant in IconVariant.allCases {
            let renderer = ImageRenderer(content: AppIconArt(variant: variant))
            renderer.scale = 1
            renderer.isOpaque = true
            let image = try #require(renderer.uiImage)
            #expect(image.size == CGSize(width: 1024, height: 1024))
            try #require(image.pngData()).write(to: folder.appending(path: "icon-\(variant.rawValue).png"))
        }
    }
}

enum IconVariant: String, CaseIterable {
    case light, dark, tinted
}

/// The icon: the brass pocket watch, its time-left ring a third gone, on the walnut ground with the
/// web's lamp glow from above. Dark and tinted variants follow iOS 18's icon appearances.
struct AppIconArt: View {
    let variant: IconVariant

    var body: some View {
        ZStack {
            switch variant {
            case .light:
                Color.nogal
                RadialGradient(colors: [Color(red: 1, green: 0.72, blue: 0.38).opacity(0.35), .clear],
                               center: UnitPoint(x: 0.5, y: 0.02), startRadius: 0, endRadius: 760)
            case .dark:
                Color(hex: 0x120A06)
            case .tinted:
                Color.black
            }
            PocketWatch(progress: 0.3)
                .frame(width: 720, height: 836)
                .offset(y: 8)
                .grayscale(variant == .tinted ? 1 : 0)
        }
        .frame(width: 1024, height: 1024)
    }
}
