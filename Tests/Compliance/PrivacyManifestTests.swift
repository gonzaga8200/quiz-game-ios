import Foundation
import Testing
@testable import Contrarreloj

struct PrivacyManifestTests {
    private func manifest() throws -> [String: Any] {
        let url = try #require(Bundle.main.url(forResource: "PrivacyInfo", withExtension: "xcprivacy"))
        let plist = try PropertyListSerialization.propertyList(from: Data(contentsOf: url), format: nil)
        return try #require(plist as? [String: Any])
    }

    @Test func privacyManifestDeclaresNoTrackingAndUserDefaults() throws {
        let m = try manifest()
        #expect(m["NSPrivacyTracking"] as? Bool == false)
        #expect((m["NSPrivacyTrackingDomains"] as? [String])?.isEmpty == true)

        let apis = m["NSPrivacyAccessedAPITypes"] as? [[String: Any]] ?? []
        let defaults = apis.first { $0["NSPrivacyAccessedAPIType"] as? String == "NSPrivacyAccessedAPICategoryUserDefaults" }
        #expect(defaults?["NSPrivacyAccessedAPITypeReasons"] as? [String] == ["CA92.1"])

        let collected = m["NSPrivacyCollectedDataTypes"] as? [[String: Any]] ?? []
        func entry(_ type: String) -> [String: Any]? {
            collected.first { $0["NSPrivacyCollectedDataType"] as? String == "NSPrivacyCollectedDataType\(type)" }
        }
        for type in ["Name", "EmailAddress", "UserID", "GameplayContent", "OtherUserContent"] {
            let e = try #require(entry(type), "\(type) missing")
            #expect(e["NSPrivacyCollectedDataTypeLinked"] as? Bool == true, "\(type)")
            #expect(e["NSPrivacyCollectedDataTypeTracking"] as? Bool == false, "\(type)")
            #expect(e["NSPrivacyCollectedDataTypePurposes"] as? [String] == ["NSPrivacyCollectedDataTypePurposeAppFunctionality"], "\(type)")
        }
        for type in ["ProductInteraction", "DeviceID", "CoarseLocation"] {
            let e = try #require(entry(type), "\(type) missing")
            #expect(e["NSPrivacyCollectedDataTypeLinked"] as? Bool == false, "\(type)")
            #expect(e["NSPrivacyCollectedDataTypeTracking"] as? Bool == false, "\(type)")
            #expect(e["NSPrivacyCollectedDataTypePurposes"] as? [String] == ["NSPrivacyCollectedDataTypePurposeAnalytics"], "\(type)")
        }
    }

    @Test func noAdSupportLinked() {
        // Firebase Analytics without its IdentitySupport product: no IDFA, no ATT needed.
        #expect(NSClassFromString("ASIdentifierManager") == nil)
    }
}
