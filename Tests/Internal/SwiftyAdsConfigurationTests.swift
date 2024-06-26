import XCTest
@testable import SwiftyAds

final class SwiftyAdsConfigurationTests: XCTestCase {

    func testProduction_decodesCorrectly() {
        let sut: SwiftyAdsConfiguration = .production(bundle: .module)
        let expectedConfig = SwiftyAdsConfiguration(
            bannerAdUnitId: "123",
            interstitialAdUnitId: "456",
            rewardedAdUnitId: "789",
            rewardedInterstitialAdUnitId: nil,
            nativeAdUnitId: nil
        )
        XCTAssertEqual(sut, expectedConfig)
    }
    
    func testDebug() {
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
}
