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

public enum SwiftyAdsEnvironment {
    case production
    case debug(testDeviceIdentifiers: [String], geography: SwiftyAdsDebugGeography, resetConsentInfo: Bool)
}

public protocol SwiftyAdsType: AnyObject {
    var isConsentRequired: Bool { get }
    var hasConsent: Bool { get }
    var isInterstitialReady: Bool { get }
    var isRewardedVideoReady: Bool { get }
    func setup(from viewController: UIViewController,
               in environment: SwiftyAdsEnvironment,
               completion: @escaping (SwiftyAdsConsentStatus) -> Void)
    func askForConsent(from viewController: UIViewController,
                       completion: @escaping (Result<SwiftyAdsConsentStatus, Error>) -> Void)
    func prepareBanner(in viewController: UIViewController,
                       atTop isAtTop: Bool,
                       isUsingSafeArea: Bool,
                       animationDuration: TimeInterval,
                       onOpen: (() -> Void)?,
                       onClose: (() -> Void)?,
                       onError: ((Error) -> Void)?)
    func showBanner(isLandscape: Bool)
    func removeBanner()
    func showInterstitial(from viewController: UIViewController,
                          withInterval interval: Int?,
                          onOpen: (() -> Void)?,
                          onClose: (() -> Void)?,
                          onError: ((Error) -> Void)?)
    func showRewardedVideo(from viewController: UIViewController,
                           onOpen: (() -> Void)?,
                           onClose: (() -> Void)?,
                           onError: ((Error) -> Void)?,
                           onNotReady: (() -> Void)?,
                           onReward: @escaping (Int) -> Void)
    func loadNativeAd(from viewController: UIViewController,
                      count: Int?,
                      onReceive: @escaping (GADUnifiedNativeAd) -> Void,
                      onError: @escaping (Error) -> Void)
    func disable()
}

/**
 SwiftyAds
 
 A concret class implementation of SwiftAdsType to display ads from Google AdMob.
 */
public final class SwiftyAds: NSObject {
    
    // MARK: - Static Properties
    
    /// The shared SwiftyAds instance
    public static let shared = SwiftyAds()
    
    // MARK: - Properties
    
    private let mobileAds: GADMobileAds
    private let intervalTracker: IntervalTracker

    private var bannerAd: SwiftyAdsBannerType?
    private var interstitialAd: SwiftyAdsInterstitialType?
    private var rewardedAd: SwiftyAdsRewardedType?
    private var nativeAd: SwiftyAdsNativeType?
    private var consentManager: SwiftyAdsConsentManagerType!
    private var configuration: SwiftyAdsConfiguration?
    private var isDisabled = false
        
    // MARK: - Computed Properties
    
    private var requestBuilder: SwiftyAdsRequestBuilderType {
        SwiftyAdsRequestBuilder(
            isConsentRequired: isConsentRequired,
            //isNonPersonalizedOnly: consentManager.status == .nonPersonalized,
            isTaggedForUnderAgeOfConsent: configuration?.isTaggedForUnderAgeOfConsent ?? true
        )
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
         bannerAd: SwiftyAdsBannerType?,
         interstitialAd: SwiftyAdsInterstitialType?,
         rewardedAd: SwiftyAdsRewardedType?,
         nativeAd: SwiftyAdsNativeType?) {
        self.mobileAds = mobileAds
        self.consentManager = consentManager
        self.intervalTracker = intervalTracker
        self.bannerAd = bannerAd
        self.interstitialAd = interstitialAd
        self.rewardedAd = rewardedAd
        self.nativeAd = nativeAd
    }
}

// MARK: - SwiftyAdsType

extension SwiftyAds: SwiftyAdsType {

    /// Check if we must ask user for consent.
    public var isConsentRequired: Bool {
        consentManager.status != .notRequired
    }

    /// Check if user has given consent or is not required to provide consent.
    public var hasConsent: Bool {
        switch consentManager.status {
        case .notRequired, .obtained:
            return true
        default:
            return false
        }
    }
     
    /// Check if interstitial video is ready (e.g to show alternative ad like an in house ad)
    public var isInterstitialReady: Bool {
        interstitialAd?.isReady ?? false
    }
     
    /// Check if reward video is ready (e.g to hide/disable the rewarded video button)
    public var isRewardedVideoReady: Bool {
        rewardedAd?.isReady ?? false
    }
    
