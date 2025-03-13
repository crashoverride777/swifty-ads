//    The MIT License (MIT)
//
//    Copyright (c) 2015-2025 Dominik Ringler
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

@preconcurrency import GoogleMobileAds
import UserMessagingPlatform

/**
 SwiftyAds
 
 A concret class implementation of SwiftAdsType to display ads from Google AdMob.
 */
public final class SwiftyAds: NSObject, @unchecked Sendable {
    
    // MARK: - Static Properties
    
    /// The shared SwiftyAds instance.
    public static let shared = SwiftyAds()
    
    // MARK: - Properties
    
    private let mobileAds: MobileAds
    
    private var configuration: SwiftyAdsConfiguration?
    private var requestBuilder: SwiftyAdsRequestBuilder?
    private var mediationConfigurator: SwiftyAdsMediationConfigurator?
    private var environment: SwiftyAdsEnvironment = .production
    
    private var interstitialAd: SwiftyAdsInterstitialAd?
    private var rewardedAd: SwiftyAdsRewardedAd?
    private var rewardedInterstitialAd: SwiftyAdsRewardedInterstitialAd?
    private var nativeAd: SwiftyAdsNativeAd?
    private var consentManager: SwiftyAdsConsentManager?
    private var disabled = false
    private var hasInitializedMobileAds = false
    
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
        mobileAds = .shared
        super.init()
    }
}

// MARK: - SwiftyAdsType

