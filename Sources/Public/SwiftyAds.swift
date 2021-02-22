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

    private var configuration: SwiftyAdsConfiguration?
    private var interstitialAd: SwiftyAdsInterstitialType?
    private var rewardedAd: SwiftyAdsRewardedType?
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
        super.init()
        
    }
}

// MARK: - SwiftyAdsType

extension SwiftyAds: SwiftyAdsType {

    /// The current consent status
    public var consentStatus: SwiftyAdsConsentStatus {
        consentManager?.consentStatus ?? .unknown
    }

    /// The type of consent provided
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
     
    /// Check if interstitial ad is ready (e.g to show alternative ad like an in house ad)
    public var isInterstitialAdReady: Bool {
        interstitialAd?.isReady ?? false
    }
     
    /// Check if reward ad is ready (e.g to hide/disable the rewarded video button)
    public var isRewardedAdReady: Bool {
        rewardedAd?.isReady ?? false
    }

    /// Returns true if SwiftyAds has been disabled
    public var isDisabled: Bool {
        disabled
    }
    
    /// Configure SwiftyAds
    ///
    /// - parameter viewController: The view controller that will present the consent alert if needed.
    /// - parameter environment: The environment for ads to be displayed.
    /// - parameter consentStatusDidChange: A handler that will be called everytime the consent status has changed.
    /// - parameter completion: A completion handler that will return the current consent status after the consent flow has finished.
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

        // Tag for child directed treatment if needed (COPPA)
        if let isTaggedForChildDirectedTreatment = configuration.isTaggedForChildDirectedTreatment {
            mobileAds.requestConfiguration.tag(forChildDirectedTreatment: isTaggedForChildDirectedTreatment)
        }

        // Set ads
        setAds(for: configuration)

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
    
    /// Make banner ad
    ///
    /// - parameter viewController: The view controller that will present the ad.
    /// - parameter adUnitIdType: The adUnitId type for the ad, either plist or custom.
    /// - parameter position: The position of the banner.
    /// - parameter animation: The animation of the banner.
    /// - parameter onOpen: An optional callback when the banner was presented.
    /// - parameter onClose: An optional callback when the banner was dismissed or removed.
    /// - parameter onError: An optional callback when an error has occurred.
    /// - returns SwiftyAdsBannerType to show, hide or remove the prepared banner ad.
    public func makeBannerAd(in viewController: UIViewController,
                             adUnitIdType: SwiftyAdsAdUnitIdType,
                             position: SwiftyAdsBannerAdPosition,
                             animation: SwiftyAdsBannerAdAnimation,
                             onOpen: (() -> Void)?,
                             onClose: (() -> Void)?,
                             onError: ((Error) -> Void)?) -> SwiftyAdsBannerType? {
        guard !isDisabled else { return nil }
        guard hasConsent else { return nil }

        var adUnitId: String? {
            switch adUnitIdType {
            case .plist:
                return configuration?.bannerAdUnitId
            case .custom(let id):
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
            request: { [unowned self] in
                self.requestBuilder.build()
            }
        )

        bannerAd.prepare(
            withAdUnitId: validAdUnitId,
            in: viewController,
            position: position,
            animation: animation,
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
    
    /// Show rewarded ad
    ///
    /// - parameter viewController: The view controller that will present the ad.
    /// - parameter onOpen: An optional callback when the ad was presented.
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

        rewardedAd?.show(
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
    /// - parameter onFinishLoading: An optional callback when the load request has finished.
    /// - parameter onError: An optional callback when an error has occurred.
    /// - parameter onReceive: A callback when the GADNativeAd has been received.

    /// - Warning:
    /// Requests for multiple native ads don't currently work for AdMob ad unit IDs that have been configured for mediation.
    /// Publishers using mediation should avoid using the GADMultipleAdsAdLoaderOptions class when making requests i.e. set count to nil.
    public func loadNativeAd(from viewController: UIViewController,
                             adUnitIdType: SwiftyAdsAdUnitIdType,
                             count: Int?,
                             onFinishLoading: (() -> Void)?,
                             onError: ((Error) -> Void)?,
                             onReceive: @escaping (GADNativeAd) -> Void) {
        guard !isDisabled else { return }
        guard hasConsent else { return }

        if nativeAd == nil, case .custom(let adUnitId) = adUnitIdType {
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
            onFinishLoading: onFinishLoading,
            onError: onError,
            onReceive: onReceive
        )
    }

    /// Disable ads
    public func disable() {
        disabled = true
        interstitialAd?.stopLoading()
        nativeAd?.stopLoading()
    }
}

// MARK: - Deprecated

public extension SwiftyAds {
    /// Setup SwiftyAds
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

    @available(*, deprecated, message: "Please use new makeBanner method with animation parameter")
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
            onError: onError
        )
    }

    @available(*, deprecated, message: "Please use new loadNativeAd method with onFinishLoading callback")
    func loadNativeAd(from viewController: UIViewController,
                      adUnitIdType: SwiftyAdsAdUnitIdType,
                      count: Int?,
                      onReceive: @escaping (GADNativeAd) -> Void,
                      onError: @escaping (Error) -> Void) {
        loadNativeAd(
            from: viewController,
            adUnitIdType: adUnitIdType,
            count: count,
            onFinishLoading: nil,
            onError: onError,
            onReceive: onReceive
        )
    }
}

// MARK: - Private Methods

private extension SwiftyAds {

    func setAds(for configuration: SwiftyAdsConfiguration) {
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
    }

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
