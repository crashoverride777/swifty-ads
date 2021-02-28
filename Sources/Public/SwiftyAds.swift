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
    private let requestBuilder: SwiftyAdsRequestBuilderType
    private let interstitialAdIntervalTracker: SwiftyAdsIntervalTrackerType
    private let rewardedInterstitialAdIntervalTracker: SwiftyAdsIntervalTrackerType

    private var configuration: SwiftyAdsConfiguration?
    private var environment: SwiftyAdsEnvironment = .production
    private var interstitialAd: SwiftyAdsInterstitialType?
    private var rewardedAd: SwiftyAdsRewardedType?
    private var rewardedInterstitialAd: SwiftyAdsRewardedInterstitialType?
    private var nativeAd: SwiftyAdsNativeType?
    private var consentManager: SwiftyAdsConsentManagerType?
    private var disabled = false

    private var hasConsent: Bool {
        guard let consentManager = consentManager else { return true }
        switch consentManager.consentStatus {
        case .notRequired, .obtained:
            return true
        default:
            return false
        }
    }
    
    // MARK: - Initialization
    
    private override init() {
        mobileAds = .sharedInstance()
        requestBuilder = SwiftyAdsRequestBuilder()
        interstitialAdIntervalTracker = SwiftyAdsIntervalTracker()
        rewardedInterstitialAdIntervalTracker = SwiftyAdsIntervalTracker()
        super.init()
        
    }
}

// MARK: - SwiftyAdsType

extension SwiftyAds: SwiftyAdsType {

    /// The current consent status.
    public var consentStatus: SwiftyAdsConsentStatus {
        consentManager?.consentStatus ?? .unknown
    }

    /// The type of consent provided when not using IAB TCF v2 framework.
    ///
    /// - Warning:
    /// Always returns unknown if using IAB TCF v2 framework
    /// https://stackoverflow.com/questions/63415275/obtaining-consent-with-the-user-messaging-platform-android
    public var consentType: SwiftyAdsConsentType {
        consentManager?.consentType ?? .unknown
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
    /// - parameter consentStatusDidChange: A handler that will be called everytime the consent status has changed.
    /// - parameter completion: A completion handler that will return the current consent status after the initial consent flow has finished.
    public func configure(from viewController: UIViewController,
                          for environment: SwiftyAdsEnvironment,
                          consentStatusDidChange: @escaping (SwiftyAdsConsentStatus) -> Void,
                          completion: @escaping SwiftyAdsConsentResultHandler) {
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
        self.configuration = configuration
        self.environment = environment

        // Tag for child directed treatment if needed (COPPA)
        if let isTaggedForChildDirectedTreatment = configuration.isTaggedForChildDirectedTreatment {
            mobileAds.requestConfiguration.tag(forChildDirectedTreatment: isTaggedForChildDirectedTreatment)
        }

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

        // Create consent manager
        let consentManager = SwiftyAdsConsentManager(
            consentInformation: .sharedInstance,
            configuration: configuration,
            environment: environment,
            mobileAds: mobileAds,
            consentStatusDidChange: consentStatusDidChange
        )
        self.consentManager = consentManager

        // Request initial consent
        requestInitialConsent(from: viewController, consentManager: consentManager, completion: completion)
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
                        consentManager.showForm(from: viewController, completion: completion)
                    }
                case .failure(let error):
                    completion(.failure(error))
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
                if case .debug = environment {
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
            request: requestBuilder.build
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
                               onOpen: (() -> Void)?,
                               onClose: (() -> Void)?,
                               onError: ((Error) -> Void)?,
                               onNotReady: (() -> Void)?,
                               onReward: @escaping (Int) -> Void) {
        guard hasConsent else { return }

        rewardedAd?.show(
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
                                           afterInterval interval: Int?,
                                           onOpen: (() -> Void)?,
                                           onClose: (() -> Void)?,
                                           onError: ((Error) -> Void)?,
                                           onReward: @escaping (Int) -> Void) {
        guard !isDisabled else { return }
        guard hasConsent else { return }

        if let interval = interval {
            guard rewardedInterstitialAdIntervalTracker.canShow(forInterval: interval) else { return }
        }

        rewardedInterstitialAd?.show(
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
        guard hasConsent else { return }

        if nativeAd == nil, case .custom(let adUnitId) = adUnitIdType {
            nativeAd = SwiftyAdsNative(
                environment: environment,
                adUnitId: adUnitId,
                request: { [unowned self] in
                    self.requestBuilder.build()
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

    // MARK: Disable

    /// Disable ads
    public func disable() {
        disabled = true
        interstitialAd?.stopLoading()
        rewardedInterstitialAd?.stopLoading()
        nativeAd?.stopLoading()
    }
}

// MARK: - Private Methods

private extension SwiftyAds {

    func requestInitialConsent(from viewController: UIViewController,
                               consentManager: SwiftyAdsConsentManagerType,
                               completion: @escaping SwiftyAdsConsentResultHandler) {
        DispatchQueue.main.async {
            consentManager.requestUpdate { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let status):
                    switch status {
                    case .obtained, .notRequired:
                        self.loadAds()
                        completion(.success(status))
                    case .required:
                        DispatchQueue.main.async {
                            consentManager.showForm(from: viewController) { [weak self] result in
                                guard let self = self else { return }
                                switch result {
                                case .success(let status):
                                    if status == .obtained || status == .notRequired {
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

    func loadAds() {
        rewardedAd?.load()
        guard !isDisabled else { return }
        interstitialAd?.load()
    }
}

// MARK: - Deprecated

public extension SwiftyAds {

    @available(*, deprecated, message: "Please use configure method")
    func setup(from viewController: UIViewController,
               for environment: SwiftyAdsEnvironment,
               consentStatusDidChange: @escaping (SwiftyAdsConsentStatus) -> Void,
               completion: @escaping SwiftyAdsConsentResultHandler) {
        configure(
            from: viewController,
            for: environment,
            consentStatusDidChange: consentStatusDidChange,
            completion: completion
        )
    }

    @available(*, deprecated, message: "Please use new makeBanner method")
    func makeBannerAd(in viewController: UIViewController,
                      adUnitIdType: SwiftyAdsAdUnitIdType,
                      position: SwiftyAdsBannerAdPosition,
                      animationDuration: TimeInterval,
                      onOpen: (() -> Void)?,
                      onClose: (() -> Void)?,
                      onError: ((Error) -> Void)?) -> SwiftyAdsBannerType? {
        makeBannerAd(
            in: viewController,
            adUnitIdType: adUnitIdType,
            position: position,
            animation: .slide(duration: animationDuration),
            onOpen: onOpen,
            onClose: onClose,
            onError: onError,
            onWillPresentScreen: nil,
            onWillDismissScreen: nil,
            onDidDismissScreen: nil
        )
    }

    @available(*, deprecated, message: "Please use new loadNativeAd method")
    func loadNativeAd(from viewController: UIViewController,
                      adUnitIdType: SwiftyAdsAdUnitIdType,
                      count: Int?,
                      onReceive: @escaping (GADNativeAd) -> Void,
                      onError: @escaping (Error) -> Void) {
        loadNativeAd(
            from: viewController,
            adUnitIdType: adUnitIdType,
            loaderOptions: count.flatMap { .multiple($0) } ?? .single,
            onFinishLoading: nil,
            onError: onError,
            onReceive: onReceive
        )
    }
}
