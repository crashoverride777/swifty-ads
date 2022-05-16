//    The MIT License (MIT)
//
//    Copyright (c) 2015-2022 Dominik Ringler
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

public typealias SwiftyAdsConsentStatus = UMPConsentStatus
public typealias SwiftyAdsConsentResultHandler = (Result<SwiftyAdsConsentStatus, Error>) -> Void

public enum SwiftyAdsAdUnitIdType {
    case plist
    case custom(String)
}

public enum SwiftyAdsBannerAdAnimation {
    case none
    case fade(duration: TimeInterval)
    case slide(duration: TimeInterval)
}

public enum SwiftyAdsBannerAdPosition {
    case top(isUsingSafeArea: Bool)
    case bottom(isUsingSafeArea: Bool)
}

public enum SwiftyAdsNativeAdLoaderOptions {
    case single
    case multiple(Int)
}

public protocol SwiftyAdsRequestBuilderType: AnyObject {
    func build() -> GADRequest
}

public protocol SwiftyAdsMediationConfiguratorType: AnyObject {
    func updateCOPPA(isTaggedForChildDirectedTreatment: Bool)
    func updateGDPR(for consentStatus: SwiftyAdsConsentStatus, isTaggedForUnderAgeOfConsent: Bool)
}

public protocol SwiftyAdsType: AnyObject {
    var consentStatus: SwiftyAdsConsentStatus { get }
    var isTaggedForChildDirectedTreatment: Bool? { get }
    var isTaggedForUnderAgeOfConsent: Bool { get }
    var isInterstitialAdReady: Bool { get }
    var isRewardedAdReady: Bool { get }
    var isRewardedInterstitialAdReady: Bool { get }
    var isDisabled: Bool { get }
    func configure(from viewController: UIViewController,
                   for environment: SwiftyAdsEnvironment,
                   requestBuilder: SwiftyAdsRequestBuilderType,
                   mediationConfigurator: SwiftyAdsMediationConfiguratorType?,
                   consentStatusDidChange: @escaping (SwiftyAdsConsentStatus) -> Void,
                   completion: @escaping SwiftyAdsConsentResultHandler)
    func askForConsent(from viewController: UIViewController,
                       completion: @escaping SwiftyAdsConsentResultHandler)
    func makeBannerAd(in viewController: UIViewController,
                      adUnitIdType: SwiftyAdsAdUnitIdType,
                      position: SwiftyAdsBannerAdPosition,
                      animation: SwiftyAdsBannerAdAnimation,
                      onOpen: (() -> Void)?,
                      onClose: (() -> Void)?,
                      onError: ((Error) -> Void)?,
                      onWillPresentScreen: (() -> Void)?,
                      onWillDismissScreen: (() -> Void)?,
                      onDidDismissScreen: (() -> Void)?) -> SwiftyAdsBannerType?
    func showInterstitialAd(from viewController: UIViewController,
                            afterInterval interval: Int?,
                            onOpen: (() -> Void)?,
                            onClose: (() -> Void)?,
                            onError: ((Error) -> Void)?)
    func showRewardedAd(from viewController: UIViewController,
                        userIdentifier: String?,
                        onOpen: (() -> Void)?,
                        onClose: (() -> Void)?,
                        onError: ((Error) -> Void)?,
                        onNotReady: (() -> Void)?,
                        onReward: @escaping (NSDecimalNumber) -> Void)
    func showRewardedInterstitialAd(from viewController: UIViewController,
                                    userIdentifier: String?,
                                    afterInterval interval: Int?,
                                    onOpen: (() -> Void)?,
                                    onClose: (() -> Void)?,
                                    onError: ((Error) -> Void)?,
                                    onReward: @escaping (NSDecimalNumber) -> Void)
    func loadNativeAd(from viewController: UIViewController,
                      adUnitIdType: SwiftyAdsAdUnitIdType,
                      loaderOptions: SwiftyAdsNativeAdLoaderOptions,
                      onFinishLoading: (() -> Void)?,
                      onError: ((Error) -> Void)?,
                      onReceive: @escaping (GADNativeAd) -> Void)
    func setDisabled(_ isDisabled: Bool)
    
    // MARK: - Deprecated
    @available(*, deprecated, message: "Use `setDisabled` instead")
    func disable(_ isDisabled: Bool)
}
