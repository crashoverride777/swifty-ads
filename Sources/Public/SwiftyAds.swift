//    The MIT License (MIT)
//
//    Copyright (c) 2015-2024 Dominik Ringler
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

/**
 SwiftyAds
 
 A concret class implementation of SwiftAdsType to display ads from Google AdMob.
 */
public final class SwiftyAds: NSObject {
    
    // MARK: - Static Properties
    
    /// The shared SwiftyAds instance.
    public static let shared = SwiftyAds()
    
    // MARK: - Properties
    
    private let mobileAds: GADMobileAds
    
    private var configuration: SwiftyAdsConfiguration?
    private var requestBuilder: SwiftyAdsRequestBuilderType?
    private var mediationConfigurator: SwiftyAdsMediationConfiguratorType?
    private var environment: SwiftyAdsEnvironment = .production
    
    private var interstitialAd: SwiftyAdsInterstitialType?
    private var rewardedAd: SwiftyAdsRewardedType?
    private var rewardedInterstitialAd: SwiftyAdsRewardedInterstitialType?
    private var nativeAd: SwiftyAdsNativeType?
    private var consentManager: SwiftyAdsConsentManagerType?
    private var disabled = false
    private var hasInitializedMobileAds = false
    
    private var consentStatusDidChange: ((SwiftyAdsConsentStatus) -> Void)?
    
    private var hasConsent: Bool {
        switch consentStatus {
        case .notRequired, .obtained:
            return true
        default:
            return false
        }
    }
    
    // MARK: - Initialization
    
    private override init() {
        mobileAds = .sharedInstance()
        super.init()
    }
}

// MARK: - SwiftyAdsType

extension SwiftyAds: SwiftyAdsType {
    /// The current consent status.
    ///
    /// - Warning:
    /// Returns .notRequired if consent has been disabled via SwiftyAds.plist isUMPDisabled entry.
    public var consentStatus: SwiftyAdsConsentStatus {
        consentManager?.consentStatus ?? .notRequired
    }

    /// Returns true if configured for child directed treatment or nil if ignored (COPPA).
    public var isTaggedForChildDirectedTreatment: Bool {
        consentManager?.isTaggedForChildDirectedTreatment ?? false
    }

    /// Returns true if configured for under age of consent (GDPR).
    public var isTaggedForUnderAgeOfConsent: Bool {
        consentManager?.isTaggedForUnderAgeOfConsent ?? false
    }
     
    /// Check if interstitial ad is ready to be displayed.
    public var isInterstitialAdReady: Bool {
        interstitialAd?.isReady ?? false
    }
     
    /// Check if rewarded ad is ready to be displayed.
    public var isRewardedAdReady: Bool {
        rewardedAd?.isReady ?? false
    }

    /// Check if rewarded interstitial ad is ready to be displayed.
    public var isRewardedInterstitialAdReady: Bool {
        rewardedInterstitialAd?.isReady ?? false
    }

    /// Returns true if ads have been disabled.
    public var isDisabled: Bool {
        disabled
    }

    // MARK: Configure
    
