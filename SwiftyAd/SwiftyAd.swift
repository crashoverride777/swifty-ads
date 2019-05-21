//    The MIT License (MIT)
//
//    Copyright (c) 2015-2018 Dominik Ringler
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

#warning("FIX")
/// LocalizedString
private extension String {
    static let sorry = "Sorry"
    static let ok = "OK"
    static let noVideo = "No video available to watch at the moment."
}

/// SwiftyAdDelegate
protocol SwiftyAdDelegate: class {
    /// SwiftyAd did open
    func swiftyAdDidOpen(_ swiftyAd: SwiftyAd)
    /// SwiftyAd did close
    func swiftyAdDidClose(_ swiftyAd: SwiftyAd)
    /// Did change consent status
    func swiftyAd(_ swiftyAd: SwiftyAd, didChange consentStatus: SwiftyAd.ConsentStatus)
    /// SwiftyAd did reward user
    func swiftyAd(_ swiftyAd: SwiftyAd, didRewardUserWithAmount rewardAmount: Int)
}

/**
 SwiftyAd
 
 A singleton class to manage adverts from Google AdMob.
 */
final class SwiftyAd: NSObject {
    typealias ConsentConfiguration = SwiftyAdConsentManager.Configuration
    typealias ConsentStatus = SwiftyAdConsentManager.ConsentStatus
    
    // MARK: - Types
    
    private struct Configuration: Codable {
        let bannerAdUnitId: String
        let interstitialAdUnitId: String
        let rewardedVideoAdUnitId: String
        let gdpr: ConsentConfiguration
        
        var ids: [String] {
            return [bannerAdUnitId, interstitialAdUnitId, rewardedVideoAdUnitId].filter { !$0.isEmpty }
        }
        
        static var propertyList: Configuration {
            guard let configurationURL = Bundle.main.url(forResource: "SwiftyAd", withExtension: "plist") else {
                print("SwiftyAd must have a valid property list")
                fatalError("SwiftyAd must have a valid property list")
            }
            do {
                let data = try Data(contentsOf: configurationURL)
                let decoder = PropertyListDecoder()
                return try decoder.decode(Configuration.self, from: data)
            } catch {
                print("SwiftyAd must have a valid property list \(error)")
                fatalError("SwiftyAd must have a valid property list")
            }
        }
        
        static var debug: Configuration {
            return Configuration(
                bannerAdUnitId: "ca-app-pub-3940256099942544/2934735716",
                interstitialAdUnitId: "ca-app-pub-3940256099942544/4411468910",
                rewardedVideoAdUnitId: "ca-app-pub-1234567890123456/1234567890",
                gdpr: ConsentConfiguration(
                    privacyPolicyURL: "https://developers.google.com/admob/ios/eu-consent",
                    shouldOfferAdFree: false,
                    mediationNetworks: [],
                    isTaggedForUnderAgeOfConsent: false,
                    isCustomForm: true
                )
            )
        }
    }
    
    // MARK: - Static Properties
    
    /// Shared instance
    static let shared = SwiftyAd()
    
    // MARK: - Properties
    
    /// Check if user has consent e.g to hide rewarded video button
    var hasConsent: Bool {
        return consentManager.hasConsent
    }
    
    /// Check if we must ask for consent e.g to hide change consent button in apps settings menu (required GDPR requiredment)
    var isRequiredToAskForConsent: Bool {
        return consentManager.isRequiredToAskForConsent
    }
    
    /// Check if interstitial video is ready (e.g to show alternative ad like an in house ad)
    /// Will try to reload an ad if it returns false.
    var isInterstitialReady: Bool {
        guard interstitialAd?.isReady == true else {
            print("AdMob interstitial ad is not ready, reloading...")
            loadInterstitialAd()
            return false
        }
        return true
    }
    
    /// Check if reward video is ready (e.g to hide a reward video button)
    /// Will try to reload an ad if it returns false.
    var isRewardedVideoReady: Bool {
        guard rewardedVideoAd?.isReady == true else {
            print("AdMob reward video is not ready, reloading...")
            loadRewardedVideoAd()
            return false
        }
        return true
    }
    
    /// Remove ads e.g for in app purchases
    var isRemoved = false {
        didSet {
            guard isRemoved else { return }
            removeBanner()
            interstitialAd?.delegate = nil
            interstitialAd = nil
        }
    }
    
    /// Delegates
    private weak var delegate: SwiftyAdDelegate?
    
    /// Configuration
    private var configuration: Configuration!
    
