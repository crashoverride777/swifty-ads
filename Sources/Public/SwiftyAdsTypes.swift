//    The MIT License (MIT)
//
//    Copyright (c) 2015-2026 Dominik Ringler
//
//    Permission is hereby granted, free of charge, to any person obtaining a copy
//    of this software and associated documentation files (the "Software"), to deal
//    in the Software without restriction, including without limitation the rights
//    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//    copies of the Software, and to permit persons to whom the Software is
//    furnished to do so, subject to the following conditions:
//
//    The above copyright notice and this permission notice shall be included in all
//    copies or substantial portions of the Software.
//
//    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//    SOFTWARE.

import GoogleMobileAds
import UserMessagingPlatform

public typealias SwiftyAdsConsentStatus = ConsentStatus

public enum SwiftyAdsAdUnitIdType: Sendable {
    case plist
    case custom(String)
}

public enum SwiftyAdsBannerAdAnimation: Sendable {
    case none
    case fade(duration: TimeInterval)
    case slide(duration: TimeInterval)
}

public enum SwiftyAdsBannerAdPosition: Sendable {
    case top(isUsingSafeArea: Bool)
    case bottom(isUsingSafeArea: Bool)
}

public enum SwiftyAdsNativeAdLoaderOptions: Sendable {
    case single
    case multiple(Int)
}

public protocol SwiftyAdsRequestBuilder {
    func build() -> Request
}

public protocol SwiftyAdsMediationConfigurator: Sendable {
    func updateCOPPA(isTaggedForChildDirectedTreatment: Bool)
    func updateGDPR(for consentStatus: SwiftyAdsConsentStatus, isTaggedForUnderAgeOfConsent: Bool)
}

@MainActor
public protocol SwiftyAdsBannerAd: AnyObject {
    /// Show the banner ad.
    ///
    /// - parameter isLandscape: If true banner is sized for landscape, otherwise portrait.
    func show(isLandscape: Bool)
    /// Hide the banner ad.
    func hide()
    /// Removes the banner from its superview.
    func remove()
}

public protocol SwiftyAdsType: Sendable {
    var consentStatus: SwiftyAdsConsentStatus { get }
    var isInterstitialAdReady: Bool { get }
    var isRewardedAdReady: Bool { get }
    var isRewardedInterstitialAdReady: Bool { get }
    var isDisabled: Bool { get }
    @MainActor
    func configure(requestBuilder: SwiftyAdsRequestBuilder, mediationConfigurator: SwiftyAdsMediationConfigurator?)
    @MainActor
    func initializeIfNeeded(from viewController: UIViewController) async throws
    @MainActor
    func makeBannerAd(in viewController: UIViewController,
                      adUnitIdType: SwiftyAdsAdUnitIdType,
                      position: SwiftyAdsBannerAdPosition,
                      animation: SwiftyAdsBannerAdAnimation,
                      onOpen: (() -> Void)?,
                      onClose: (() -> Void)?,
                      onError: ((Error) -> Void)?,
                      onWillPresentScreen: (() -> Void)?,
                      onWillDismissScreen: (() -> Void)?,
                      onDidDismissScreen: (() -> Void)?) -> SwiftyAdsBannerAd?
    @MainActor
    func showInterstitialAd(from viewController: UIViewController,
                            onOpen: (() -> Void)?,
                            onClose: (() -> Void)?,
                            onError: ((Error) -> Void)?) async throws
    @MainActor
    func showRewardedAd(from viewController: UIViewController,
                        onOpen: (() -> Void)?,
                        onClose: (() -> Void)?,
                        onError: ((Error) -> Void)?,
                        onReward: @escaping (NSDecimalNumber) -> Void) async throws
    @MainActor
    func showRewardedInterstitialAd(from viewController: UIViewController,
                                    onOpen: (() -> Void)?,
                                    onClose: (() -> Void)?,
                                    onError: ((Error) -> Void)?,
                                    onReward: @escaping (NSDecimalNumber) -> Void) async throws
    @MainActor
    func loadNativeAd(from viewController: UIViewController,
                      adUnitIdType: SwiftyAdsAdUnitIdType,
                      loaderOptions: SwiftyAdsNativeAdLoaderOptions,
                      onFinishLoading: (() -> Void)?,
                      onError: ((Error) -> Void)?,
                      onReceive: @escaping (NativeAd) -> Void)
    @MainActor
    func updateConsent(from viewController: UIViewController) async throws -> SwiftyAdsConsentStatus
    func setDisabled(_ isDisabled: Bool)
    func loadAdsIfNeeded() async throws
    #if DEBUG
    func enableDebug(testDeviceIdentifiers: [String],
                     geography: DebugGeography,
                     resetsConsentOnLaunch: Bool,
                     isTaggedForChildDirectedTreatment: Bool?,
                     isTaggedForUnderAgeOfConsent: Bool?)
    #endif
}
