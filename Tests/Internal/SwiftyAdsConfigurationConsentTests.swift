import XCTest
@testable import SwiftyAds

final class SwiftyAdsConfigurationConsentTests: XCTestCase {

    func testProduction_decodesCorrectly() {
        let sut: SwiftyAdsConsentConfiguration? = .production(bundle: .module)
        let expectedConfig = SwiftyAdsConsentConfiguration(
            isTaggedForChildDirectedTreatment: false,
            isTaggedForUnderAgeOfConsent: true
        )
        XCTAssertEqual(sut, expectedConfig)
    }
    
    func testDebug() {
        let sut: SwiftyAdsConsentConfiguration = .debug
        let expectedConfig = SwiftyAdsConsentConfiguration(
            isTaggedForChildDirectedTreatment: false,
            isTaggedForUnderAgeOfConsent: false
        )
        XCTAssertEqual(sut, expectedConfig)
    }
}
