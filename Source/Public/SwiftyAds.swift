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

/// SwiftyAdsDelegate
public protocol SwiftyAdsDelegate: class {
    /// SwiftyAds did open
    func swiftyAdsDidOpen(_ swiftyAds: SwiftyAds)
    /// SwiftyAds did close
    func swiftyAdsDidClose(_ swiftyAds: SwiftyAds)
    /// SwiftyAds did change consent status
    func swiftyAds(_ swiftyAds: SwiftyAds, didChange consentStatus: SwiftyAdsConsentStatus)
    /// SwiftyAds did reward user
    func swiftyAds(_ swiftyAds: SwiftyAds, didRewardUserWithAmount rewardAmount: Int)
}

/// SwiftyAds mode
public enum SwiftyAdsMode {
    case production
    case test(devices: [String])
}

/// SwiftyAds type
public protocol SwiftyAdsType: AnyObject {
    var hasConsent: Bool { get }
    var isRequiredToAskForConsent: Bool { get }
    var isInterstitialReady: Bool { get }
    var isRewardedVideoReady: Bool { get }
    func setup(with viewController: UIViewController,
               delegate: SwiftyAdsDelegate?,
               mode: SwiftyAdsMode,
               consentStyle: SwiftyAdsConsentStyle,
               handler: @escaping (SwiftyAdsConsentStatus) -> Void)
    func askForConsent(from viewController: UIViewController)
    func showBanner(from viewController: UIViewController, atTop isAtTop: Bool, animationDuration: TimeInterval)
    func showInterstitial(from viewController: UIViewController, withInterval interval: Int?)
    func showRewardedVideo(from viewController: UIViewController, completion: (Bool) -> Void)
    func removeBanner()
    func disable()
}

/**
 SwiftyAds
 
 A singleton class to manage adverts from Google AdMob.
 */
public final class SwiftyAds: NSObject {
    
    // MARK: - Static Properties
    
    /// The shared instance of SwiftyAds using default non costumizable settings
    public static let shared = SwiftyAds()
    
    // MARK: - Properties
    
    private var configuration: SwiftyAdsConfiguration = .propertyList
    private var mode: SwiftyAdsMode = .production
    private var consentManager: SwiftyAdsConsentManagerType!
    private let intervalTracker: SwiftyAdsIntervalTrackerType
    private var consentStyle: SwiftyAdsConsentStyle = .adMob(shouldOfferAdFree: false)
    private weak var delegate: SwiftyAdsDelegate?
    
    private var isDisabled = false
    private var testDevices: [Any] = [kGADSimulatorID]
        
    private lazy var bannerAd: SwiftyAdsBannerType = {
        let ad = SwiftyAdsBanner(
            adUnitId: configuration.bannerAdUnitId,
            notificationCenter: .default,
            isLandscape: { UIDevice.current.orientation.isLandscape },
            request: ({ [unowned self] in
                self.makeRequest()
            }),
            didOpen: ({ [weak self] in
                guard let self = self else { return }
                self.delegate?.swiftyAdsDidOpen(self)
            }),
            didClose: ({ [weak self] in
                guard let self = self else { return }
                self.delegate?.swiftyAdsDidClose(self)
            })
        )
        return ad
    }()
    
    private lazy var interstitialAd: SwiftyAdsInterstitialType = {
        let ad = SwiftyAdsInterstitial(
            adUnitId: configuration.interstitialAdUnitId,
            request: ({ [unowned self] in
                self.makeRequest()
            }),
            didOpen: ({ [weak self] in
                guard let self = self else { return }
                self.delegate?.swiftyAdsDidOpen(self)
            }),
            didClose: ({ [weak self] in
                guard let self = self else { return }
                self.delegate?.swiftyAdsDidClose(self)
            })
        )
        return ad
    }()
    
    private lazy var rewardedAd: SwiftyAdsRewardedType = {
        let ad = SwiftyAdsRewarded(
            adUnitId: configuration.rewardedVideoAdUnitId,
            request: ({ [unowned self] in
                self.makeRequest()
            }),
            didOpen: ({ [weak self] in
                guard let self = self else { return }
                self.delegate?.swiftyAdsDidOpen(self)
            }),
            didClose: ({ [weak self] in
                guard let self = self else { return }
                self.delegate?.swiftyAdsDidClose(self)
            }),
            didReward: ({ [weak self] rewardAmount in
                guard let self = self else { return }
                self.delegate?.swiftyAds(self, didRewardUserWithAmount: rewardAmount)
            })
        )
        return ad
    }()
        
    // MARK: - Computed Properties
    
    private var requestBuilder: SwiftyAdsRequestBuilderType {
        SwiftyAdsRequestBuilder(
            mobileAds: .sharedInstance(),
            isGDPRRequired: consentManager.isInEEA,
            isNonPersonalizedOnly: consentManager.status == .nonPersonalized,
            isTaggedForUnderAgeOfConsent: consentManager.isTaggedForUnderAgeOfConsent
        )
    }
    
    // MARK: - Init
    
