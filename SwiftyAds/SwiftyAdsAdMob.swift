
//  Created by Dominik on 22/08/2015.

//    The MIT License (MIT)
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

//    v6.1.1

import GoogleMobileAds

/**
 SwiftyAdsAdMob
 
 Singleton class to manage adverts from AdMob. This class is only included in the iOS version of the project.
 */
final class SwiftyAdsAdMob: NSObject {
    
    // MARK: - Static Properties
    
    /// Shared instance
    static let shared = SwiftyAdsAdMob()
    
    // MARK: - Properties
    
    /// Delegates
    weak var delegate: SwiftyAdsDelegate?
    
    /// Removed ads
    var isRemoved = false {
        didSet {
            guard isRemoved else { return }
            print("Removed all ads")
            removeBanner()
            interstitialAd?.delegate = nil
            rewardedVideoAd?.delegate = nil
        }
    }
    
    /// Check if interstitial ad is ready (e.g to show alternative ad like a custom ad or something)
    /// Will try to reload an ad if it returns false.
    var isInterstitialReady: Bool {
        guard let interAd = interstitialAd, interAd.isReady else {
            print("AdMob interstitial ad is not ready, reloading...")
            interstitialAd = loadInterstitialAd()
            return false
        }
        return true
    }
    
    /// Check if reward video is ready (e.g to hide a reward video button)
    /// Will try to reload an ad if it returns false.
    var isRewardedVideoReady: Bool {
        guard let rewardedVideo = rewardedVideoAd, rewardedVideo.isReady else {
            print("AdMob reward video is not ready, reloading...")
            rewardedVideoAd = loadRewardedVideoAd()
            return false
        }
        return true
    }
    
    /// Presenting view controller
    fileprivate var presentingViewController: UIViewController?
    
    /// Ads
    fileprivate var bannerAd: GADBannerView?
    fileprivate var interstitialAd: GADInterstitial?
    fileprivate var rewardedVideoAd: GADRewardBasedVideoAd?
    
    /// Test Ad Unit IDs. Will get set to real ID in setup method
    fileprivate var bannerAdUnitID = "ca-app-pub-3940256099942544/2934735716"
    fileprivate var interstitialAdUnitID = "ca-app-pub-3940256099942544/4411468910"
    fileprivate var rewardedVideoAdUnitID = "ca-app-pub-1234567890123456/1234567890"
    
    /// Interval counter
    private var intervalCounter = 0
    
    // MARK: - Init
    
    /// Private singleton init
    private override init() {
        super.init()
        print("Google Mobile Ads SDK version: " + GADRequest.sdkVersion())
    }
    
    // MARK: - Set-Up
    
    /// Set up admob helper
    ///
    /// - parameter viewController: The view controller reference to present ads.
    /// - parameter bannerID: The banner adUnitID for this app.
    /// - parameter interID: The interstitial adUnitID for this app.
    /// - parameter rewardedVideoID: The rewarded video adUnitID for this app.
    func setup(viewController: UIViewController, bannerID: String, interID: String, rewardedVideoID: String) {
        presentingViewController = viewController
        
        #if !DEBUG
        bannerAdUnitID = bannerID
        interstitialAdUnitID = interID
        rewardedVideoAdUnitID = rewardedVideoID
        #endif
        
        // Preload inter and reward ads first time
        interstitialAd = loadInterstitialAd()
        rewardedVideoAd = loadRewardedVideoAd()
    }
    
    // MARK: - Show Banner
    