    /// Configure SwiftyAds
    ///
    /// - parameter requestBuilder: The GADRequest builder.
    /// - parameter mediationConfigurator: Optional configurator to update mediation networks..
    /// - parameter bundle: The bundle to search for the SwiftyAds plist's files. Defaults to main bundle.
    ///
    /// - Warning:
    /// Returns .notRequired in the completion handler if consent has been disabled via SwiftyAds.plist isUMPDisabled entry.
    public func configure(requestBuilder: SwiftyAdsRequestBuilderType,
                          mediationConfigurator: SwiftyAdsMediationConfiguratorType?,
                          bundle: Bundle = .main) {
        // Update configuration for selected environment
        let configuration: SwiftyAdsConfiguration
        let consentConfiguration: SwiftyAdsConsentConfiguration?
        switch environment {
        case .production:
            configuration = .production(bundle: bundle)
            consentConfiguration = .production(bundle: bundle)
        case .development(let testDeviceIdentifiers, _, _):
            configuration = .debug
            consentConfiguration = .debug
            mobileAds.requestConfiguration.testDeviceIdentifiers = testDeviceIdentifiers
        }
        
        self.configuration = configuration
        self.requestBuilder = requestBuilder
        self.mediationConfigurator = mediationConfigurator
        
        // Create ads
        if let interstitialAdUnitId = configuration.interstitialAdUnitId {
            interstitialAd = SwiftyAdsInterstitial(
                adUnitId: interstitialAdUnitId,
                request: requestBuilder.build,
                environment: { [weak self] in
                    self?.environment ?? .production
                }
            )
        }

        if let rewardedAdUnitId = configuration.rewardedAdUnitId {
            rewardedAd = SwiftyAdsRewarded(
                adUnitId: rewardedAdUnitId,
                request: requestBuilder.build,
                environment: { [weak self] in
                    self?.environment ?? .production
                }
            )
        }

        if let rewardedInterstitialAdUnitId = configuration.rewardedInterstitialAdUnitId {
            rewardedInterstitialAd = SwiftyAdsRewardedInterstitial(
                adUnitId: rewardedInterstitialAdUnitId,
                request: requestBuilder.build,
                environment: { [weak self] in
                    self?.environment ?? .production
                }
            )
        }

        if let nativeAdUnitId = configuration.nativeAdUnitId {
            nativeAd = SwiftyAdsNative(
                adUnitId: nativeAdUnitId,
                request: requestBuilder.build,
                environment: { [weak self] in
                    self?.environment ?? .production
                }
            )
        }
        
        // Create consent manager.
        if let consentConfiguration {
            consentManager = SwiftyAdsConsentManager(
                configuration: consentConfiguration,
                mediationConfigurator: mediationConfigurator,
                mobileAds: mobileAds,
                environment: { [weak self] in
                    self?.environment ?? .production
                },
                consentStatusDidChange: { [weak self] status in
                    self?.consentStatusDidChange?(status)
                }
            )
        }
    }
    
    // MARK: Initialize
    
    /// Initializes SwiftyAds with its configuration.
    public func initializeIfNeeded(from viewController: UIViewController) async throws {
        guard !hasInitializedMobileAds else { return }
        
        if let consentManager {
            try await consentManager.request(from: viewController)
        }
        /*
         Ads may be preloaded by the Mobile Ads SDK or mediation partner SDKs upon
         calling startWithCompletionHandler:. If you need to obtain consent from users
         in the European Economic Area (EEA), set any request-specific flags (such as
         tagForChildDirectedTreatment or tag_for_under_age_of_consent), or otherwise
         take action before loading ads, ensure you do so before initializing the Mobile
         Ads SDK.
        */
        let initializationStatus = await mobileAds.start()
        hasInitializedMobileAds = true
        if case .development = environment {
            print("SwiftyAds initialization status", initializationStatus.adapterStatusesByClassName)
        }
        loadAdsIfNeeded()
    }
    
    // MARK: Banner Ads
    
    /// Make banner ad
    ///
    /// - parameter viewController: The view controller that will present the ad.
    /// - parameter adUnitIdType: The adUnitId type for the ad, either plist or custom.
    /// - parameter position: The position of the banner.
    /// - parameter animation: The animation of the banner.
    /// - parameter onOpen: An optional callback when the banner was presented.
    /// - parameter onClose: An optional callback when the banner was dismissed or removed.
    /// - parameter onError: An optional callback when an error has occurred.
    /// - parameter onWillPresentScreen: An optional callback when the banner was tapped and is about to present a screen.
    /// - parameter onWillDismissScreen: An optional callback when the banner is about dismiss a presented screen.
    /// - parameter onDidDismissScreen: An optional callback when the banner did dismiss a presented screen.
    /// - returns SwiftyAdsBannerType to show, hide or remove the prepared banner ad.
    public func makeBannerAd(in viewController: UIViewController,
                             adUnitIdType: SwiftyAdsAdUnitIdType,
                             position: SwiftyAdsBannerAdPosition,
                             animation: SwiftyAdsBannerAdAnimation,
                             onOpen: (() -> Void)?,
                             onClose: (() -> Void)?,
                             onError: ((Error) -> Void)?,
                             onWillPresentScreen: (() -> Void)?,
                             onWillDismissScreen: (() -> Void)?,
                             onDidDismissScreen: (() -> Void)?) -> SwiftyAdsBannerType? {
        guard !isDisabled else { return nil }
        
        guard let configuration = configuration else {
            onError?(SwiftyAdsError.notConfigured)
            return nil
        }
        
        guard hasConsent else {
            onError?(SwiftyAdsError.consentNotObtained)
            return nil
        }
        
        var adUnitId: String? {
            switch adUnitIdType {
            case .plist:
                return configuration.bannerAdUnitId
            case .custom(let id):
                if case .development = environment {
                    return configuration.bannerAdUnitId
                }
                return id
            }
        }

        guard let validAdUnitId = adUnitId else {
            onError?(SwiftyAdsError.bannerAdMissingAdUnitId)
            return nil
        }

        let bannerAd = SwiftyAdsBanner(
            isDisabled: { [weak self] in
                self?.isDisabled ?? false
            },
            hasConsent: { [weak self] in
                self?.hasConsent ?? true
            },
            request: { [weak self] in
                self?.requestBuilder?.build() ?? GADRequest()
            },
            environment: { [weak self] in
                self?.environment ?? .production
            }
        )

        bannerAd.prepare(
            withAdUnitId: validAdUnitId,
            in: viewController,
            position: position,
            animation: animation,
            onOpen: onOpen,
            onClose: onClose,
            onError: onError,
            onWillPresentScreen: onWillPresentScreen,
            onWillDismissScreen: onWillDismissScreen,
            onDidDismissScreen: onDidDismissScreen
        )

        return bannerAd
    }

