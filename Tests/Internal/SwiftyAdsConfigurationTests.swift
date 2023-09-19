import XCTest
@testable import SwiftyAds

final class SwiftyAdsConfigurationTests: XCTestCase {

    // MARK: - Production
    
    func testProduction_decodesCorrectly() {
        let sut: SwiftyAdsConfiguration = .debug
        let expectedConfig = SwiftyAdsConfiguration(
            bannerAdUnitId: "123",
            interstitialAdUnitId: "456",
            rewardedAdUnitId: "789",
            rewardedInterstitialAdUnitId: nil,
            nativeAdUnitId: nil
        )
        XCTAssertEqual(sut, expectedConfig)
    }
    
    // MARK: - Debug

    func testDebug_whenUMPConsentEnabled() {
        let sut: SwiftyAdsConfiguration = .debug
        let expectedConfig = SwiftyAdsConfiguration(
            bannerAdUnitId: "ca-app-pub-3940256099942544/2934735716",
            interstitialAdUnitId: "ca-app-pub-3940256099942544/4411468910",
            rewardedAdUnitId: "ca-app-pub-3940256099942544/1712485313",
            rewardedInterstitialAdUnitId: "ca-app-pub-3940256099942544/6978759866",
            nativeAdUnitId: "ca-app-pub-3940256099942544/3986624511"
        )
        XCTAssertEqual(sut, expectedConfig)
    }

    func testDebug_whenUMPConsentDisabled() {
        let sut = SwiftyAdsConfiguration.debug
        let expectedConfig = SwiftyAdsConfiguration(
            bannerAdUnitId: "ca-app-pub-3940256099942544/2934735716",
            interstitialAdUnitId: "ca-app-pub-3940256099942544/4411468910",
            rewardedAdUnitId: "ca-app-pub-3940256099942544/1712485313",
            rewardedInterstitialAdUnitId: "ca-app-pub-3940256099942544/6978759866",
            nativeAdUnitId: "ca-app-pub-3940256099942544/3986624511"
        )
        XCTAssertEqual(sut, expectedConfig)
    }
}
