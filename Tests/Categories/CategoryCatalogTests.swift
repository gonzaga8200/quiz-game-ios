import Testing
@testable import Contrarreloj

/// The categories tab works out counts and showcases once per load, not on every redraw.
struct CategoryCatalogTests {
    @Test func catalogMatchesTheCoreSelection() {
        let bank = BundledQuestions.all
        let catalog = CategoryCatalog(questions: bank)
        #expect(catalog.counts == countActiveByCategory(bank))
        for category in QuizCategory.allCases {
            #expect(catalog.showcase(for: category).map(\.id) == pickShowcase(bank, category: category, count: 20).map(\.id),
                    "\(category)")
        }
    }

    @Test func emptyBankHasNothingToShow() {
        let catalog = CategoryCatalog(questions: [])
        #expect(catalog.isEmpty)
        #expect(catalog.counts.values.allSatisfy { $0 == 0 })
        #expect(catalog.showcase(for: .science).isEmpty)
        #expect(!CategoryCatalog(questions: BundledQuestions.all).isEmpty)
    }
}
