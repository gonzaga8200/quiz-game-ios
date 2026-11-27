import Testing
@testable import Contrarreloj

struct CategoryCopyTests {
    @Test func everyCategoryHasCopy() {
        for category in QuizCategory.allCases {
            let copy = copy(for: category)
            #expect(!copy.title.isEmpty && !copy.heading.isEmpty && !copy.blurb.isEmpty, "\(category)")
            #expect(copy.intro.count == 2, "\(category)")
        }
        #expect(copy(for: .sports).blurb == "Juegos Olímpicos, Mundiales de fútbol, Tour de Francia, La Liga y motociclismo.")
        #expect(hubCopy.heading == "Preguntas de cultura general con respuestas")
        #expect(hubCopy.intro.count == 2)
    }
}