extension SwiftyAds: SwiftyAdsType {
    /// The current consent status.
    public var consentStatus: SwiftyAdsConsentStatus {
        consentManager?.consentStatus ?? .notRequired
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
    @MainActor
    public func configure(requestBuilder: SwiftyAdsRequestBuilder, mediationConfigurator: SwiftyAdsMediationConfigurator?) {
        // Update configuration for selected environment
        let configuration: SwiftyAdsConfiguration
        switch environment {
        case .production:
            configuration = .production(bundle: .main)
        case .development(let developmentSettings):
            configuration = .debug(for: developmentSettings)
            mobileAds.requestConfiguration.testDeviceIdentifiers = developmentSettings.testDeviceIdentifiers
        }
        
        self.configuration = configuration
        self.requestBuilder = requestBuilder
        self.mediationConfigurator = mediationConfigurator
        
        // Create ads
        createAds(with: configuration, requestBuilder: requestBuilder)
        
        // Update for COPPA if needed
        if let isTaggedForChildDirectedTreatment = configuration.isTaggedForChildDirectedTreatment {
            mediationConfigurator?.updateCOPPA(isTaggedForChildDirectedTreatment: isTaggedForChildDirectedTreatment)
            mobileAds.requestConfiguration.tagForChildDirectedTreatment = NSNumber(value: isTaggedForChildDirectedTreatment)
        }
        
        // Create consent manager.
        if let isTaggedForUnderAgeOfConsent = configuration.isTaggedForUnderAgeOfConsent {
            consentManager = DefaultSwiftyAdsConsentManager(
                isTaggedForChildDirectedTreatment: configuration.isTaggedForChildDirectedTreatment ?? false,
                isTaggedForUnderAgeOfConsent: isTaggedForUnderAgeOfConsent,
                mediationConfigurator: mediationConfigurator,
                environment: environment,
                mobileAds: mobileAds
            )
        }
    }
    
    // MARK: Initialize
    
    /// Initializes SwiftyAds with its configuration.
    @MainActor
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
        try await loadAdsIfNeeded()
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
    /// - returns SwiftyAdsBannerAd to show, hide or remove the prepared banner ad.
    @MainActor
    public func makeBannerAd(in viewController: UIViewController,
                             adUnitIdType: SwiftyAdsAdUnitIdType,
                             position: SwiftyAdsBannerAdPosition,
                             animation: SwiftyAdsBannerAdAnimation,
                             onOpen: (() -> Void)?,
                             onClose: (() -> Void)?,
                             onError: ((Error) -> Void)?,
                             onWillPresentScreen: (() -> Void)?,
                             onWillDismissScreen: (() -> Void)?,
                             onDidDismissScreen: (() -> Void)?) -> SwiftyAdsBannerAd? {
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

        let bannerAd = GADSwiftyAdsBannerAd(
            environment: environment,
            isDisabled: { [weak self] in
                self?.isDisabled ?? false
            },
            hasConsent: { [weak self] in
                self?.hasConsent ?? true
            },
            request: { [weak self] in
                self?.requestBuilder?.build() ?? Request()
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
    @MainActor
    public func showInterstitialAd(from viewController: UIViewController,
                                   onOpen: (() -> Void)?,
                                   onClose: (() -> Void)?,
                                   onError: ((Error) -> Void)?) async throws {
        guard !isDisabled else { return }
        
        guard let interstitialAd else {
            throw SwiftyAdsError.notConfigured
        }
        
        guard hasConsent else {
            throw SwiftyAdsError.consentNotObtained
        }
        
        try await interstitialAd.show(
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
    @MainActor
    public func showRewardedAd(from viewController: UIViewController,
                               onOpen: (() -> Void)?,
                               onClose: (() -> Void)?,
                               onError: ((Error) -> Void)?,
                               onReward: @escaping (NSDecimalNumber) -> Void) async throws {
        guard let rewardedAd else {
            throw SwiftyAdsError.notConfigured
        }
        
        guard hasConsent else {
            throw SwiftyAdsError.consentNotObtained
        }

        try await rewardedAd.show(
            from: viewController,
            onOpen: onOpen,
            onClose: onClose,
            onError: onError,
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
    @MainActor
    public func showRewardedInterstitialAd(from viewController: UIViewController,
                                           onOpen: (() -> Void)?,
                                           onClose: (() -> Void)?,
                                           onError: ((Error) -> Void)?,
                                           onReward: @escaping (NSDecimalNumber) -> Void) async throws {
        guard !isDisabled else { return }
        
        guard let rewardedInterstitialAd else {
            throw SwiftyAdsError.notConfigured
        }

        guard hasConsent else {
            throw SwiftyAdsError.consentNotObtained
        }

        try await rewardedInterstitialAd.show(
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
    @MainActor
    public func loadNativeAd(from viewController: UIViewController,
                             adUnitIdType: SwiftyAdsAdUnitIdType,
                             loaderOptions: SwiftyAdsNativeAdLoaderOptions,
                             onFinishLoading: (() -> Void)?,
                             onError: ((Error) -> Void)?,
                             onReceive: @escaping (NativeAd) -> Void) {
        guard !isDisabled else { return }
        
        guard hasConsent else {
            onError?(SwiftyAdsError.consentNotObtained)
            return
        }

        if nativeAd == nil, case .custom(let adUnitId) = adUnitIdType {
            nativeAd = GADSwiftyAdsNativeAd(
                adUnitId: adUnitId,
                environment: environment,
                request: { [weak self] in
                    self?.requestBuilder?.build() ?? Request()
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
    
    // MARK: Consent
    
    /// Under GDPR users must be able to change their consent at any time.
    ///
    /// - parameter viewController: The view controller that will present the consent form.
    /// - returns SwiftyAdsConsentStatus
    @MainActor
    public func updateConsent(from viewController: UIViewController) async throws -> SwiftyAdsConsentStatus {
        guard let consentManager = consentManager else {
            throw SwiftyAdsError.consentManagerNotAvailable
        }
        
        try await consentManager.request(from: viewController)
        return consentManager.consentStatus
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
            Task { [weak self] in
                try await self?.loadAdsIfNeeded()
            }
        }
    }
    
    // MARK: Load Ads If Needed
    
    /// Preloads ads if needed e.g. offline/online changes.
    public func loadAdsIfNeeded() async throws {
        if let rewardedAd, !rewardedAd.isReady {
            try await rewardedAd.load()
        }
        
        guard !isDisabled else {
            return
        }
        
        if let interstitialAd, !interstitialAd.isReady {
            try await interstitialAd.load()
        }
        
        if let rewardedInterstitialAd, !rewardedInterstitialAd.isReady {
            try await rewardedInterstitialAd.load()
        }
    }
    
    // MARK: - DEBUG
    
    #if DEBUG
    /// Enable debugging. Should be called before `configure`.
    public func enableDebug(testDeviceIdentifiers: [String], 
                            geography: UMPDebugGeography,
                            resetsConsentOnLaunch: Bool,
                            isTaggedForChildDirectedTreatment: Bool?,
                            isTaggedForUnderAgeOfConsent: Bool?) {
        let developmentSettings = SwiftyAdsEnvironment.DevelopmentSettings(
            testDeviceIdentifiers: testDeviceIdentifiers,
            geography: geography,
            resetsConsentOnLaunch: resetsConsentOnLaunch,
            isTaggedForChildDirectedTreatment: isTaggedForChildDirectedTreatment,
            isTaggedForUnderAgeOfConsent: isTaggedForUnderAgeOfConsent
        )
        environment = .development(developmentSettings)
    }
    #endif
}

// MARK: - Private Methods

private extension SwiftyAds {
    func createAds(with configuration: SwiftyAdsConfiguration, requestBuilder: SwiftyAdsRequestBuilder) {
        if let interstitialAdUnitId = configuration.interstitialAdUnitId {
            interstitialAd = GADSwiftyAdsInterstitialAd(
                adUnitId: interstitialAdUnitId,
                environment: environment,
                request: requestBuilder.build
            )
        }

        if let rewardedAdUnitId = configuration.rewardedAdUnitId {
            rewardedAd = GADSwiftyAdsRewardedAd(
                adUnitId: rewardedAdUnitId,
                environment: environment,
                request: requestBuilder.build
            )
        }

        if let rewardedInterstitialAdUnitId = configuration.rewardedInterstitialAdUnitId {
            rewardedInterstitialAd = GADSwiftyAdsRewardedInterstitialAd(
                adUnitId: rewardedInterstitialAdUnitId,
                environment: environment,
                request: requestBuilder.build
            )
        }

        if let nativeAdUnitId = configuration.nativeAdUnitId {
            nativeAd = GADSwiftyAdsNativeAd(
                adUnitId: nativeAdUnitId,
                environment: environment,
                request: requestBuilder.build
            )
        }
    }
}
