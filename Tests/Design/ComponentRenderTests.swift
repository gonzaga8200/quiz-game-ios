import SwiftUI
import Testing
@testable import Contrarreloj

struct ComponentRenderTests {
    private func render(_ view: some View, width: CGFloat, height: CGFloat) -> UIImage? {
        let renderer = ImageRenderer(content: view.frame(width: width, height: height))
        renderer.scale = 2
        return renderer.uiImage
    }

    @Test func pocketWatchRendersAtHeroAndBarSizes() throws {
        let hero = try #require(render(PocketWatch(progress: 0.3), width: 200, height: 232))
        #expect(hero.size == CGSize(width: 200, height: 232))
        let bar = try #require(render(PocketWatch(progress: 0.9, urgent: true), width: 56, height: 65))
        #expect(bar.size.width == 56)
    }

    @Test func buttonsAndCardRender() throws {
        let view = VStack {
            Button("Jugar arcade") {}.buttonStyle(PrimaryButtonStyle(large: true))
            Button("Volver al menú") {}.buttonStyle(SecondaryButtonStyle())
            PaperCard { Text(verbatim: "Respuestas") }
        }
        #expect(render(view, width: 320, height: 300) != nil)
    }

    @Test func watchGeometryMatchesTheWebSVG() {
        #expect(PocketWatchGeometry.viewBox == CGSize(width: 200, height: 232))
        #expect(PocketWatchGeometry.center == CGPoint(x: 100, y: 132))
        #expect(PocketWatchGeometry.numerals.count == 12)
        #expect(PocketWatchGeometry.numerals.first == "XII")
        #expect(PocketWatchGeometry.numerals[4] == "IIII")
        // The time-left ring empties as the game goes: full at the start, gone at the end.
        #expect(PocketWatchGeometry.remainingSweep(progress: 0) == 360)
        #expect(PocketWatchGeometry.remainingSweep(progress: 0.25) == 270)
        #expect(PocketWatchGeometry.remainingSweep(progress: 1.5) == 0)
    }
}