    private override init() {
        self.intervalTracker = SwiftyAdsIntervalTracker()
        super.init()
        consentManager = SwiftyAdsConsentManager(
            configuration: { [unowned self] in self.configuration },
            consentStyle: { [unowned self] in self.consentStyle }
        )
    }
    
    init(mode: SwiftyAdsMode,
         consentManager: SwiftyAdsConsentManagerType,
         intervalTracker: SwiftyAdsIntervalTrackerType,
         consentStyle: SwiftyAdsConsentStyle) {
        self.mode = mode
        self.consentManager = consentManager
        self.intervalTracker = intervalTracker
        self.consentStyle = consentStyle
    }
}

// MARK: - SwiftyAdType

extension SwiftyAds: SwiftyAdsType {
    
    /// Check if user has consent e.g to hide rewarded video button
    public var hasConsent: Bool {
        consentManager.hasConsent
    }
     
    /// Check if we must ask for consent e.g to hide change consent button in apps settings menu (required GDPR requirement)
    public var isRequiredToAskForConsent: Bool {
        consentManager.isRequiredToAskForConsent
    }
     
    /// Check if interstitial video is ready (e.g to show alternative ad like an in house ad)
    /// Will try to reload an ad if it returns false.
    public var isInterstitialReady: Bool {
        interstitialAd.isReady
    }
     
    /// Check if reward video is ready (e.g to hide/disable the rewarded video button)
    /// Will try to reload an ad if it returns false.
    public var isRewardedVideoReady: Bool {
        rewardedAd.isReady
    }
    
    /// Setup swift ad
    ///
    /// - parameter viewController: The view controller that will present the consent alert if needed.
    /// - parameter delegate: A delegate to receive event callbacks. Can also be set manually if needed.
    /// - parameter mode: Set the mode of ads, production or debug.
    /// - parameter consentStyle: The style of the consent alert.
    /// - parameter handler: A handler that will return the current consent status.
    public func setup(with viewController: UIViewController,
                      delegate: SwiftyAdsDelegate?,
                      mode: SwiftyAdsMode,
                      consentStyle: SwiftyAdsConsentStyle,
                      handler: @escaping (SwiftyAdsConsentStatus) -> Void) {
        self.delegate = delegate
        self.consentStyle = consentStyle
       
        switch mode {
        case .production:
            configuration = .propertyList
        case .test(let testDevices):
            configuration = .debug
            self.testDevices.append(contentsOf: testDevices)
        }
     
        // Make consent request
        consentManager.ask(from: viewController, skipIfAlreadyAuthorized: true) { status in
            self.handleConsentStatusChange(status)
           
            if status.hasConsent {
                if !self.isDisabled {
                    self.interstitialAd.load()
                }
                self.rewardedAd.load()
            }
            
            handler(status)
        }
    }

    /// Ask for consent e.g when consent button is pressed
    ///
    /// - parameter viewController: The view controller that will present the consent form.
    public func askForConsent(from viewController: UIViewController) {
        consentManager.ask(from: viewController, skipIfAlreadyAuthorized: false) { status in
            self.handleConsentStatusChange(status)
        }
    }
    
    /// Show banner ad
    ///
    /// - parameter viewController: The view controller that will present the ad.
    /// - parameter isAtTop: If set to true the banner will be displayed at the top.
    /// - parameter animationDuration: The duration of the banner to animate on/off screen.
    public func showBanner(from viewController: UIViewController, atTop isAtTop: Bool, animationDuration: TimeInterval) {
        guard !isDisabled else { return }
        guard hasConsent else { return }
        bannerAd.show(from: viewController, at: isAtTop ? .top : .bottom, animationDuration: animationDuration)
    }
    
    /// Show interstitial ad
    ///
    /// - parameter viewController: The view controller that will present the ad.
    /// - parameter interval: The interval of when to show the ad, e.g every 4th time the method is called. Set to nil to always show.
    public func showInterstitial(from viewController: UIViewController, withInterval interval: Int?) {
        guard !isDisabled else { return }
        guard hasConsent else { return }
        guard isInterstitialReady else { return }
        guard intervalTracker.canShow(forInterval: interval) else { return }
        interstitialAd.show(from: viewController)
    }
    
    /// Show rewarded video ad
    ///
    /// - parameter viewController: The view controller that will present the ad.
    /// - parameter completion: A completion handler returning a boolean to indicate if the ad was displayed e.g show alert if not.
    public func showRewardedVideo(from viewController: UIViewController, completion: (Bool) -> Void) {
        guard hasConsent else { return }
        rewardedAd.show(from: viewController, completion: completion)
    }
    
    /// Remove banner ads
    public func removeBanner() {
        bannerAd.remove()
    }

    /// Disable ads e.g in app purchases
    public func disable() {
        isDisabled = true
        removeBanner()
        interstitialAd.stopLoading()
    }
}

// MARK: - Private Methods

private extension SwiftyAds {
    
    func handleConsentStatusChange(_ status: SwiftyAdsConsentStatus) {
        delegate?.swiftyAds(self, didChange: status)
    }
    
    func makeRequest() -> GADRequest {
        switch mode {
        case .production:
            return requestBuilder.build(.production)
        case .test(let devices):
            return requestBuilder.build(.test(devices: devices))
        }
    }
}