    /// Consent manager
    private var consentManager: SwiftyAdConsentManager!
    
    /// Ads
    private var bannerAdView: GADBannerView?
    private var interstitialAd: GADInterstitial?
    private var rewardedVideoAd: GADRewardBasedVideoAd?
    
    /// Constraints
    private var bannerViewConstraint: NSLayoutConstraint?
    
    /// Banner animation duration
    private var bannerAnimationDuration = 1.8
    
    /// Interval counter
    private var intervalCounter = 0
        
    // MARK: - Init
    
    private override init() {
        super.init()
        print("AdMob SDK version \(GADRequest.sdkVersion())")
        NotificationCenter.default.addObserver(self, selector: #selector(deviceRotated), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    // MARK: - Setup
    
    /// Setup swift ad
    ///
    /// - parameter viewController: The view controller that will present the consent alert if needed.
    /// - parameter delegate: A delegate to receive event callbacks.
    /// - parameter bannerAnimationDuration: The duration of the banner animation.
    /// - returns handler: A handler that will return a boolean with the consent status.
    func setup(with viewController: UIViewController,
               delegate: SwiftyAdDelegate?,
               bannerAnimationDuration: TimeInterval? = nil,
               handler: @escaping (_ hasConsent: Bool) -> Void) {
        self.delegate = delegate
        if let bannerAnimationDuration = bannerAnimationDuration {
            self.bannerAnimationDuration = bannerAnimationDuration
        }
        
        // Configure
        configuration = Configuration.propertyList
        #if DEBUG
        configuration = Configuration.debug
        #endif
        
        // Create consent manager
        consentManager = SwiftyAdConsentManager(ids: configuration.ids, configuration: configuration.gdpr)
        
        // Make consent request
        consentManager.ask(from: viewController, skipIfAlreadyAuthorized: true) { status in
            self.delegate?.swiftyAd(self, didChange: status)
           
            switch status {
            case .personalized, .nonPersonalized:
                self.loadInterstitialAd()
                self.loadRewardedVideoAd()
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
    func askForConsent(from viewController: UIViewController) {
        consentManager.ask(from: viewController, skipIfAlreadyAuthorized: false) { status in
            self.delegate?.swiftyAd(self, didChange: status)
        }
    }
    
    // MARK: - Show Banner
    
    /// Show banner ad
    ///
    /// - parameter viewController: The view controller that will present the ad.
    /// - parameter position: The position of the banner. Defaults to bottom.
    func showBanner(from viewController: UIViewController) {
        guard !isRemoved else { return }
        
        checkThatWeCanShowAd(from: viewController) { canShowAd in
            guard canShowAd else { return }
            self.loadBannerAd(from: viewController)
        }
    }
    
    // MARK: - Show Interstitial
    
    /// Show interstitial ad
    ///
    /// - parameter viewController: The view controller that will present the ad.
    /// - parameter interval: The interval of when to show the ad, e.g every 4th time the method is called. Defaults to nil.
    func showInterstitial(from viewController: UIViewController, withInterval interval: Int? = nil) {
        guard !isRemoved else { return }
        
        if let interval = interval {
            intervalCounter += 1
            guard intervalCounter >= interval else { return }
            intervalCounter = 0
        }
        
        checkThatWeCanShowAd(from: viewController) { canShowAd in
            guard canShowAd, self.isInterstitialReady else { return }
            self.interstitialAd?.present(fromRootViewController: viewController)
        }
    }
    
    // MARK: - Show Reward Video
    
    /// Show rewarded video ad
    ///
    /// - parameter viewController: The view controller that will present the ad.
    func showRewardedVideo(from viewController: UIViewController) {
        checkThatWeCanShowAd(from: viewController) { canShowAd in
            guard canShowAd else { return }
            if self.isRewardedVideoReady {
                self.rewardedVideoAd?.present(fromRootViewController: viewController)
            } else {
                let alertController = UIAlertController(title: .sorry, message: .noVideo, preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: .ok, style: .cancel))
                viewController.present(alertController, animated: true)
            }
        }
    }
    
    // MARK: - Remove Banner
    
    /// Remove banner ads
    func removeBanner() {
        bannerAdView?.delegate = nil
        bannerAdView?.removeFromSuperview()
        bannerAdView = nil
        bannerViewConstraint = nil
    }
}

// MARK: - GADBannerViewDelegate

extension SwiftyAd: GADBannerViewDelegate {
    
    func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        print("AdMob banner did receive ad from: \(bannerView.adNetworkClassName ?? "")")
        animateBannerToOnScreenPosition(bannerView, from: bannerView.rootViewController)
    }
    
    func adViewWillPresentScreen(_ bannerView: GADBannerView) {
        delegate?.swiftyAdDidOpen(self)
    }
    
    func adViewWillLeaveApplication(_ bannerView: GADBannerView) {
        delegate?.swiftyAdDidOpen(self)
    }
    
    func adViewWillDismissScreen(_ bannerView: GADBannerView) {
   
    }
    
    func adViewDidDismissScreen(_ bannerView: GADBannerView) {
        delegate?.swiftyAdDidClose(self)
    }
    
    func adView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: GADRequestError) {
        print(error.localizedDescription)
        animateBannerToOffScreenPosition(bannerView, from: bannerView.rootViewController)
    }
}

// MARK: - GADInterstitialDelegate

extension SwiftyAd: GADInterstitialDelegate {
    
    func interstitialDidReceiveAd(_ ad: GADInterstitial) {
        print("AdMob interstitial did receive ad from: \(ad.adNetworkClassName ?? "")")
    }
    
    func interstitialWillPresentScreen(_ ad: GADInterstitial) {
        delegate?.swiftyAdDidOpen(self)
    }
    
    func interstitialWillLeaveApplication(_ ad: GADInterstitial) {
        delegate?.swiftyAdDidOpen(self)
    }
    
    func interstitialWillDismissScreen(_ ad: GADInterstitial) {
    }
    
    func interstitialDidDismissScreen(_ ad: GADInterstitial) {
        delegate?.swiftyAdDidClose(self)
        loadInterstitialAd()
    }
    
    func interstitialDidFail(toPresentScreen ad: GADInterstitial) {
    }
    
    func interstitial(_ ad: GADInterstitial, didFailToReceiveAdWithError error: GADRequestError) {
        print(error.localizedDescription)
        // Do not reload here as it might cause endless loading loops if no/slow internet
    }
}

// MARK: - GADRewardBasedVideoAdDelegate

extension SwiftyAd: GADRewardBasedVideoAdDelegate {
    
    func rewardBasedVideoAdDidReceive(_ rewardBasedVideoAd: GADRewardBasedVideoAd) {
        print("AdMob reward based video did receive ad from: \(rewardBasedVideoAd.adNetworkClassName ?? "")")
    }
    
    func rewardBasedVideoAdDidStartPlaying(_ rewardBasedVideoAd: GADRewardBasedVideoAd) {
        delegate?.swiftyAdDidOpen(self)
    }
    
    func rewardBasedVideoAdDidOpen(_ rewardBasedVideoAd: GADRewardBasedVideoAd) {
    }
    
    func rewardBasedVideoAdWillLeaveApplication(_ rewardBasedVideoAd: GADRewardBasedVideoAd) {
        delegate?.swiftyAdDidOpen(self)
    }
    
    func rewardBasedVideoAdDidClose(_ rewardBasedVideoAd: GADRewardBasedVideoAd) {
        delegate?.swiftyAdDidClose(self)
        loadRewardedVideoAd()
    }
    
    func rewardBasedVideoAdDidCompletePlaying(_ rewardBasedVideoAd: GADRewardBasedVideoAd) {
        
    }
    
    func rewardBasedVideoAd(_ rewardBasedVideoAd: GADRewardBasedVideoAd, didFailToLoadWithError error: Error) {
        print(error.localizedDescription)
        // Do not reload here as it might cause endless loading loops if no/slow internet
    }
    
    func rewardBasedVideoAd(_ rewardBasedVideoAd: GADRewardBasedVideoAd, didRewardUserWith reward: GADAdReward) {
        print("AdMob reward based video ad did reward user with \(reward)")
        let rewardAmount = Int(truncating: reward.amount)
        delegate?.swiftyAd(self, didRewardUserWithAmount: rewardAmount)
    }
}

// MARK: - Callbacks

private extension SwiftyAd {

    @objc func deviceRotated() {
        bannerAdView?.adSize = UIDevice.current.orientation.isLandscape ? kGADAdSizeSmartBannerLandscape : kGADAdSizeSmartBannerPortrait
    }
}

// MARK: - Load Ads

private extension SwiftyAd {
    
    func loadBannerAd(from viewController: UIViewController) {
        guard !isRemoved, hasConsent else { return }
        
        // Remove old banners
        removeBanner()
        
        // Create ad
        bannerAdView = GADBannerView()
        deviceRotated() // to set banner size
        
        guard let bannerAdView = bannerAdView else { return }
        
        bannerAdView.adUnitID = configuration.bannerAdUnitId
        bannerAdView.delegate = self
        bannerAdView.rootViewController = viewController
        viewController.view.addSubview(bannerAdView)
        
        // Add constraints
        let layoutGuide: UILayoutGuide
        if #available(iOS 11, *) {
            layoutGuide = viewController.view.safeAreaLayoutGuide
        } else {
            layoutGuide = viewController.view.layoutMarginsGuide
        }
        
        bannerAdView.translatesAutoresizingMaskIntoConstraints = false
        bannerAdView.leftAnchor.constraint(equalTo: layoutGuide.leftAnchor).isActive = true
        bannerAdView.rightAnchor.constraint(equalTo: layoutGuide.rightAnchor).isActive = true
        bannerViewConstraint = bannerAdView.bottomAnchor.constraint(equalTo: layoutGuide.bottomAnchor)
        bannerViewConstraint?.isActive = true
        
        // Move off screen
        animateBannerToOffScreenPosition(bannerAdView, from: viewController, withAnimation: false)
        
        // Request ad
        let request = makeRequest()
        bannerAdView.load(request)
    }
    
    func loadInterstitialAd() {
        guard !isRemoved, hasConsent else { return }
        
        interstitialAd = GADInterstitial(adUnitID: configuration.interstitialAdUnitId)
        interstitialAd?.delegate = self
        let request = makeRequest()
        interstitialAd?.load(request)
    }
    
    func loadRewardedVideoAd() {
        guard hasConsent else { return }

        rewardedVideoAd = GADRewardBasedVideoAd.sharedInstance()
        rewardedVideoAd?.delegate = self
        let request = makeRequest()
        rewardedVideoAd?.load(request, withAdUnitID: configuration.rewardedVideoAdUnitId)
    }
}

// MARK: - Check That We Can Show Ad

private extension SwiftyAd {
    