    /// Setup swift ad
    ///
    /// - parameter viewController: The view controller that will present the consent alert if needed.
    /// - parameter environment: The environment for ads to be displayed.
    /// - parameter completion: A completion handler that will return the current consent status after the consent flow has finished.
    public func setup(from viewController: UIViewController,
                      in environment: SwiftyAdsEnvironment,
                      completion: @escaping (SwiftyAdsConsentStatus) -> Void) {
        // Update configuration for selected environment
        let configuration: SwiftyAdsConfiguration
        switch environment {
        case .production:
            configuration = .production
        case .debug(let testDeviceIdentifiers, _, _):
            configuration = .debug
            mobileAds.requestConfiguration.testDeviceIdentifiers = testDeviceIdentifiers//kGADSimulatorID
        }

        // Keep reference to configuration
        self.configuration = configuration
        
        // Create banner ad if we have an AdUnitId
        if let bannerAdUnitId = configuration.bannerAdUnitId {
            bannerAd = SwiftyAdsBanner(
                adUnitId: bannerAdUnitId,
                request: { [unowned self] in
                    self.requestBuilder.build()
                }
            )
        }

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
        if let rewardedVideoAdUnitId = configuration.rewardedVideoAdUnitId {
            rewardedAd = SwiftyAdsRewarded(
                adUnitId: rewardedVideoAdUnitId,
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
        consentManager = SwiftyAdsConsentManager(
            consentInformation: .sharedInstance,
            configuration: configuration,
            environment: environment
        )

        // Request consent update
        DispatchQueue.main.async {
            self.consentManager.requestUpdate { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let status):
                    if status == .obtained {
                        self.loadAds()
                        completion(status)
                    } else if status == .required {
                        DispatchQueue.main.async {
                            self.consentManager.showForm(from: viewController) { result in
                                switch result {
                                case .success(let status):
                                    if status == .obtained {
                                        self.loadAds()
                                        completion(status)
                                    }
                                case .failure(let error):
                                    print(error)
                                    completion(self.consentManager.status)
                                    #warning("fix")
                                }
                            }
                        }
                    }
                case .failure(let error):
                    print(error)
                    completion(self.consentManager.status)
                    #warning("fix")
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
        DispatchQueue.main.async {
            self.consentManager.requestUpdate { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success:
                    DispatchQueue.main.async {
                        self.consentManager.showForm(from: viewController, completion: completion)
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    /// Show banner ad
    ///
    /// - parameter viewController: The view controller that will present the ad.
    /// - parameter isAtTop: If set to true the banner will be displayed at the top.
    /// - parameter isUsingSafeArea: If set to true the banner will use the safe area margins.
    /// - parameter animationDuration: The duration of the banner to animate on/off screen.
    /// - parameter onOpen: An optional callback when the banner was presented.
    /// - parameter onClose: An optional callback when the banner was dismissed or removed.
    /// - parameter onError: An optional callback when an error has occurred.
    public func prepareBanner(in viewController: UIViewController,
                              atTop isAtTop: Bool,
                              isUsingSafeArea: Bool,
                              animationDuration: TimeInterval,
                              onOpen: (() -> Void)?,
                              onClose: (() -> Void)?,
                              onError: ((Error) -> Void)?) {
        guard !isDisabled else { return }
        guard hasConsent else { return }

        bannerAd?.prepare(
            in: viewController,
            at: isAtTop ? .top(isUsingSafeArea: isUsingSafeArea) : .bottom(isUsingSafeArea: isUsingSafeArea),
            animationDuration: animationDuration,
            onOpen: onOpen,
            onClose: onClose,
            onError: onError
        )
    }

    /// Show the prepared banner
    ///
    /// - parameter isLandscape: If true banner is sized for landscape, otherwise portrait.
    public func showBanner(isLandscape: Bool) {
        guard !isDisabled else { return }
        guard hasConsent else { return }
        bannerAd?.show(isLandscape: isLandscape)
    }

    /// Remove banner ads
    public func removeBanner() {
        bannerAd?.remove()
    }
    
    /// Show interstitial ad
    ///
    /// - parameter viewController: The view controller that will present the ad.
    /// - parameter interval: The interval of when to show the ad, e.g every 4th time the method is called. Set to nil to always show.
    /// - parameter onOpen: An optional callback when the banner was presented.
    /// - parameter onClose: An optional callback when the ad was dismissed.
    /// - parameter onError: An optional callback when an error has occurred.
    public func showInterstitial(from viewController: UIViewController,
                                 withInterval interval: Int?,
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
    public func showRewardedVideo(from viewController: UIViewController,
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
    /// - parameter count: The number of ads to load via  GADMultipleAdsAdLoaderOptions. Set to nil to use default options or when using mediation.
    /// - parameter onReceive: The received GADUnifiedNativeAd when the load request has completed.
    /// - parameter onError: The error when the load request has failed.

    /// - Warning:
    /// Requests for multiple native ads don't currently work for AdMob ad unit IDs that have been configured for mediation.
    /// Publishers using mediation should avoid using the GADMultipleAdsAdLoaderOptions class when making requests i.e. set count to nil.
    public func loadNativeAd(from viewController: UIViewController,
                             count: Int?,
                             onReceive: @escaping (GADUnifiedNativeAd) -> Void,
                             onError: @escaping (Error) -> Void) {
        guard let nativeAd = nativeAd else { return }
        guard hasConsent else { return }
        nativeAd.load(
            from: viewController,
            count: count,
            onReceive: onReceive,
            onError: onError
        )
    }

    /// Disable ads for example when providing a remove ads in app purchase.
    public func disable() {
        isDisabled = true
        removeBanner()
        interstitialAd?.stopLoading()
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