    /// Show banner ad with delay
    ///
    /// - parameter delay: The delay until showing the ad. Defaults to 0.
    func showBanner(withDelay delay: TimeInterval = 0.1) {
        guard !isRemoved else { return }
        
        Timer.scheduledTimer(timeInterval: delay, target: self, selector: #selector(showingBanner), userInfo: nil, repeats: false)
    }
    
    /// Show banner ad
    @objc fileprivate func showingBanner() {
        loadBannerAd()
    }
    
    // MARK: - Show Interstitial
    
    /// Show interstitial ad randomly
    ///
    /// - parameter interval: The interval of when to show the ad, e.g every 4th time. Defaults to nil.
    func showInterstitial(withInterval interval: Int? = nil) {
        guard !isRemoved, isInterstitialReady else { return }
        guard let presentingViewController = presentingViewController?.view?.window?.rootViewController else { return }
        
        if let interval = interval {
            intervalCounter += 1
            guard intervalCounter >= interval else { return }
            intervalCounter = 0
        }
        
        print("AdMob interstitial is showing")
        interstitialAd?.present(fromRootViewController: presentingViewController)
    }
    
    // MARK: - Show Reward Video
    
    /// Show rewarded video ad
    func showRewardedVideo() {
        guard isRewardedVideoReady else { return }
        guard let rootViewController = presentingViewController?.view?.window?.rootViewController else { return }
        
        print("AdMob reward video is showing")
        rewardedVideoAd?.present(fromRootViewController: rootViewController)
    }
    
    // MARK: - Remove
    
    /// Remove banner ads
    func removeBanner() {
        print("Removed banner ad")
        
        bannerAd?.delegate = nil
        bannerAd?.removeFromSuperview()
        
        guard let view = presentingViewController?.view else { return }
        for subview in view.subviews { // Just incase there are multiple instances of a banner
            if let bannerAd = subview as? GADBannerView {
                bannerAd.delegate = nil
                bannerAd.removeFromSuperview()
            }
        }
    }
    
    // MARK: - Orientation Changed
    
    /// Orientation changed
    func adjustForOrientation() {
        guard let presentingViewController = presentingViewController, let bannerAd = bannerAd else { return }
        
        print("AdMob banner orientation adjusted")
        
        if UIApplication.shared.statusBarOrientation.isLandscape {
            bannerAd.adSize = kGADAdSizeSmartBannerLandscape
        } else {
            bannerAd.adSize = kGADAdSizeSmartBannerPortrait
        }
        
        bannerAd.center = CGPoint(x: presentingViewController.view.frame.midX, y: presentingViewController.view.frame.maxY - (bannerAd.frame.height / 2))
    }
}

// MARK: - Requesting Ad

fileprivate extension SwiftyAdsAdMob {
    
    /// Load banner ad
    func loadBannerAd() {
        guard let presentingViewController = presentingViewController else { return }
        print("AdMob banner loading...")
        
        if UIApplication.shared.statusBarOrientation.isLandscape {
            bannerAd = GADBannerView(adSize: kGADAdSizeSmartBannerLandscape)
        } else {
            bannerAd = GADBannerView(adSize: kGADAdSizeSmartBannerPortrait)
        }
        
        bannerAd?.adUnitID = bannerAdUnitID
        bannerAd?.delegate = self
        bannerAd?.rootViewController = presentingViewController.view?.window?.rootViewController
        bannerAd?.center = CGPoint(x: presentingViewController.view.frame.midX, y: presentingViewController.view.frame.maxY + (bannerAd!.frame.height / 2))
        
        let request = GADRequest()
        
        #if DEBUG
            request.testDevices = [kGADSimulatorID]
        #endif
        
        bannerAd?.load(request)
    }

    /// Load interstitial ad
    func loadInterstitialAd() -> GADInterstitial {
        print("AdMob interstitial loading...")
        
        let interstitialAd = GADInterstitial(adUnitID: interstitialAdUnitID)
        interstitialAd.delegate = self
        
        let request = GADRequest()
        
        #if DEBUG
            request.testDevices = [kGADSimulatorID]
        #endif
        
        interstitialAd.load(request)
        
        return interstitialAd
    }
    
    /// Load rewarded video ad
    func loadRewardedVideoAd() -> GADRewardBasedVideoAd? {
        
        let rewardedVideoAd = GADRewardBasedVideoAd.sharedInstance()
        
        rewardedVideoAd.delegate = self
        let request = GADRequest()
        
        #if DEBUG
            request.testDevices = [kGADSimulatorID]
        #endif
        
        rewardedVideoAd.load(request, withAdUnitID: rewardedVideoAdUnitID)
        
        return rewardedVideoAd
    }
}

// MARK: - GADBannerViewDelegate

extension SwiftyAdsAdMob: GADBannerViewDelegate {
    
    func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        guard let presentingViewController = presentingViewController else { return }
        print("AdMob banner did receive ad from: \(bannerView.adNetworkClassName)")
        
