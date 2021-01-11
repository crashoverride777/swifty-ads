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

/**
 SwiftyAds
 
 A concret class implementation of SwiftAdsType to display ads from AdMob.
 */
public final class SwiftyAds: NSObject {
    
    // MARK: - Static Properties
    
    /// The shared instance of SwiftyAds
    public static let shared = SwiftyAds()
    
    // MARK: - Properties
    
    private let mobileAds: GADMobileAds
    private let intervalTracker: IntervalTracker
    
    private var bannerAd: SwiftyAdsBannerType?
    private var interstitialAd: SwiftyAdsInterstitialType?
    private var rewardedAd: SwiftyAdsRewardedType?
    private var nativeAd: SwiftyAdsNativeAdType?
    private var consentManager: SwiftyAdsConsentManagerType!
    private var isDisabled = false
        
    // MARK: - Computed Properties
    
    private var requestBuilder: SwiftyAdsRequestBuilderType {
        SwiftyAdsRequestBuilder(
            isGDPRRequired: consentManager.status != .notRequired,
            isNonPersonalizedOnly: consentManager.status == .nonPersonalized,
            isTaggedForUnderAgeOfConsent: consentManager.status == .underAge
        )
    }
    
    // MARK: - Initialization
    
    private override init() {
        mobileAds = .sharedInstance()
        intervalTracker = SwiftyAdsIntervalTracker()
        super.init()
        
    }
    
    init(mobileAds: GADMobileAds,
         bannerAd: SwiftyAdsBannerType?,
         interstitialAd: SwiftyAdsInterstitialType?,
         rewardedAd: SwiftyAdsRewardedType?,
         nativeAd: SwiftyAdsNativeAdType?,
         consentManager: SwiftyAdsConsentManagerType,
         intervalTracker: IntervalTracker) {
        self.mobileAds = mobileAds
        self.bannerAd = bannerAd
        self.interstitialAd = interstitialAd
        self.rewardedAd = rewardedAd
        self.nativeAd = nativeAd
        self.consentManager = consentManager
        self.intervalTracker = intervalTracker
    }
}

// MARK: - SwiftyAdsType

extension SwiftyAds: SwiftyAdsType {
    
    /// Check if user has given consent e.g to hide rewarded video button
    /// Also returns true if user is outside EEA and is therefore not required to provide consent
    public var hasConsent: Bool {
        consentManager.status.hasConsent
    }
     
