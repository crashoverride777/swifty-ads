//    The MIT License (MIT)
//
//    Copyright (c) 2015-2020 Dominik Ringler
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
    private let intervalTracker: SwiftyAdsIntervalTrackerType
    
    private var bannerAd: SwiftyAdsBannerType?
    private var interstitialAd: SwiftyAdsInterstitialType?
    private var rewardedAd: SwiftyAdsRewardedType?
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
    
    // MARK: - Init
    
    private override init() {
        mobileAds = .sharedInstance()
        intervalTracker = SwiftyAdsIntervalTracker()
        super.init()
        
    }
    
    init(mobileAds: GADMobileAds,
         bannerAd: SwiftyAdsBannerType,
         interstitialAd: SwiftyAdsInterstitialType,
         rewardedAd: SwiftyAdsRewardedType,
         consentManager: SwiftyAdsConsentManagerType,
         intervalTracker: SwiftyAdsIntervalTrackerType) {
        self.mobileAds = mobileAds
        self.bannerAd = bannerAd
        self.interstitialAd = interstitialAd
        self.rewardedAd = rewardedAd
        self.consentManager = consentManager
        self.intervalTracker = intervalTracker
    }
}

// MARK: - SwiftyAdType

extension SwiftyAds: SwiftyAdsType {
    
    /// Check if user has given consent e.g to hide rewarded video button
    /// Also returns true if used is outside EEA and is therefore not required to provide consent
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
    /// - parameter mode: Set the mode of ads, production or debug.
    /// - parameter consentStyle: The style of the consent alert.
    /// - parameter consentStatusDidChange: A handler that will fire everytime the consent status has changed.
    /// - parameter completion: A handler that will return the current consent status after the consent alert has been dismissed.
    public func setup(with viewController: UIViewController,
                      mode: SwiftyAdsMode,
                      consentStyle: SwiftyAdsConsentStyle,
                      consentStatusDidChange: @escaping (SwiftyAdsConsentStatus) -> Void,
                      completion: @escaping (SwiftyAdsConsentStatus) -> Void) {
        // Update configuration for selected mode
        let configuration: SwiftyAdsConfiguration
        switch mode {
        case .production:
            configuration = .production
        case .debug(let testDeviceIdentifiers):
            configuration = .debug
            mobileAds.requestConfiguration.testDeviceIdentifiers = testDeviceIdentifiers//kGADSimulatorID
        }
        
        // Create ads
        bannerAd = SwiftyAdsBanner(
            adUnitId: configuration.bannerAdUnitId,
            request: ({ [unowned self] in
                self.requestBuilder.build()
            })
        )
        
        interstitialAd = SwiftyAdsInterstitial(
            adUnitId: configuration.interstitialAdUnitId,
            request: ({ [unowned self] in
                self.requestBuilder.build()
            })
        )
        
        rewardedAd = SwiftyAdsRewarded(
            adUnitId: configuration.rewardedVideoAdUnitId,
            request: ({ [unowned self] in
                self.requestBuilder.build()
            })
        )
     
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
                consentStatusDidChange(status)
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
        guard let bannerAd = bannerAd else {
            return
        }
        
        guard !isDisabled, hasConsent else {
            return
        }
        
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
	/// - Returns: Returns `true` when actually start show, else return `false`.
    public func showInterstitial(from viewController: UIViewController,
                                 withInterval interval: Int?,
                                 onOpen: (() -> Void)?,
                                 onClose: (() -> Void)?,
                                 onError: ((Error) -> Void)?) -> Bool {
        guard let interstitialAd = interstitialAd else {
            return false
        }
        
        guard !isDisabled, hasConsent else {
            return false
        }
    
        guard intervalTracker.canShow(forInterval: interval) else {
            return false
        }
        
        interstitialAd.show(
            from: viewController,
            onOpen: onOpen,
            onClose: onClose,
            onError: onError
        )
		
		return true
    }
    
    /// Show rewarded video ad
    ///
    /// - parameter viewController: The view controller that will present the ad.
    /// - parameter onOpen: An optional callback when the banner was presented.
    /// - parameter onClose: An optional callback when the ad was dismissed.
    /// - parameter onError: An optional callback when an error has occurred.
    /// - parameter onNotReady: An optional callback when the ad was not ready.
    /// - parameter onReward: A callback when the reward has been granted.
	/// - Returns: Returns `true` when actually start show, else return `false`.
    public func showRewardedVideo(from viewController: UIViewController,
                                  onOpen: (() -> Void)?,
                                  onClose: (() -> Void)?,
                                  onError: ((Error) -> Void)?,
                                  onNotReady: (() -> Void)?,
                                  onReward: @escaping (Int) -> Void) -> Bool {
        guard let rewardedAd = rewardedAd else {
            return false
        }
        
        guard hasConsent else {
            return false
        }
        
        rewardedAd.show(
            from: viewController,
            onOpen: onOpen,
            onClose: onClose,
            onError: onError,
            onNotReady: onNotReady,
            onReward: onReward
        )
		
		return true
    }

    /// Disable ads e.g in app purchases
    public func disable() {
        isDisabled = true
        removeBanner()
        interstitialAd?.stopLoading()
    }
}