        presentingViewController.view?.addSubview(bannerView)
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(1.5)
        bannerView.center = CGPoint(x: presentingViewController.view.frame.midX, y: presentingViewController.view.frame.maxY - (bannerView.frame.height / 2))
        UIView.commitAnimations()
    }
    
    func adViewWillPresentScreen(_ bannerView: GADBannerView) { // gets called only in release mode
        print("AdMob banner clicked")
        delegate?.adDidOpen()
    }
    
    func adViewWillDismissScreen(_ bannerView: GADBannerView) {
        print("AdMob banner about to be closed")
    }
    
    func adViewDidDismissScreen(_ bannerView: GADBannerView) { // gets called in only release mode
        print("AdMob banner closed")
        delegate?.adDidClose()
    }
    
    func adViewWillLeaveApplication(_ bannerView: GADBannerView) {
        print("AdMob banner will leave application")
        delegate?.adDidOpen()
    }
    
    func adView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: GADRequestError) {
        print(error.localizedDescription)
        
        guard let presentingViewController = presentingViewController else { return }
        
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(1.5)
        bannerView.center = CGPoint(x: presentingViewController.view.frame.midX, y: presentingViewController.view.frame.maxY + (bannerView.frame.height / 2))
        bannerView.isHidden = true
   
        UIView.commitAnimations()
    }
}

// MARK: - GADInterstitialDelegate

extension SwiftyAdsAdMob: GADInterstitialDelegate {
    
    func interstitialDidReceiveAd(_ ad: GADInterstitial) {
        print("AdMob interstitial did receive ad from: \(ad.adNetworkClassName)")
    }
    
    func interstitialWillPresentScreen(_ ad: GADInterstitial) {
        print("AdMob interstitial will present")
        delegate?.adDidOpen()
    }
    
    func interstitialWillDismissScreen(_ ad: GADInterstitial) {
        print("AdMob interstitial about to be closed")
    }
    
    func interstitialDidDismissScreen(_ ad: GADInterstitial) {
        print("AdMob interstitial closed, reloading...")
        delegate?.adDidClose()
        interstitialAd = loadInterstitialAd()
    }
    
    func interstitialWillLeaveApplication(_ ad: GADInterstitial) {
        print("AdMob interstitial will leave application")
        delegate?.adDidOpen()
    }
    
    func interstitialDidFail(toPresentScreen ad: GADInterstitial) {
        print("AdMob interstitial did fail to present")
    }
    
    func interstitial(_ ad: GADInterstitial, didFailToReceiveAdWithError error: GADRequestError) {
        print(error.localizedDescription)
    }
}

// MARK: - GADRewardBasedVideoAdDelegate

extension SwiftyAdsAdMob: GADRewardBasedVideoAdDelegate {
    
    func rewardBasedVideoAdDidOpen(_ rewardBasedVideoAd: GADRewardBasedVideoAd) {
        print("AdMob reward video ad did open")
    }
    
    func rewardBasedVideoAdDidClose(_ rewardBasedVideoAd: GADRewardBasedVideoAd) {
        print("AdMob reward video closed, reloading...")
        delegate?.adDidClose()
        rewardedVideoAd = loadRewardedVideoAd()
    }
    
    func rewardBasedVideoAdDidReceive(_ rewardBasedVideoAd: GADRewardBasedVideoAd) {
        print("AdMob reward video did receive ad")
    }
    
    func rewardBasedVideoAdDidStartPlaying(_ rewardBasedVideoAd: GADRewardBasedVideoAd) {
        print("AdMob reward video did start playing")
        delegate?.adDidOpen()
    }
    
    func rewardBasedVideoAdWillLeaveApplication(_ rewardBasedVideoAd: GADRewardBasedVideoAd) {
        print("AdMob reward video will leave application")
        delegate?.adDidOpen()
    }
    
    func rewardBasedVideoAd(_ rewardBasedVideoAd: GADRewardBasedVideoAd, didFailToLoadWithError error: Error) {
        print(error.localizedDescription)
    }
    
    func rewardBasedVideoAd(_ rewardBasedVideoAd: GADRewardBasedVideoAd, didRewardUserWith reward: GADAdReward) {
        print("AdMob reward video did reward user")
        delegate?.adDidRewardUser(withAmount: Int(reward.amount))
    }
}
