//    The MIT License (MIT)
//
//    Copyright (c) 2015-2021 Dominik Ringler
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
public typealias SwiftyAdsDebugGeography = UMPDebugGeography

public protocol SwiftyAdsType: AnyObject {
    var isConsentRequired: Bool { get }
    var hasConsent: Bool { get }
    var isInterstitialAdReady: Bool { get }
    var isRewardedAdReady: Bool { get }
    func setup(from viewController: UIViewController,
               for environment: SwiftyAdsEnvironment,
               completion: @escaping (Result<SwiftyAdsConsentStatus, Error>) -> Void)
    func askForConsent(from viewController: UIViewController,
                       completion: @escaping (Result<SwiftyAdsConsentStatus, Error>) -> Void)
    func makeBannerAd(in viewController: UIViewController,
                      adUnitIdType: SwiftyAdsAdUnitIdType,
                      position: SwiftyAdsBannerAdPosition,
                      animationDuration: TimeInterval,
                      onOpen: (() -> Void)?,
                      onClose: (() -> Void)?,
                      onError: ((Error) -> Void)?) -> SwiftyAdsBannerType?
    func showInterstitialAd(from viewController: UIViewController,
                            afterInterval interval: Int?,
                            onOpen: (() -> Void)?,
                            onClose: (() -> Void)?,
                            onError: ((Error) -> Void)?)
    func showRewardedAd(from viewController: UIViewController,
                        onOpen: (() -> Void)?,
                        onClose: (() -> Void)?,
                        onError: ((Error) -> Void)?,
                        onNotReady: (() -> Void)?,
                        onReward: @escaping (Int) -> Void)
    func loadNativeAd(from viewController: UIViewController,
                      adUnitIdType: SwiftyAdsAdUnitIdType,
                      count: Int?,
                      onReceive: @escaping (GADNativeAd) -> Void,
                      onError: @escaping (Error) -> Void)
    func disable()
}

/**
 SwiftyAds
 
 A concret class implementation of SwiftAdsType to display ads from Google AdMob.
 */
public final class SwiftyAds: NSObject {

    // MARK: - Types

    enum SwiftyAdsError: Error {
        case noConsentManager
        case missingBannerAdUnitId
    }

    // MARK: - Static Properties

    /// The shared SwiftyAds instance.
    public static let shared = SwiftyAds()

    // MARK: - Properties
    
    private let mobileAds: GADMobileAds
    private let intervalTracker: IntervalTracker

    private var interstitialAd: SwiftyAdsInterstitialType?
    private var rewardedAd: SwiftyAdsRewardedType?
    private var nativeAd: SwiftyAdsNativeType?
    private var consentManager: SwiftyAdsConsentManagerType?
    private var configuration: SwiftyAdsConfiguration?
    private var isDisabled = false
        
    // MARK: - Computed Properties
    
    private var requestBuilder: SwiftyAdsRequestBuilderType {
        SwiftyAdsRequestBuilder()
    }
    
    // MARK: - Initialization
    
    private override init() {
        mobileAds = .sharedInstance()
        intervalTracker = SwiftyAdsIntervalTracker()
        super.init()
        
    }
    
    init(mobileAds: GADMobileAds,
         consentManager: SwiftyAdsConsentManagerType,
         intervalTracker: IntervalTracker,
         interstitialAd: SwiftyAdsInterstitialType?,
         rewardedAd: SwiftyAdsRewardedType?,
         nativeAd: SwiftyAdsNativeType?) {
        self.mobileAds = mobileAds
        self.consentManager = consentManager
        self.intervalTracker = intervalTracker
        self.interstitialAd = interstitialAd
        self.rewardedAd = rewardedAd
        self.nativeAd = nativeAd
    }
}

// MARK: - SwiftyAdsType

extension SwiftyAds: SwiftyAdsType {

    /// Check if we must ask user for consent.
    public var isConsentRequired: Bool {
        guard let consentManager = consentManager else { return false }
        return consentManager.status != .notRequired
    }

    /// Check if user has given consent or is not required to provide consent.
    public var hasConsent: Bool {
        guard let consentManager = consentManager else { return true }
        switch consentManager.status {
        case .notRequired, .obtained:
            return true
        default:
            return false
        }
    }
     
    /// Check if interstitial ad is ready (e.g to show alternative ad like an in house ad)
    public var isInterstitialAdReady: Bool {
        interstitialAd?.isReady ?? false
    }
     
    /// Check if reward ad is ready (e.g to hide/disable the rewarded video button)
    public var isRewardedAdReady: Bool {
        rewardedAd?.isReady ?? false
    }
    
