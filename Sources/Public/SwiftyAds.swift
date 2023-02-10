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
    private let interstitialAdIntervalTracker: SwiftyAdsIntervalTrackerType
    private let rewardedInterstitialAdIntervalTracker: SwiftyAdsIntervalTrackerType

    private var configuration: SwiftyAdsConfiguration?
    private var environment: SwiftyAdsEnvironment = .production
    private var requestBuilder: SwiftyAdsRequestBuilderType?
    private var mediationConfigurator: SwiftyAdsMediationConfiguratorType?
    
    private var interstitialAd: SwiftyAdsInterstitialType?
    private var rewardedAd: SwiftyAdsRewardedType?
    private var rewardedInterstitialAd: SwiftyAdsRewardedInterstitialType?
    private var nativeAd: SwiftyAdsNativeType?
    private var consentManager: SwiftyAdsConsentManagerType?
    private var disabled = false

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
        interstitialAdIntervalTracker = SwiftyAdsIntervalTracker()
        rewardedInterstitialAdIntervalTracker = SwiftyAdsIntervalTracker()
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
    public var isTaggedForChildDirectedTreatment: Bool? {
        configuration?.isTaggedForChildDirectedTreatment
    }

    /// Returns true if configured for under age of consent (GDPR).
    public var isTaggedForUnderAgeOfConsent: Bool {
        configuration?.isTaggedForUnderAgeOfConsent ?? false
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
    /// - parameter viewController: The view controller that will present the consent alert if needed.
    /// - parameter environment: The environment for ads to be displayed.
    /// - parameter requestBuilder: The GADRequest builder.
    /// - parameter mediationConfigurator: Optional configurator to update mediation networks COPPA/GDPR consent status.
    /// - parameter consentStatusDidChange: A handler that will be called everytime the consent status has changed.
    /// - parameter completion: A completion handler that will return the current consent status after the initial consent flow has finished.
    ///
    /// - Warning:
    /// Returns .notRequired in the completion handler if consent has been disabled via SwiftyAds.plist isUMPDisabled entry.
    public func configure(from viewController: UIViewController,
                          for environment: SwiftyAdsEnvironment,
                          requestBuilder: SwiftyAdsRequestBuilderType,
                          mediationConfigurator: SwiftyAdsMediationConfiguratorType?,
                          consentStatusDidChange: @escaping (SwiftyAdsConsentStatus) -> Void,
                          completion: @escaping SwiftyAdsConsentResultHandler) {
        // Update configuration for selected environment
        let configuration: SwiftyAdsConfiguration
        switch environment {
        case .production:
            configuration = .production()
        case .development(let testDeviceIdentifiers, let consentConfiguration):
            configuration = .debug(isUMPDisabled: consentConfiguration.isDisabled)
            mobileAds.requestConfiguration.testDeviceIdentifiers = [GADSimulatorID].compactMap { $0 } + testDeviceIdentifiers
        }
        
        self.configuration = configuration
        self.environment = environment
        self.requestBuilder = requestBuilder
        self.mediationConfigurator = mediationConfigurator

        // Create ads
        if let interstitialAdUnitId = configuration.interstitialAdUnitId {
            interstitialAd = SwiftyAdsInterstitial(
                environment: environment,
                adUnitId: interstitialAdUnitId,
                request: requestBuilder.build
            )
        }

        if let rewardedAdUnitId = configuration.rewardedAdUnitId {
            rewardedAd = SwiftyAdsRewarded(
                environment: environment,
                adUnitId: rewardedAdUnitId,
                request: requestBuilder.build
            )
        }

        if let rewardedInterstitialAdUnitId = configuration.rewardedInterstitialAdUnitId {
            rewardedInterstitialAd = SwiftyAdsRewardedInterstitial(
                environment: environment,
                adUnitId: rewardedInterstitialAdUnitId,
                request: requestBuilder.build
            )
        }

        if let nativeAdUnitId = configuration.nativeAdUnitId {
            nativeAd = SwiftyAdsNative(
                environment: environment,
                adUnitId: nativeAdUnitId,
                request: requestBuilder.build
            )
        }

        // If UMP SDK is disabled skip consent flow completely
        if configuration.isUMPDisabled == true {
            /// If consent flow was skipped we need to update COPPA settings.
            updateCOPPA(for: configuration, mediationConfigurator: mediationConfigurator)
            
            /// If consent flow was skipped we can start `GADMobileAds` and preload ads.
            startMobileAdsSDK { [weak self] in
                guard let self = self else { return }
                self.loadAds()
                completion(.success(.notRequired))
            }
            return
        }

        // Create consent manager
        let consentManager = SwiftyAdsConsentManager(
            consentInformation: .sharedInstance,
            environment: environment,
            isTaggedForUnderAgeOfConsent: configuration.isTaggedForUnderAgeOfConsent ?? false,
            consentStatusDidChange: consentStatusDidChange
        )
        self.consentManager = consentManager

        // Request initial consent
        requestInitialConsent(from: viewController, consentManager: consentManager) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let consentStatus):
                /// Once initial consent flow has finished we need to update COPPA settings.
                self.updateCOPPA(for: configuration, mediationConfigurator: mediationConfigurator)
                
                /// Once initial consent flow has finished and consentStatus is not `.notRequired`
                /// we need to update GDPR settings.
                if consentStatus != .notRequired {
                    self.updateGDPR(
                        for: configuration,
                        mediationConfigurator: mediationConfigurator,
                        consentStatus: consentStatus
                    )
                }
                
                /// Once initial consent flow has finished we can start `GADMobileAds` and preload ads.
                self.startMobileAdsSDK { [weak self] in
                    guard let self = self else { return }
                    self.loadAds()
                    completion(result)
                }
            case .failure:
                completion(result)
            }
        }
    }
    
    // MARK: Consent

    /// Under GDPR users must be able to change their consent at any time.
    ///
    /// - parameter viewController: The view controller that will present the consent form.
    /// - parameter completion: A completion handler that will return the updated consent status.
    public func askForConsent(from viewController: UIViewController,
                              completion: @escaping SwiftyAdsConsentResultHandler) {
        guard let consentManager = consentManager else {
            completion(.failure(SwiftyAdsError.consentManagerNotAvailable))
            return
        }
        
        DispatchQueue.main.async {
            consentManager.requestUpdate { result in
                switch result {
                case .success:
                    DispatchQueue.main.async {
                        consentManager.showForm(from: viewController) { [weak self] result in
                            guard let self = self else { return }
                            // If consent form was used to update consentStatus
                            // we need to update GDPR settings
                            if case .success(let newConsentStatus) = result, let configuration = self.configuration {
                                self.updateGDPR(
                                    for: configuration,
                                    mediationConfigurator: self.mediationConfigurator,
                                    consentStatus: newConsentStatus
                                )
                            }
                            
                            completion(result)
                        }
                    }
                case .failure:
                    completion(result)
                }
            }
        }
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
        guard hasConsent else { return nil }

        var adUnitId: String? {
            switch adUnitIdType {
            case .plist:
                return configuration?.bannerAdUnitId
            case .custom(let id):
                if case .development = environment {
                    return configuration?.bannerAdUnitId
                }
                return id
            }
        }

        guard let validAdUnitId = adUnitId else {
            onError?(SwiftyAdsError.bannerAdMissingAdUnitId)
            return nil
        }

        let bannerAd = SwiftyAdsBanner(
            environment: environment,
            isDisabled: { [weak self] in
                self?.isDisabled ?? false
            },
            hasConsent: { [weak self] in
                self?.hasConsent ?? true
            },
            request: { [weak self] in
                self?.requestBuilder?.build() ?? GADRequest()
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
    /// - parameter interval: The interval of when to show the ad, e.g every 4th time the method is called. Set to nil to always show.
    /// - parameter onOpen: An optional callback when the ad was presented.
    /// - parameter onClose: An optional callback when the ad was dismissed.
    /// - parameter onError: An optional callback when an error has occurred.
    public func showInterstitialAd(from viewController: UIViewController,
                                   afterInterval interval: Int?,
                                   onOpen: (() -> Void)?,
                                   onClose: (() -> Void)?,
                                   onError: ((Error) -> Void)?) {
        guard !isDisabled else { return }
        guard hasConsent else { return }

        if let interval = interval {
            guard interstitialAdIntervalTracker.canShow(forInterval: interval) else { return }
        }
        
        interstitialAd?.show(
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
                               userIdentifier: String? = nil,
                               onOpen: (() -> Void)?,
                               onClose: (() -> Void)?,
                               onError: ((Error) -> Void)?,
                               onNotReady: (() -> Void)?,
                               onReward: @escaping (NSDecimalNumber) -> Void) {
        guard hasConsent else {
            onNotReady?()
            return
        }

        rewardedAd?.show(
            from: viewController,
            userIdentifier: userIdentifier,
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
    /// - parameter interval: The interval of when to show the ad, e.g every 4th time the method is called. Set to nil to always show.
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
                                           userIdentifier: String? = nil,
                                           afterInterval interval: Int?,
                                           onOpen: (() -> Void)?,
                                           onClose: (() -> Void)?,
                                           onError: ((Error) -> Void)?,
                                           onNotReady: (() -> Void)?,
                                           onReward: @escaping (NSDecimalNumber) -> Void) {
        guard !isDisabled else { return }
        guard hasConsent else {
            onNotReady?()
            return
        }

        if let interval = interval {
            guard rewardedInterstitialAdIntervalTracker.canShow(forInterval: interval) else { return }
        }

        rewardedInterstitialAd?.show(
            from: viewController,
            userIdentifier: userIdentifier,
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
        guard hasConsent else { return }

        if nativeAd == nil, case .custom(let adUnitId) = adUnitIdType {
            nativeAd = SwiftyAdsNative(
                environment: environment,
                adUnitId: adUnitId,
                request: { [weak self] in
                    self?.requestBuilder?.build() ?? GADRequest()
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
            loadAds()
        }
    }
}

// MARK: - Private Methods

private extension SwiftyAds {
    func requestInitialConsent(from viewController: UIViewController,
                               consentManager: SwiftyAdsConsentManagerType,
                               completion: @escaping SwiftyAdsConsentResultHandler) {
        DispatchQueue.main.async {
            consentManager.requestUpdate { result in
                switch result {
                case .success(let status):
                    switch status {
                    case .required:
                        DispatchQueue.main.async {
                            consentManager.showForm(from: viewController, completion: completion)
                        }
                    default:
                        completion(result)
                    }
                case .failure:
                    completion(result)
                }
            }
        }
    }
    
    func updateCOPPA(for configuration: SwiftyAdsConfiguration,
                     mediationConfigurator: SwiftyAdsMediationConfiguratorType?) {
        guard let isCOPPAEnabled = configuration.isTaggedForChildDirectedTreatment else { return }
        
        // Update mediation networks
        mediationConfigurator?.updateCOPPA(isTaggedForChildDirectedTreatment: isCOPPAEnabled)
        
        // Update GADMobileAds
        mobileAds.requestConfiguration.tag(forChildDirectedTreatment: isCOPPAEnabled)
    }
    
    func updateGDPR(for configuration: SwiftyAdsConfiguration,
                    mediationConfigurator: SwiftyAdsMediationConfiguratorType?,
                    consentStatus: SwiftyAdsConsentStatus) {
        // Update mediation networks
        //
        // The GADMobileADs tagForUnderAgeOfConsent parameter is currently NOT forwarded to ad network
        // mediation adapters.
        // It is your responsibility to ensure that each third-party ad network in your application serves
        // ads that are appropriate for users under the age of consent per GDPR.
        mediationConfigurator?.updateGDPR(
            for: consentStatus,
            isTaggedForUnderAgeOfConsent: configuration.isTaggedForUnderAgeOfConsent ?? false
        )
        
        // Update GADMobileAds
        //
        // The tags to enable the child-directed setting and tagForUnderAgeOfConsent
        // should not both simultaneously be set to true.
        // If they are, the child-directed setting takes precedence.
        // https://developers.google.com/admob/ios/targeting#child-directed_setting
        if let isCOPPAEnabled = configuration.isTaggedForChildDirectedTreatment, isCOPPAEnabled {
            return
        }

        if let isTaggedForUnderAgeOfConsent = configuration.isTaggedForUnderAgeOfConsent {
            mobileAds.requestConfiguration.tagForUnderAge(ofConsent: isTaggedForUnderAgeOfConsent)
        }
    }
    
    func startMobileAdsSDK(completion: @escaping () -> Void) {
        /*
         Warning:
         Ads may be preloaded by the Mobile Ads SDK or mediation partner SDKs upon
         calling startWithCompletionHandler:. If you need to obtain consent from users
         in the European Economic Area (EEA), set any request-specific flags (such as
         tagForChildDirectedTreatment or tag_for_under_age_of_consent), or otherwise
         take action before loading ads, ensure you do so before initializing the Mobile
         Ads SDK.
        */
        mobileAds.start { [weak self] initializationStatus in
            guard let self = self else { return }
            if case .development = self.environment {
                print("SwiftyAds initialization status", initializationStatus.adapterStatusesByClassName)
            }
            completion()
        }
    }
    
    func loadAds() {
        rewardedAd?.load()
        guard !isDisabled else { return }
        interstitialAd?.load()
        rewardedInterstitialAd?.load()
    }
}

// MARK: - Deprecated

public extension SwiftyAds {
    @available(*, deprecated, message: "Use `setDisabled` instead")
    func disable(_ isDisabled: Bool) {
        setDisabled(isDisabled)
    }
}
