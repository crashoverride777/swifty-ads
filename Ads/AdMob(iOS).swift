
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

//    v5.5

import GoogleMobileAds

/**
 AdMob
 
 Singleton class to manage adverts from AdMob. This class is only included in the iOS version of the project.
 */
final class AdMob: NSObject {
    
    // MARK: - Static Properties
    
    /// Shared instance
    static let shared = AdMob()
    
    // MARK: - Properties
    
    /// Delegates
    weak var delegate: AdsDelegate?
    
    /// Check if reward video is ready (e.g to hide a reward video button)
    var rewardedVideoIsReady: Bool {
        guard let rewardedVideoAd = rewardedVideoAd else { return false }
        return rewardedVideoAd.isReady
    }
    
    /// Presenting view controller
    fileprivate var presentingViewController: UIViewController?
    
    /// Ads
    fileprivate var bannerAd: GADBannerView?
    fileprivate var interstitialAd: GADInterstitial?
    fileprivate var rewardedVideoAd: GADRewardBasedVideoAd?
    
    /// Test Ad Unit IDs
    /// Will get set to real ID in setUp method
    fileprivate var bannerAdUnitID = "ca-app-pub-3940256099942544/2934735716"
    fileprivate var interstitialAdUnitID = "ca-app-pub-3940256099942544/4411468910"
    fileprivate var rewardedVideoAdUnitID = "ca-app-pub-1234567890123456/1234567890"
    
    /// Interval counter
    fileprivate var intervalCounter = 0
    
    /// Removed ads
    fileprivate var removedAds = false
    
    // MARK: - Init
    
    fileprivate override init() {
        super.init()
        print("Google Mobile Ads SDK version: " + GADRequest.sdkVersion())
    }
    
    // MARK: - Set-Up
    
