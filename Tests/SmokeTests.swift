import Foundation
import Testing
@testable import Contrarreloj

@Test func hostAppHasTheAppStoreBundleIdentifier() {
    #expect(Bundle.main.bundleIdentifier == "com.contrarrelojquiz.app")
}