    // MARK: Interstitial Ads
    
    /// Show interstitial ad
    ///
    /// - parameter viewController: The view controller that will present the ad.
    /// - parameter onOpen: An optional callback when the ad was presented.
    /// - parameter onClose: An optional callback when the ad was dismissed.
    /// - parameter onError: An optional callback when an error has occurred.
    public func showInterstitialAd(from viewController: UIViewController,
                                   onOpen: (() -> Void)?,
                                   onClose: (() -> Void)?,
                                   onError: ((Error) -> Void)?) {
        guard !isDisabled else { return }
        
        guard let interstitialAd else {
            onError?(SwiftyAdsError.notConfigured)
            return
        }
        
        guard hasConsent else {
            onError?(SwiftyAdsError.consentNotObtained)
            return
        }
        
        interstitialAd.show(
            from: viewController,
            onOpen: onOpen,
            onClose: onClose,
            onError: onError
        )
    }

    // MARK: Rewarded Ads
    
    /// Show rewarded ad
    ///
    /// - parameter viewController: The view controller that will present the ad.
    /// - parameter onOpen: An optional callback when the ad was presented.
    /// - parameter onClose: An optional callback when the ad was dismissed.
    /// - parameter onError: An optional callback when an error has occurred.
    /// - parameter onNotReady: An optional callback when the ad was not ready.
    /// - parameter onReward: A callback when the reward has been granted.
    ///
    /// - Warning:
    /// Rewarded ads may be non-skippable and should only be displayed after pressing a dedicated button.
    public func showRewardedAd(from viewController: UIViewController,
                               onOpen: (() -> Void)?,
                               onClose: (() -> Void)?,
                               onError: ((Error) -> Void)?,
                               onNotReady: (() -> Void)?,
                               onReward: @escaping (NSDecimalNumber) -> Void) {
        guard let rewardedAd else {
            onError?(SwiftyAdsError.notConfigured)
            return
        }
        
        guard hasConsent else {
            onError?(SwiftyAdsError.consentNotObtained)
            return
        }

        rewardedAd.show(
            from: viewController,
            onOpen: onOpen,
            onClose: onClose,
            onError: onError,
            onNotReady: onNotReady,
            onReward: onReward
        )
    }

    /// Show rewarded interstitial ad
    ///
    /// - parameter viewController: The view controller that will present the ad.
    /// - parameter onOpen: An optional callback when the ad was presented.
    /// - parameter onClose: An optional callback when the ad was dismissed.
    /// - parameter onError: An optional callback when an error has occurred.
    /// - parameter onReward: A callback when the reward has been granted.
    ///
    /// - Warning:
    /// Before displaying a rewarded interstitial ad to users, you must present the user with an intro screen that provides clear reward messaging
    /// and an option to skip the ad before it starts.
    /// https://support.google.com/admob/answer/9884467
    public func showRewardedInterstitialAd(from viewController: UIViewController,
                                           onOpen: (() -> Void)?,
                                           onClose: (() -> Void)?,
                                           onError: ((Error) -> Void)?,
                                           onReward: @escaping (NSDecimalNumber) -> Void) {
        guard !isDisabled else { return }
        
        guard let rewardedInterstitialAd else {
            onError?(SwiftyAdsError.notConfigured)
            return
        }

        guard hasConsent else {
            onError?(SwiftyAdsError.consentNotObtained)
            return
        }

        rewardedInterstitialAd.show(
            from: viewController,
            onOpen: onOpen,
            onClose: onClose,
            onError: onError,
            onReward: onReward
        )
    }

