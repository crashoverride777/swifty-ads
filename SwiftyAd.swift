//    The MIT License (MIT)
//
//    Copyright (c) 2015-2017 Dominik Ringler
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

/// LocalizedString (todo)
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
    /// SwiftyAd did reward user
    func swiftyAd(_ swiftyAd: SwiftyAd, didRewardUserWithAmount rewardAmount: Int)
}

/**
 AdMob
 
 A singleton class to manage adverts from Google AdMob.
 */
final class SwiftyAd: NSObject {
    
    // MARK: - Static Properties
    
    /// Shared instance
    static let shared = SwiftyAd()
    
    // MARK: - Properties
    
    /// Banner position
    enum BannerPosition {
        case bottom
        case top
    }
    
    /// Delegates
    weak var delegate: SwiftyAdDelegate?
    
    /// Banner animation duration
    var bannerAnimationDuration = 1.8
    
    /// Check if interstitial video is ready (e.g to show alternative ad)
    /// Will try to reload an ad if it returns false.
    var isInterstitialReady: Bool {
        guard let ad = interstitialAd, ad.isReady else {
            print("AdMob interstitial ad is not ready, reloading...")
            loadInterstitialAd()
            return false
        }
        return true
    }
    
    /// Check if reward video is ready (e.g to hide a reward video button)
    /// Will try to reload an ad if it returns false.
    var isRewardedVideoReady: Bool {
        guard let ad = rewardedVideoAd, ad.isReady else {
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
    
    /// Ads
    private var bannerViewConstraint: NSLayoutConstraint?
    private var bannerAdView: GADBannerView?
    private var interstitialAd: GADInterstitial?
    private var rewardedVideoAd: GADRewardBasedVideoAd?
    
    /// Ad Unit IDs. Gets set to real ID in setup method
    private var bannerViewAdUnitID    = "ca-app-pub-3940256099942544/2934735716"
    private var interstitialAdUnitID  = "ca-app-pub-3940256099942544/4411468910"
    private var rewardedVideoAdUnitID = "ca-app-pub-1234567890123456/1234567890"
    
    /// Interval counter
    private var intervalCounter = 0
    
    /// Banner position
    private var bannerPosition: BannerPosition = .bottom
    
    /// Banner size
    private var bannerSize: GADAdSize {
        return UIDevice.current.orientation.isLandscape ? kGADAdSizeSmartBannerLandscape : kGADAdSizeSmartBannerPortrait
    }
    
    // MARK: - Init
    
    private override init() {
        super.init()
        print("AdMob SDK version \(GADRequest.sdkVersion())")
        NotificationCenter.default.addObserver(self, selector: #selector(didRotateDevice), name: .UIDeviceOrientationDidChange, object: nil)
    }
    
    // MARK: - Setup
    
    /// Set up swift ad
    ///
    /// - parameter bannerID: The banner adUnitID for this app.
    /// - parameter interstitialID: The interstitial adUnitID for this app.
    /// - parameter rewardedVideoID: The rewarded video adUnitID for this app.
    func setup(withBannerID bannerID: String?, interstitialID: String?, rewardedVideoID: String?) {
        #if !DEBUG
            bannerViewAdUnitID = bannerID ?? ""
            interstitialAdUnitID = interstitialID ?? ""
            rewardedVideoAdUnitID = rewardedVideoID ?? ""
        #endif
        
        loadInterstitialAd()
        loadRewardedVideoAd()
    }
    
    // MARK: - Show Banner
    
    /// Show banner ad
    ///
    /// - parameter viewController: The view controller that will present the ad.
    /// - parameter position: The position of the banner. Defaults to bottom.
    func showBanner(from viewController: UIViewController, at position: BannerPosition = .bottom) {
        guard !isRemoved else { return }
        bannerPosition = position
        loadBannerAd(from: viewController)
    }
    
    // MARK: - Show Interstitial
    
    /// Show interstitial ad randomly
    ///
    /// - parameter viewController: The view controller that will present the ad.
    /// - parameter interval: The interval of when to show the ad, e.g every 4th time the method is called. Defaults to nil.
    func showInterstitial(from viewController: UIViewController, withInterval interval: Int? = nil) {
        guard !isRemoved, isInterstitialReady else { return }
        
        if let interval = interval {
            intervalCounter += 1
            guard intervalCounter >= interval else { return }
            intervalCounter = 0
        }
        
        interstitialAd?.present(fromRootViewController: viewController)
    }
    
    // MARK: - Show Reward Video
    
    /// Show rewarded video ad
    ///
    /// - parameter viewController: The view controller that will present the ad.
    func showRewardedVideo(from viewController: UIViewController) {
        guard isRewardedVideoReady else {
            let alertController = UIAlertController(title: .sorry, message: .noVideo, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: .ok, style: .cancel))
            viewController.present(alertController, animated: true)
            return
        }
        
        rewardedVideoAd?.present(fromRootViewController: viewController)
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

// MARK: - Load Ad

private extension SwiftyAd {
    
    func loadBannerAd(from viewController: UIViewController) {
        removeBanner()
        bannerAdView = GADBannerView(adSize: bannerSize)
        
        guard let bannerAdView = bannerAdView else { return }
        
        // Create ad
        bannerAdView.adUnitID = bannerViewAdUnitID
        bannerAdView.delegate = self
        bannerAdView.rootViewController = viewController
        bannerAdView.isHidden = true
        bannerAdView.translatesAutoresizingMaskIntoConstraints = false
        viewController.view.addSubview(bannerAdView)
        
        // Add constraints
        let layoutGuide: UILayoutGuide
        if #available(iOS 11, *) {
            layoutGuide = viewController.view.safeAreaLayoutGuide
        } else {
            layoutGuide = viewController.view.layoutMarginsGuide
        }
        
        bannerAdView.leftAnchor.constraint(equalTo: layoutGuide.leftAnchor).isActive = true
        bannerAdView.rightAnchor.constraint(equalTo: layoutGuide.rightAnchor).isActive = true
        
        switch bannerPosition {
        case .bottom:
            bannerViewConstraint = bannerAdView.bottomAnchor.constraint(equalTo: layoutGuide.bottomAnchor)
        case .top:
            bannerViewConstraint = bannerAdView.topAnchor.constraint(equalTo: layoutGuide.topAnchor)
        }
        
        animateBannerToOffScreenPosition(bannerAdView, from: viewController, withAnimation: false)
        bannerViewConstraint?.isActive = true
        
        // Request ad
        let request = GADRequest()
        #if DEBUG
            request.testDevices = [kGADSimulatorID]
        #endif
        bannerAdView.load(request)
    }
    
    func loadInterstitialAd() {
        interstitialAd = GADInterstitial(adUnitID: interstitialAdUnitID)
        interstitialAd?.delegate = self
        
        let request = GADRequest()
        #if DEBUG
            request.testDevices = [kGADSimulatorID]
        #endif
        interstitialAd?.load(request)
    }
    
    func loadRewardedVideoAd() {
        rewardedVideoAd = GADRewardBasedVideoAd.sharedInstance()
        rewardedVideoAd?.delegate = self
        
        let request = GADRequest()
        #if DEBUG
            request.testDevices = [kGADSimulatorID]
        #endif
        rewardedVideoAd?.load(request, withAdUnitID: rewardedVideoAdUnitID)
    }
}

// MARK: - GAD Banner View Delegate

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

// MARK: - GAD Interstitial Delegate

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

// MARK: - GAD Reward Based Video Ad Delegate

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

    @objc func didRotateDevice() {
        print("SwiftyAd did rotate device")
        bannerAdView?.adSize = bannerSize
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
        switch bannerPosition {
        case .bottom:
            bannerViewConstraint?.constant = 0 + (bannerAd.frame.height * 3) // *3 due to iPhoneX safe area
        case .top:
            bannerViewConstraint?.constant = 0 - (bannerAd.frame.height * 3) // *3 due to iPhoneX safe area
        }
        
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

// MARK: - Print

private extension SwiftyAd {
    
    /// Overrides the default print method so it print statements only show when in DEBUG mode
    func print(_ items: Any...) {
        #if DEBUG
            Swift.print(items)
        #endif
    }
}
