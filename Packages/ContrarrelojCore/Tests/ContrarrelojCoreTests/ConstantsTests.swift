import Testing
@testable import ContrarrelojCore

@Test func pointsTableMatchesWeb() {
    #expect(Difficulty.allCases.map { Rules.pointsByDifficulty[$0] } == [3, 5, 7, 10, 15])
    #expect(Difficulty.allCases.map { Rules.wrongPenaltyByDifficulty[$0] } == [2, 1, 0, 0, 0])
    #expect(Rules.comboBonuses == [3: 2, 5: 4, 10: 8])
    #expect(Rules.freeSkips == 2)
    #expect(Rules.paidSkipPenalty == 1)
    #expect(Rules.maxPointsPerCorrect == 17)
    #expect(Rules.rankingSize == 50)
    #expect(Rules.maxSameInARow == 2)
    #expect(Rules.maxSameCategoryInARow == 1)
    #expect(Rules.optionsPerQuestion == 4)
    #expect(Rules.arcadeDuration == .short)
    #expect(Rules.arcadeFilter == .random)
}

@Test func namesAndOrderMatchWeb() {
    #expect(QuizCategory.allCases.map(\.rawValue) == [
        "Arte y Literatura", "Historia y Geografía", "Deportes", "Cine y televisión",
        "Ciencias", "Lengua e Idiomas", "Música",
    ])
    #expect(Difficulty.allCases.map(\.rawValue) == ["muy fácil", "fácil", "medio", "difícil", "muy difícil"])
    #expect(DifficultyFilter.allCases.map(\.rawValue) == ["Aleatorio", "Fácil", "Medio", "Difícil"])
    #expect(GameDuration.allCases.map(\.rawValue) == [60, 120])
}

@Test func slugsRoundTrip() {
    #expect(QuizCategory.allCases.map(\.urlSlug) == [
        "arte-y-literatura", "historia-y-geografia", "deportes", "cine-y-television",
        "ciencias", "lengua-e-idiomas", "musica",
    ])
    for category in QuizCategory.allCases {
        #expect(QuizCategory(urlSlug: category.urlSlug) == category)
    }
    #expect(QuizCategory(urlSlug: "trivial") == nil)
    #expect(QuizCategory(urlSlug: "Ciencias") == nil)
}

@Test func filtersLetThroughTheirDifficulties() {
    #expect(DifficultyFilter.random.difficulties == Difficulty.allCases)
    #expect(DifficultyFilter.easy.difficulties == [.veryEasy, .easy])
    #expect(DifficultyFilter.medium.difficulties == [.medium])
    #expect(DifficultyFilter.hard.difficulties == [.hard, .veryHard])
    #expect(DifficultyFilter.allCases.map(\.slug) == ["aleatorio", "facil", "medio", "dificil"])
}

@Test func difficultiesAreOrderedEasiestFirst() {
    #expect(Difficulty.veryEasy < .easy)
    #expect(Difficulty.hard < .veryHard)
    #expect(Difficulty.allCases.sorted() == Difficulty.allCases)
}

@Test func categoryChoiceMapsToItsCategory() {
    #expect(CategoryChoice.random.category == nil)
    #expect(CategoryChoice.only(.science).category == .science)
}
