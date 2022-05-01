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
    
    func testConsentConfigurationGeography_whenDisabled_returnsDisabled() {
        let sut: SwiftyAdsEnvironment.ConsentConfiguration = .disabled
        XCTAssertEqual(sut.geography, .disabled)
    }
    
    // MARK: Is Disabled
    
    func testConsentConfigurationIsDisabled_whenDefault_returnsFalse() {
        let sut: SwiftyAdsEnvironment.ConsentConfiguration = .default(geography: .EEA)
        XCTAssertFalse(sut.isDisabled)
    }
    
    func testConsentConfigurationIsDisabled_whenResetOnLaunch_returnsFalse() {
        let sut: SwiftyAdsEnvironment.ConsentConfiguration = .resetOnLaunch(geography: .notEEA)
        XCTAssertFalse(sut.isDisabled)
    }
    
    func testConsentConfigurationIsDisabled_whenDisabled_returnsTrue() {
        let sut: SwiftyAdsEnvironment.ConsentConfiguration = .disabled
        XCTAssertTrue(sut.isDisabled)
    }
}
