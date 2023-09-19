import XCTest
@testable import SwiftyAds

final class SwiftyAdsEnvironmentTests: XCTestCase {

    // MARK: - Consent Configuration
    
    // MARK: Geography
    
    func testConsentConfigurationGeography_whenDefault_returnsGeography() {
        let sut: SwiftyAdsEnvironment.ConsentConfiguration = .default(geography: .EEA)
        XCTAssertEqual(sut.geography, .EEA)
    }
    
    func testConsentConfigurationGeography_whenResetOnLaunch_returnsGeography() {
        let sut: SwiftyAdsEnvironment.ConsentConfiguration = .resetOnLaunch(geography: .notEEA)
        XCTAssertEqual(sut.geography, .notEEA)
    }
}