    /**
     Set up admob helper
     
     - parameter viewController: The view controller reference to present ads.
     - parameter bannerID: The banner adUnitID for this app.
     - parameter interID: The interstitial adUnitID for this app.
     - parameter rewardedVideoID: The rewarded video adUnitID for this app.
     */
    func setup(_ viewController: UIViewController, bannerID: String, interID: String, rewardedVideoID: String) {
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
    
    /**
     Show banner ad with delay
     
     - parameter delay: The delay until showing the ad. Defaults to 0.
     */
    func showBanner(withDelay delay: TimeInterval = 0.1) {
        guard !removedAds else { return }
        
        Timer.scheduledTimer(timeInterval: delay, target: self, selector: #selector(showingBanner), userInfo: nil, repeats: false)
    }
    
    /// Show banner ad
    @objc fileprivate func showingBanner() {
        guard !removedAds else { return }
        
        loadBannerAd()
    }
    
    // MARK: - Show Interstitial
    
    /**
     Show interstitial ad randomly
     
     - parameter interval: The interval of when to show the ad, e.g every 4th time. Defaults to 0.
     */
    func showInterstitial(withInterval interval: Int = 0) {
        guard !removedAds else { return }
        
        guard let interstitialAd = interstitialAd , interstitialAd.isReady else {
            print("AdMob interstitial is not ready, reloading...")
            self.interstitialAd = loadInterstitialAd()
            return
        }
        
        if interval != 0 {
            intervalCounter += 1
            guard intervalCounter >= interval else { return }
            intervalCounter = 0
        }
        
        print("AdMob interstitial is showing")
        guard let presentingViewController = presentingViewController?.view?.window?.rootViewController else { return }
        interstitialAd.present(fromRootViewController: presentingViewController)
    }
    
    // MARK: - Show Reward Video
    
    /**
     Show rewarded video ad
     
     - parameter interval: The interval of when to show the ad, e.g every 4th time. Defaults to 0.
     */
    func showRewardedVideo(withInterval interval: Int = 0) {
        guard !removedAds else { return }
        
        guard let rewardedVideoAd = rewardedVideoAd , rewardedVideoAd.isReady else {
            print("AdMob reward video is not ready, reloading...")
            self.rewardedVideoAd = loadRewardedVideoAd()
            return
        }
        
        if interval != 0 {
            intervalCounter += 1
            guard intervalCounter >= interval else { return }
            intervalCounter = 0
        }
        
        print("AdMob reward video is showing")
        guard let rootViewController = presentingViewController?.view?.window?.rootViewController else { return }
        rewardedVideoAd.present(fromRootViewController: rootViewController)
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
    
    /// Remove all ads (in app purchases)
    func removeAll() {
        print("Removed all ads")
        
        removedAds = true
        removeBanner()
        interstitialAd?.delegate = nil
        rewardedVideoAd?.delegate = nil
    }
    
    // MARK: - Orientation Changed
    
    /// Orientation changed
    func adjustForOrientation() {
        guard let presentingViewController = presentingViewController else { return }
        guard let bannerAd = bannerAd else { return }
        
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

fileprivate extension AdMob {
    
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
        
        rewardedVideoAd?.delegate = self
        let request = GADRequest()
        
        #if DEBUG
            request.testDevices = [kGADSimulatorID]
        #endif
        
        rewardedVideoAd?.load(request, withAdUnitID: rewardedVideoAdUnitID)
        
        return rewardedVideoAd
    }
}

// MARK: - GADBannerViewDelegate

extension AdMob: GADBannerViewDelegate {
    
    func adViewDidReceiveAd(_ bannerView: GADBannerView!) {
        guard let presentingViewController = presentingViewController else { return }
        print("AdMob banner did receive ad from: \(bannerView.adNetworkClassName)")
        
        presentingViewController.view?.addSubview(bannerView)
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(1.5)
        bannerView.center = CGPoint(x: presentingViewController.view.frame.midX, y: presentingViewController.view.frame.maxY - (bannerView.frame.height / 2))
        UIView.commitAnimations()
    }
    
    func adViewWillPresentScreen(_ bannerView: GADBannerView!) { // gets called only in release mode
        print("AdMob banner clicked")
        delegate?.adClicked()
    }
    
    func adViewWillDismissScreen(_ bannerView: GADBannerView!) {
        print("AdMob banner about to be closed")
    }
    
    func adViewDidDismissScreen(_ bannerView: GADBannerView!) { // gets called in only release mode
        print("AdMob banner closed")
        delegate?.adClosed()
    }
    
    func adViewWillLeaveApplication(_ bannerView: GADBannerView!) {
        print("AdMob banner will leave application")
        delegate?.adClicked()
    }
    
    func adView(_ bannerView: GADBannerView!, didFailToReceiveAdWithError error: GADRequestError!) {
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

extension AdMob: GADInterstitialDelegate {
    
    func interstitialDidReceiveAd(_ ad: GADInterstitial!) {
        print("AdMob interstitial did receive ad from: \(ad.adNetworkClassName)")
    }
    
    func interstitialWillPresentScreen(_ ad: GADInterstitial!) {
        print("AdMob interstitial will present")
        delegate?.adClicked()
    }
    
    func interstitialWillDismissScreen(_ ad: GADInterstitial!) {
        print("AdMob interstitial about to be closed")
    }
    
    func interstitialDidDismissScreen(_ ad: GADInterstitial!) {
        print("AdMob interstitial closed, reloading...")
        delegate?.adClosed()
        interstitialAd = loadInterstitialAd()
    }
    
    func interstitialWillLeaveApplication(_ ad: GADInterstitial!) {
        print("AdMob interstitial will leave application")
        delegate?.adClicked()
    }
    
    func interstitialDidFail(toPresentScreen ad: GADInterstitial!) {
        print("AdMob interstitial did fail to present")
        // Not sure if to reload here
    }
    
    func interstitial(_ ad: GADInterstitial!, didFailToReceiveAdWithError error: GADRequestError!) {
        print(error.localizedDescription)
    }
}

// MARK: - GADRewardBasedVideoAdDelegate

extension AdMob: GADRewardBasedVideoAdDelegate {
    
    func rewardBasedVideoAdDidOpen(_ rewardBasedVideoAd: GADRewardBasedVideoAd!) {
        print("AdMob reward video ad did open")
    }
    
    func rewardBasedVideoAdDidClose(_ rewardBasedVideoAd: GADRewardBasedVideoAd!) {
        print("AdMob reward video closed, reloading...")
        delegate?.adClosed()
        rewardedVideoAd = loadRewardedVideoAd()
    }
    
    func rewardBasedVideoAdDidReceive(_ rewardBasedVideoAd: GADRewardBasedVideoAd!) {
        print("AdMob reward video did receive ad")
    }
    
    func rewardBasedVideoAdDidStartPlaying(_ rewardBasedVideoAd: GADRewardBasedVideoAd!) {
        print("AdMob reward video did start playing")
        delegate?.adClicked()
    }
    
    func rewardBasedVideoAdWillLeaveApplication(_ rewardBasedVideoAd: GADRewardBasedVideoAd!) {
        print("AdMob reward video will leave application")
        delegate?.adClicked()
    }
    
    func rewardBasedVideoAd(_ rewardBasedVideoAd: GADRewardBasedVideoAd!, didFailToLoadWithError error: Error!) {
        print(error.localizedDescription)
    }
    
    func rewardBasedVideoAd(_ rewardBasedVideoAd: GADRewardBasedVideoAd!, didRewardUserWith reward: GADAdReward!) {
        print("AdMob reward video did reward user")
        delegate?.adDidRewardUser(withAmount: Int(reward.amount))
    }
}
