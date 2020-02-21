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

/// SwiftyAdDelegate
public protocol SwiftyAdDelegate: class {
    /// SwiftyAd did open
    func swiftyAdDidOpen(_ swiftyAd: SwiftyAd)
    /// SwiftyAd did close
    func swiftyAdDidClose(_ swiftyAd: SwiftyAd)
    /// Did change consent status
    func swiftyAd(_ swiftyAd: SwiftyAd, didChange consentStatus: SwiftyAdConsentStatus)
    /// SwiftyAd did reward user
    func swiftyAd(_ swiftyAd: SwiftyAd, didRewardUserWithAmount rewardAmount: Int)
}

/// A protocol for mediation implementations
public protocol SwiftyAdMediation: class {
    func update(for consentType: SwiftyAdConsentStatus)
}

/**
 SwiftyAd
 
 A singleton class to manage adverts from Google AdMob.
 */
public final class SwiftyAd: NSObject {
    
    // MARK: - Static Properties
    
    /// The shared instance of SwiftyAd using default non costumizable settings
    public static let shared = SwiftyAd()
    
    // MARK: - Properties
    
    /// Delegate callbacks
    public weak var delegate: SwiftyAdDelegate?
    
    /// Ads
    private(set) lazy var banner: SwiftyAdBannerType = {
        let ad = SwiftyAdBanner(
            adUnitId: configuration.bannerAdUnitId,
            notificationCenter: .default,
            request: ({ [unowned self] in
                self.requestBuilder.build()
            }),
            didOpen: ({ [weak self] in
                guard let self = self else { return }
                self.delegate?.swiftyAdDidOpen(self)
            }),
            didClose: ({ [weak self] in
                guard let self = self else { return }
                self.delegate?.swiftyAdDidClose(self)
            })
        )
        return ad
    }()
    
    private(set) lazy var interstitial: SwiftyAdInterstitialType = {
        let ad = SwiftyAdInterstitial(
            adUnitId: configuration.interstitialAdUnitId,
            request: ({ [unowned self] in
                self.requestBuilder.build()
            }),
            didOpen: ({ [weak self] in
                guard let self = self else { return }
                self.delegate?.swiftyAdDidOpen(self)
            }),
            didClose: ({ [weak self] in
                guard let self = self else { return }
                self.delegate?.swiftyAdDidClose(self)
            })
        )
        return ad
    }()
    
    private(set) lazy var rewarded: SwiftyAdRewardedType = {
        let ad = SwiftyAdRewarded(
            adUnitId: configuration.rewardedVideoAdUnitId,
            request: ({ [unowned self] in
                self.requestBuilder.build()
            }),
            didOpen: ({ [weak self] in
                guard let self = self else { return }
                self.delegate?.swiftyAdDidOpen(self)
            }),
            didClose: ({ [weak self] in
                guard let self = self else { return }
                self.delegate?.swiftyAdDidClose(self)
            }),
            didReward: ({ [weak self] rewardAmount in
                guard let self = self else { return }
                self.delegate?.swiftyAd(self, didRewardUserWithAmount: rewardAmount)
            })
        )
        return ad
    }()
    
    /// Init
    let configuration: SwiftyAdConfiguration
    let requestBuilder: SwiftyAdRequestBuilderType
    let intervalTracker: SwiftyAdIntervalTrackerType
    let consentManager: SwiftyAdConsentManagerType
    let mediationManager: SwiftyAdMediation?
  
    #if DEBUG
    //Testdevices in DEBUG mode
    private var testDevices: [Any] = [kGADSimulatorID]
    #endif
    