    /// Setup swift ad
    ///
    /// - parameter viewController: The view controller that will present the consent alert if needed.
    /// - parameter environment: The environment for ads to be displayed.
    /// - parameter completion: A completion handler that will return the current consent status after the consent flow has finished.
    public func setup(from viewController: UIViewController,
                      for environment: SwiftyAdsEnvironment,
                      completion: @escaping (Result<SwiftyAdsConsentStatus, Error>) -> Void) {
        // Update configuration for selected environment
        let configuration: SwiftyAdsConfiguration
        switch environment {
        case .production:
            configuration = .production
        case .debug(let testDeviceIdentifiers, _, _):
            configuration = .debug
            let simulatorId = kGADSimulatorID as? String
            mobileAds.requestConfiguration.testDeviceIdentifiers = [simulatorId].compactMap { $0 } + testDeviceIdentifiers
        }

        // Keep reference to configuration
        self.configuration = configuration

        // Create interstitial ad if we have an AdUnitId
        if let interstitialAdUnitId = configuration.interstitialAdUnitId {
            interstitialAd = SwiftyAdsInterstitial(
                adUnitId: interstitialAdUnitId,
                request: { [unowned self] in
                    self.requestBuilder.build()
                }
            )
        }

        // Create rewarded ad if we have an AdUnitId
        if let rewardedAdUnitId = configuration.rewardedAdUnitId {
            rewardedAd = SwiftyAdsRewarded(
                adUnitId: rewardedAdUnitId,
                request: { [unowned self] in
                    self.requestBuilder.build()
                }
            )
        }

        // Create native ad if we have an AdUnitId
        if let nativeAdUnitId = configuration.nativeAdUnitId {
            nativeAd = SwiftyAdsNative(
                adUnitId: nativeAdUnitId,
                request: { [unowned self] in
                    self.requestBuilder.build()
                }
            )
        }
     
        // Create consent manager
        let consentManager = SwiftyAdsConsentManager(
            consentInformation: .sharedInstance,
            configuration: configuration,
            environment: environment,
            mobileAds: mobileAds
        )

        // Keep reference to consent manager
        self.consentManager = consentManager

        // Request consent update
        DispatchQueue.main.async {
            consentManager.requestUpdate { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let status):
                    switch status {
                    case .obtained:
                        self.loadAds()
                        completion(.success(status))
                    case .required:
                        DispatchQueue.main.async {
                            consentManager.showForm(from: viewController) { [weak self] result in
                                guard let self = self else { return }
                                switch result {
                                case .success(let status):
                                    if status == .obtained {
                                        self.loadAds()
                                    }
                                    completion(.success(status))
                                case .failure(let error):
                                    completion(.failure(error))
                                }
                            }
                        }
                    default:
                        completion(.success(status))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }

    /// Under GDPR users must be able to change their consent at any time.
    ///
    /// - parameter viewController: The view controller that will present the consent form.
    /// - parameter completion: A completion handler that will return the updated consent status.
    public func askForConsent(from viewController: UIViewController,
                              completion: @escaping (Result<SwiftyAdsConsentStatus, Error>) -> Void) {
        guard let consentManager = consentManager else {
            completion(.failure(SwiftyAdsError.noConsentManager))
            return
        }
        
        DispatchQueue.main.async {
            consentManager.requestUpdate { result in
                switch result {
                case .success:
                    DispatchQueue.main.async {
                        consentManager.showForm(from: viewController, completion: completion)
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    /// Make banner ad
    ///
    /// - parameter viewController: The view controller that will present the ad.
    /// - parameter adUnitIdType: The adUnitId type for the ad, either plist or custom.
    /// - parameter position: The position of the banner.
    /// - parameter animationDuration: The duration of the banner to animate on/off screen.
    /// - parameter onOpen: An optional callback when the banner was presented.
    /// - parameter onClose: An optional callback when the banner was dismissed or removed.
    /// - parameter onError: An optional callback when an error has occurred.
    /// - returns SwiftyAdsBannerType to show, hide or remove the prepared banner ad.
    public func makeBannerAd(in viewController: UIViewController,
                             adUnitIdType: SwiftyAdsAdUnitIdType,
                             position: SwiftyAdsBannerAdPosition,
                             animationDuration: TimeInterval,
                             onOpen: (() -> Void)?,
                             onClose: (() -> Void)?,
                             onError: ((Error) -> Void)?) -> SwiftyAdsBannerType? {
        guard !isDisabled else { return nil }
        guard hasConsent else { return nil }

        let adUnitId: String?

        switch adUnitIdType {
        case .plist:
            adUnitId = configuration?.bannerAdUnitId
        case .custom(let id):
            adUnitId = id
        }

        guard let validAdUnitId = adUnitId else {
            onError?(SwiftyAdsError.missingBannerAdUnitId)
            return nil
        }

        let bannerAd = SwiftyAdsBanner(
            adUnitId: validAdUnitId,
            isDisabled: { [weak self] in
                self?.isDisabled ?? false
            },
            hasConsent: { [weak self] in
                self?.hasConsent ?? true
            },
            request: { [unowned self] in
                self.requestBuilder.build()
            }
        )

        bannerAd.prepare(
            in: viewController,
            adUnitIdType: adUnitIdType,
            position: position,
            animationDuration: animationDuration,
            onOpen: onOpen,
            onClose: onClose,
            onError: onError
        )

        return bannerAd
    }
    
    /// Show interstitial ad
    ///
    /// - parameter viewController: The view controller that will present the ad.
    /// - parameter interval: The interval of when to show the ad, e.g every 4th time the method is called. Set to nil to always show.
    /// - parameter onOpen: An optional callback when the banner was presented.
    /// - parameter onClose: An optional callback when the ad was dismissed.
    /// - parameter onError: An optional callback when an error has occurred.
    public func showInterstitialAd(from viewController: UIViewController,
                                   afterInterval interval: Int?,
                                   onOpen: (() -> Void)?,
                                   onClose: (() -> Void)?,
                                   onError: ((Error) -> Void)?) {
        guard !isDisabled else { return }
        guard hasConsent else { return }
        guard intervalTracker.canShow(forInterval: interval) else { return }
        guard let interstitialAd = interstitialAd else { return }

        interstitialAd.show(
            from: viewController,
            onOpen: onOpen,
            onClose: onClose,
            onError: onError
        )
    }
    
    /// Show rewarded video ad
    ///
    /// - parameter viewController: The view controller that will present the ad.
    /// - parameter onOpen: An optional callback when the banner was presented.
    /// - parameter onClose: An optional callback when the ad was dismissed.
    /// - parameter onError: An optional callback when an error has occurred.
    /// - parameter onNotReady: An optional callback when the ad was not ready.
    /// - parameter onReward: A callback when the reward has been granted.
    public func showRewardedAd(from viewController: UIViewController,
                               onOpen: (() -> Void)?,
                               onClose: (() -> Void)?,
                               onError: ((Error) -> Void)?,
                               onNotReady: (() -> Void)?,
                               onReward: @escaping (Int) -> Void) {
        guard hasConsent else { return }
        guard let rewardedAd = rewardedAd else { return }

        rewardedAd.show(
            from: viewController,
            onOpen: onOpen,
            onClose: onClose,
            onError: onError,
            onNotReady: onNotReady,
            onReward: onReward
        )
    }

    /// Load native ad
    ///
    /// - parameter viewController: The view controller that will load the native ad.
    /// - parameter adUnitIdType: The adUnitId type for the ad, either plist or custom.
    /// - parameter count: The number of ads to load via  GADMultipleAdsAdLoaderOptions. Set to nil to use default options or when using mediation.
    /// - parameter onReceive: The received GADNativeAd when the load request has completed.
    /// - parameter onError: The error when the load request has failed.

    /// - Warning:
    /// Requests for multiple native ads don't currently work for AdMob ad unit IDs that have been configured for mediation.
    /// Publishers using mediation should avoid using the GADMultipleAdsAdLoaderOptions class when making requests i.e. set count to nil.
    public func loadNativeAd(from viewController: UIViewController,
                             adUnitIdType: SwiftyAdsAdUnitIdType,
                             count: Int?,
                             onReceive: @escaping (GADNativeAd) -> Void,
                             onError: @escaping (Error) -> Void) {
        guard !isDisabled else { return }
        guard hasConsent else { return }

        if case .custom(let adUnitId) = adUnitIdType, nativeAd == nil {
            nativeAd = SwiftyAdsNative(
                adUnitId: adUnitId,
                request: { [unowned self] in
                    self.requestBuilder.build()
                }
            )
        }

        nativeAd?.load(
            from: viewController,
            adUnitIdType: adUnitIdType,
            count: count,
            onReceive: onReceive,
            onError: onError
        )
    }

    /// Disable ads for example when providing a remove ads in app purchase.
    public func disable() {
        isDisabled = true
        interstitialAd?.stopLoading()
        nativeAd?.stopLoading()
    }
}

// MARK: - Private Methods

private extension SwiftyAds {

    func loadAds() {
        rewardedAd?.load()
        guard !isDisabled else { return }
        interstitialAd?.load()
    }
}