    // MARK: Native Ads

    /// Load native ad
    ///
    /// - parameter viewController: The view controller that will load the native ad.
    /// - parameter adUnitIdType: The adUnitId type for the ad, either plist or custom.
    /// - parameter loaderOptions: The loader options for GADMultipleAdsAdLoaderOptions, single or multiple.
    /// - parameter onFinishLoading: An optional callback when the load request has finished.
    /// - parameter onError: An optional callback when an error has occurred.
    /// - parameter onReceive: A callback when the GADNativeAd has been received.
    ///
    /// - Warning:
    /// Requests for multiple native ads don't currently work for AdMob ad unit IDs that have been configured for mediation.
    /// Publishers using mediation should avoid using the GADMultipleAdsAdLoaderOptions class when making requests i.e. set loaderOptions parameter to .single.
    public func loadNativeAd(from viewController: UIViewController,
                             adUnitIdType: SwiftyAdsAdUnitIdType,
                             loaderOptions: SwiftyAdsNativeAdLoaderOptions,
                             onFinishLoading: (() -> Void)?,
                             onError: ((Error) -> Void)?,
                             onReceive: @escaping (GADNativeAd) -> Void) {
        guard !isDisabled else { return }
        
        guard hasConsent else {
            onError?(SwiftyAdsError.consentNotObtained)
            return
        }

        if nativeAd == nil, case .custom(let adUnitId) = adUnitIdType {
            nativeAd = SwiftyAdsNative(
                adUnitId: adUnitId,
                request: { [weak self] in
                    self?.requestBuilder?.build() ?? GADRequest()
                },
                environment: { [weak self] in
                    self?.environment ?? .production
                }
            )
        }

        nativeAd?.load(
            from: viewController,
            adUnitIdType: adUnitIdType,
            loaderOptions: loaderOptions,
            adTypes: [.native],
            onFinishLoading: onFinishLoading,
            onError: onError,
            onReceive: onReceive
        )
    }

    // MARK: Enable/Disable

    /// Enable/Disable ads
    ///
    /// - parameter isDisabled: Set to true to disable ads or false to enable ads.
    public func setDisabled(_ isDisabled: Bool) {
        disabled = isDisabled
        if isDisabled {
            interstitialAd?.stopLoading()
            rewardedInterstitialAd?.stopLoading()
            nativeAd?.stopLoading()
        } else {
            loadAdsIfNeeded()
        }
    }
    
    // MARK: Load Ads If Needed
    
    /// Preloads ads if needed e.g. offline/online changes.
    public func loadAdsIfNeeded() {
        if let rewardedAd, !rewardedAd.isReady {
            rewardedAd.load()
        }
        
        guard !isDisabled else {
            return
        }
        
        if let interstitialAd, !interstitialAd.isReady {
            interstitialAd.load()
        }
        
        if let rewardedInterstitialAd, !rewardedInterstitialAd.isReady {
            rewardedInterstitialAd.load()
        }
    }
    
    // MARK: Consent
    
    /// Observe consent status changes
    ///
    /// - parameter onStatusChange: A completion hander that is called every time consent status changes.
    public func observeConsentStatus(onStatusChange: @escaping (SwiftyAdsConsentStatus) -> Void) {
        self.consentStatusDidChange = onStatusChange
    }

    /// Under GDPR users must be able to change their consent at any time.
    ///
    /// - parameter viewController: The view controller that will present the consent form.
    /// - returns SwiftyAdsConsentStatus
    public func askForConsent(from viewController: UIViewController) async throws -> SwiftyAdsConsentStatus {
        guard let consentManager = consentManager else {
            throw SwiftyAdsError.consentManagerNotAvailable
        }
        
        return try await consentManager.request(from: viewController)
    }
    
    // MARK: - DEBUG
    
    #if DEBUG
    /// Enable debugging. Should be called before `configure`.
    public func enableDebug(testDeviceIdentifiers: [String], geography: UMPDebugGeography, resetsConsentOnLaunch: Bool) {
        environment = .development(
            testDeviceIdentifiers: testDeviceIdentifiers,
            geography: geography,
            resetsConsentOnLaunch: resetsConsentOnLaunch
        )
    }
    #endif
}