    // MARK: - Computed Properties
    
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
        interstitial.isReady
    }
    
    /// Check if reward video is ready (e.g to hide a reward video button)
    /// Will try to reload an ad if it returns false.
    public var isRewardedVideoReady: Bool {
        rewarded.isReady
    }
        
    /// Check if ads have been removed
    private var isRemoved = false {
        didSet {
            guard isRemoved else { return }
            removeBanner()
            interstitial.stopLoading()
        }
    }
    
    // MARK: - Init
    
    override convenience init() {
        // Update configuration
        #if DEBUG
        let configuration: SwiftyAdConfiguration = .debug
        #else
        let configuration: AdConfiguration = .propertyList
        #endif
        let consentManager = SwiftyAdConsentManager(
            ids: configuration.ids,
            configuration: configuration.gdpr
        )
        
        let requestBuilder = SwiftyAdRequestBuilder(
            mobileAds: .sharedInstance(),
            isGDPRRequired: consentManager.isInEEA,
            isNonPersonalizedOnly: consentManager.status == .nonPersonalized,
            isTaggedForUnderAgeOfConsent: consentManager.isTaggedForUnderAgeOfConsent,
            testDevices: nil
        )
        
        self.init(
            configuration: configuration,
            requestBuilder: requestBuilder,
            intervalTracker: SwiftyAdIntervalTracker(),
            mediationManager: nil,
            consentManager: consentManager,
            testDevices: [],
            notificationCenter: .default
        )
    }
    
    init(configuration: SwiftyAdConfiguration,
         requestBuilder: SwiftyAdRequestBuilderType,
         intervalTracker: SwiftyAdIntervalTrackerType,
         mediationManager: SwiftyAdMediation?,
         consentManager: SwiftyAdConsentManagerType,
         testDevices: [Any],
         notificationCenter: NotificationCenter) {
        self.configuration = configuration
        self.requestBuilder = requestBuilder
        self.intervalTracker = intervalTracker
        self.mediationManager = mediationManager
        self.consentManager = consentManager
        self.testDevices = testDevices
        super.init()
        print("AdMob SDK version \(GADRequest.sdkVersion())")
    }
    
    // MARK: - Setup
    
    /// Setup swift ad
    ///
    /// - parameter viewController: The view controller that will present the consent alert if needed.
    /// - parameter delegate: A delegate to receive event callbacks. Can also be set manually if needed.
    /// - parameter bannerAnimationDuration: The duration of the banner animation.
    /// - parameter testDevices: The test devices to use when debugging. These will get added in addition to kGADSimulatorID.
    /// - returns handler: A handler that will return a boolean with the consent status.
    public func setup(with viewController: UIViewController,
                      delegate: SwiftyAdDelegate?,
                      bannerAnimationDuration: TimeInterval,
                      testDevices: [Any] = [],
                      handler: @escaping (_ hasConsent: Bool) -> Void) {
        self.delegate = delegate
    
        // Debug settings
        #if DEBUG
        self.testDevices.append(contentsOf: testDevices)
        #endif
        
        // Update banner animation duration
        banner.updateAnimationDuration(to: bannerAnimationDuration)
       
        // Make consent request
        self.consentManager.ask(from: viewController, skipIfAlreadyAuthorized: true) { status in
            self.handleConsentStatusChange(status)
           
            switch status {
            case .personalized, .nonPersonalized:
                if !self.isRemoved {
                    self.interstitial.load()
                }
                self.rewarded.load()
                handler(true)
            
            case .adFree, .unknown:
                handler(false)
            }
        }
    }
    
    // MARK: - Ask For Consent
    
    /// Ask for consent. Use this for the consent button that should be e.g in settings.
    ///
    /// - parameter viewController: The view controller that will present the consent form.
    public func askForConsent(from viewController: UIViewController) {
        consentManager.ask(from: viewController, skipIfAlreadyAuthorized: false) { status in
            self.handleConsentStatusChange(status)
        }
    }
    
    // MARK: - Show Banner
    
    /// Show banner ad
    ///
    /// - parameter viewController: The view controller that will present the ad.
    /// - parameter position: The position of the banner. Defaults to bottom.
    public func showBanner(from viewController: UIViewController) {
        guard !isRemoved, hasConsent else { return }
        banner.show(from: viewController)
    }
    
    // MARK: - Show Interstitial
    
    /// Show interstitial ad
    ///
    /// - parameter viewController: The view controller that will present the ad.
    /// - parameter interval: The interval of when to show the ad, e.g every 4th time the method is called. Defaults to nil.
    public func showInterstitial(from viewController: UIViewController, withInterval interval: Int? = nil) {
        guard !isRemoved, hasConsent else { return }
        guard intervalTracker.canShow(forInterval: interval) else { return }
        guard isInterstitialReady else { return }
        interstitial.show(for: viewController)
    }
    
    // MARK: - Show Reward Video
    
    /// Show rewarded video ad
    ///
    /// - parameter viewController: The view controller that will present the ad.
    public func showRewardedVideo(from viewController: UIViewController) {
        guard hasConsent else { return }
        rewarded.show(from: viewController)
    }
    
    // MARK: - Remove Banner
    
    /// Remove banner ads
    public func removeBanner() {
        banner.remove()
    }
    
    // MARK: - Disable ads
    
    /// Disable ads e.g in app purchases
    public func disable() {
        isRemoved = true
    }
}

// MARK: - Private Methods

private extension SwiftyAd {
    
    func handleConsentStatusChange(_ status: SwiftyAdConsentStatus) {
        delegate?.swiftyAd(self, didChange: status)
        mediationManager?.update(for: status)
    }
}