    /// Check if we must ask for consent e.g to hide change consent button in apps settings menu (required GDPR requirement)
    public var isRequiredToAskForConsent: Bool {
        switch consentManager.status {
        case .notRequired, .underAge: // if under age, cannot legally consent
            return false
        default:
            return true
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
    /// - parameter environment: Sets the environment fof swifty ads to display ads.
    /// - parameter consentStyle: The style of the consent alert.
    /// - parameter consentStatusDidChange: A handler that will fire everytime the consent status has changed.
    /// - parameter completion: A handler that will return the current consent status after the consent alert has been dismissed.
    public func setup(with viewController: UIViewController,
                      environment: SwiftyAdsEnvironment,
                      consentStyle: SwiftyAdsConsentStyle,
                      consentStatusDidChange: @escaping (SwiftyAdsConsentStatus) -> Void,
                      completion: @escaping (SwiftyAdsConsentStatus) -> Void) {
        // Update configuration for selected environment
        let configuration: SwiftyAdsConfiguration
        switch environment {
        case .production:
            configuration = .production
        case .debug(let testDeviceIdentifiers):
            configuration = .debug
            mobileAds.requestConfiguration.testDeviceIdentifiers = testDeviceIdentifiers//kGADSimulatorID
        }
        
        // Create ads
        if let bannerAdUnitId = configuration.bannerAdUnitId {
            bannerAd = SwiftyAdsBanner(
                adUnitId: bannerAdUnitId,
                request: ({ [unowned self] in
                    self.requestBuilder.build()
                })
            )
        }

        if let interstitialAdUnitId = configuration.interstitialAdUnitId {
            interstitialAd = SwiftyAdsInterstitial(
                adUnitId: interstitialAdUnitId,
                request: ({ [unowned self] in
                    self.requestBuilder.build()
                })
            )
        }

        if let rewardedVideoAdUnitId = configuration.rewardedVideoAdUnitId {
            rewardedAd = SwiftyAdsRewarded(
                adUnitId: rewardedVideoAdUnitId,
                request: ({ [unowned self] in
                    self.requestBuilder.build()
                })
            )
        }

        if let nativeAdUnitId = configuration.nativeAdUnitId {
            nativeAd = SwiftyAdsNativeAd(
                adUnitId: nativeAdUnitId,
                request: ({ [unowned self] in
                    self.requestBuilder.build()
                })
            )
        }
     
        // Create consent manager and make request
        consentManager = SwiftyAdsConsentManager(
            consentInformation: .sharedInstance,
            configuration: configuration,
            consentStyle: consentStyle,
            statusDidChange: consentStatusDidChange
        )
        
        consentManager.requestUpdate { [weak self] status in
            guard let self = self else { return }
            func loadAds() {
                if !self.isDisabled {
                    self.interstitialAd?.load()
                }
                self.rewardedAd?.load()
            }
            
            if status.hasConsent {
                loadAds()
                completion(status)
            } else {
                self.consentManager.showForm(from: viewController) { status in
                    if status.hasConsent {
                        loadAds()
                        completion(status)
                    }
                }
            }
        }
    }

    /// Ask for consent e.g when consent button is pressed
    ///
    /// - parameter viewController: The view controller that will present the consent form.
    public func askForConsent(from viewController: UIViewController) {
        consentManager.showForm(from: viewController, handler: nil)
    }
    
    /// Show banner ad
    ///
    /// - parameter viewController: The view controller that will present the ad.
    /// - parameter isAtTop: If set to true the banner will be displayed at the top.
    /// - parameter ignoresSafeArea: If set to true the banner will ignore safe area margins
    /// - parameter animationDuration: The duration of the banner to animate on/off screen.
    /// - parameter onOpen: An optional callback when the banner was presented.
    /// - parameter onClose: An optional callback when the banner was dismissed or removed.
    /// - parameter onError: An optional callback when an error has occurred.
    public func showBanner(from viewController: UIViewController,
                           atTop isAtTop: Bool,
                           ignoresSafeArea: Bool,
                           animationDuration: TimeInterval,
                           onOpen: (() -> Void)?,
                           onClose: (() -> Void)?,
                           onError: ((Error) -> Void)?) {
        guard let bannerAd = bannerAd else { return }
        guard !isDisabled, hasConsent else { return }
        
        bannerAd.show(
            from: viewController,
            at: isAtTop ? .top(ignoresSafeArea: ignoresSafeArea) : .bottom(ignoresSafeArea: ignoresSafeArea),
            isLandscape: UIDevice.current.orientation.isLandscape,
            animationDuration: animationDuration,
            onOpen: onOpen,
            onClose: onClose,
            onError: onError
        )
    }
    
    /// Update banner for orientation change
    ///
    /// - parameter isLandscape: An flag to tell the banner if it should be refreshed for landscape or portrait orientation.
    public func updateBannerForOrientationChange(isLandscape: Bool) {
        bannerAd?.updateSize(isLandscape: isLandscape)
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
        guard let interstitialAd = interstitialAd else { return }
        guard !isDisabled, hasConsent else { return }
        guard intervalTracker.canShow(forInterval: interval) else { return }
        
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
        guard let rewardedAd = rewardedAd else { return }
        guard hasConsent else { return }
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

    /// Disable ads e.g in app purchases
    public func disable() {
        isDisabled = true
        removeBanner()
        interstitialAd?.stopLoading()
    }
}
