import XCTest
@testable import SwiftyAds

final class SwiftyAdsConfigurationTests: XCTestCase {

    func testProduction_decodesCorrectly() {
        let sut: SwiftyAdsConfiguration = .production(bundle: .module)
        let expectedConfig = SwiftyAdsConfiguration(
            bannerAdUnitId: "111",
            interstitialAdUnitId: "222",
            rewardedAdUnitId: "333",
            rewardedInterstitialAdUnitId: "444",
            nativeAdUnitId: "555",
            isTaggedForChildDirectedTreatment: false,
            isTaggedForUnderAgeOfConsent: true
        )
        XCTAssertEqual(sut, expectedConfig)
    }
    
    func testDebug() {
        let developmentSettings = SwiftyAdsEnvironment.DevelopmentSettings(
            testDeviceIdentifiers: [],
            geography: .disabled,
            resetsConsentOnLaunch: false,
            isTaggedForChildDirectedTreatment: nil,
            isTaggedForUnderAgeOfConsent: true
        )
        let sut: SwiftyAdsConfiguration = .debug(for: developmentSettings)
        let expectedConfig = SwiftyAdsConfiguration(
            bannerAdUnitId: "ca-app-pub-3940256099942544/2934735716",
            interstitialAdUnitId: "ca-app-pub-3940256099942544/4411468910",
            rewardedAdUnitId: "ca-app-pub-3940256099942544/1712485313",
            rewardedInterstitialAdUnitId: "ca-app-pub-3940256099942544/6978759866",
            nativeAdUnitId: "ca-app-pub-3940256099942544/3986624511",
            isTaggedForChildDirectedTreatment: nil,
            isTaggedForUnderAgeOfConsent: true
        )
        XCTAssertEqual(sut, expectedConfig)
    }
}