    func checkThatWeCanShowAd(from viewController: UIViewController, handler: @escaping (Bool) -> Void) {
        guard !hasConsent else {
            handler(true)
            return
        }
        
        consentManager.ask(from: viewController, skipIfAlreadyAuthorized: false) { status in
            defer {
                self.delegate?.swiftyAd(self, didChange: status)
            }
            
            switch status {
            case .personalized, .nonPersonalized:
                handler(true)
            case .adFree, .unknown:
                handler(false)
            }
        }
    }
}

// MARK: - Banner Position

private extension SwiftyAd {
    
    func animateBannerToOnScreenPosition(_ bannerAd: GADBannerView, from viewController: UIViewController?) {
        bannerAd.isHidden = false
        bannerViewConstraint?.constant = 0
        
        UIView.animate(withDuration: bannerAnimationDuration) {
            viewController?.view.layoutIfNeeded()
        }
    }
    
    func animateBannerToOffScreenPosition(_ bannerAd: GADBannerView, from viewController: UIViewController?, withAnimation: Bool = true) {
        bannerViewConstraint?.constant = 0 + (bannerAd.frame.height * 3) // *3 due to iPhoneX safe area
        
        guard withAnimation else {
            bannerAd.isHidden = true
            return
        }
        
        UIView.animate(withDuration: bannerAnimationDuration, animations: {
            viewController?.view.layoutIfNeeded()
        }, completion: { isSuccess in
            bannerAd.isHidden = true
        })
    }
}

// MARK: - Make Ad Request

private extension SwiftyAd {
    
    func makeRequest() -> GADRequest {
        let request = GADRequest()
        
        // Set debug settings
        #if DEBUG
        request.testDevices = [kGADSimulatorID]
        #endif
        
        // Add extras if in EU (GDPR)
        if consentManager.isInEEA {
            
            // Create additional parameters with under age of consent
            var additionalParameters: [String: Any] = ["tag_for_under_age_of_consent": consentManager.isTaggedForUnderAgeOfConsent]
          
            // Add non personalized paramater to additional parameters if needed
            if consentManager.status == .nonPersonalized {
                additionalParameters["npa"] = "1" // only allow non-personalized ads
            }
            
            // Create extras
            let extras = GADExtras()
            extras.additionalParameters = additionalParameters
            request.register(extras)
        }
        
        // Return the request
        return request
    }
}

/// Overrides the default print method so it print statements only show when in DEBUG mode
private func print(_ items: Any...) {
    #if DEBUG
    Swift.print(items)
    #endif
}
