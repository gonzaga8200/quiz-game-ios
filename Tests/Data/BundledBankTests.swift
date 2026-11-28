import Testing
@testable import Contrarreloj

struct BundledBankTests {
    @Test func bundledBankIsValid() {
        let questions = BundledQuestions.all
        #expect(questions.count > 2_000)
        #expect(questions.allSatisfy { Question.validated($0) != nil })
        #expect(Set(questions.map(\.category)) == Set(QuizCategory.allCases))
    }
}
