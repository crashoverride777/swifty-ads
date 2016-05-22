
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

//    v5.1

//    Dont forget to add the custom "-D DEBUG" flag in Targets -> BuildSettings -> SwiftCompiler-CustomFlags -> DEBUG)

/*
    Abstract:
    A Singleton class to manage adverts from AdMob. This class is only included in the iOS version of the project.
*/

import GoogleMobileAds

/// Hide print statements for release
private struct Debug {
    static func print(object: Any) {
        #if DEBUG
            Swift.print("DEBUG", object) //, terminator: "")
        #endif
    }
}

/// Admob ad unit IDs
struct AdMobAdUnitID {
    static var banner = ""
    static var interstitial = ""
    static var rewardVideo = ""
}

/// Delegates
protocol AdMobDelegate: class {
    func adMobAdClicked()
    func adMobAdClosed()
    func adMobDidRewardUser(rewardAmount rewardAmount: Int)
}

/// Ads singleton class
class AdMob: NSObject {
    
    // MARK: - Static Properties
    
    /// Shared instance
    static let sharedInstance = AdMob()
    
    // MARK: - Properties
    
    /// Delegates
    weak var delegate: AdMobDelegate?
    
    /// Check if reward video is ready (e.g to hide a reward video button)
    var rewardVideoIsReady: Bool {
        guard let rewardVideoAd = rewardVideoAd else { return false }
        return rewardVideoAd.ready
    }
    
    /// Presenting view controller
    private var presentingViewController: UIViewController?
    
    /// Ads
    private var bannerAd: GADBannerView?
    private var interstitialAd: GADInterstitial?
    private var rewardVideoAd: GADRewardBasedVideoAd?
    
    /// Ad Unit IDs
    #if DEBUG
    private var bannerAdUnitID = "ca-app-pub-3940256099942544/2934735716"
    private var interstitialAdUnitID = "ca-app-pub-3940256099942544/4411468910"
    private var rewardVideoAdUnitID = "ca-app-pub-1234567890123456/1234567890"
    #else
    private var bannerAdUnitID = AdMobAdUnitID.banner
    private var interstitialAdUnitID = AdMobAdUnitID.interstitial
    private var rewardVideoAdUnitID = AdMobAdUnitID.rewardVideo
    #endif
    
    /// Removed ads
    private var removedAds = false
    
    // MARK: - Init
    
    private override init() {
        super.init()
        Debug.print("Google Mobile Ads SDK version: " + GADRequest.sdkVersion())
        
        // Preload inter and reward ads first time
        interstitialAd = loadInterstitialAd()
        rewardVideoAd = loadRewardVideoAd()
    }
    
    // MARK: - Set-Up
    
    /// Set up ads helper
    func setUp(viewController viewController: UIViewController) {
        presentingViewController = viewController
    }
    
    // MARK: - Show Banner
    
    /// Show banner ad with delay
    func showBannerWithDelay(delay: NSTimeInterval) {
        guard !removedAds else { return }
        
        NSTimer.scheduledTimerWithTimeInterval(delay, target: self, selector: #selector(showBanner), userInfo: nil, repeats: false)
    }
    
    /// Show banner ad
    func showBanner() {
        guard !removedAds else { return }
        
        loadBannerAd()
    }
    
    // MARK: - Show Interstitial
    
    /// Show interstitial ad randomly
    func showInterstitialRandomly(randomness randomness: UInt32) {
        guard !removedAds else { return }
    
        guard Int(arc4random_uniform(randomness)) == 0 else { return }
        showInterstitial()
    }
    
    /// Show interstitial ad
    func showInterstitial() {
        guard !removedAds else { return }
        
        guard let interstitialAd = interstitialAd where interstitialAd.isReady else {
            Debug.print("AdMob interstitial is not ready, reloading...")
            self.interstitialAd = loadInterstitialAd()
            return
        }
        
        Debug.print("AdMob interstitial is showing")
        guard let rootViewController = presentingViewController?.view?.window?.rootViewController else { return }
        interstitialAd.presentFromRootViewController(rootViewController)
    }
    
    // MARK: - Show Reward Video
    
    /// Show reward video ad randomly
    func showRewardVideoRandomly(randomness randomness: UInt32) {
        guard !removedAds else { return }
        
        guard Int(arc4random_uniform(randomness)) == 0 else { return }
        showRewardVideo()
    }
    
    /// Show reward video ad
    func showRewardVideo() {
        guard !removedAds else { return }
        
        guard let rewardVideoAd = rewardVideoAd where rewardVideoAd.ready else {
             Debug.print("AdMob reward video is not ready, reloading...")
            self.rewardVideoAd = loadRewardVideoAd()
            return
        }
        
         Debug.print("AdMob reward video is showing")
        guard let rootViewController = presentingViewController else { return }
        rewardVideoAd.presentFromRootViewController(rootViewController)
    }
    
    // MARK: - Remove
    
    /// Remove banner ads
    func removeBanner() {
        Debug.print("Removed banner ad")
        
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
        Debug.print("Removed all ads")
        
        removedAds = true
        removeBanner()
        interstitialAd?.delegate = nil
        rewardVideoAd?.delegate = nil
    }
    
    // MARK: - Orientation Changed
    
    /// Orientation changed
    func orientationChanged() {
        guard let presentingViewController = presentingViewController else { return }
        guard let bannerAd = bannerAd else { return }
        
        Debug.print("AdMob banner orientation adjusted")
        
        if UIApplication.sharedApplication().statusBarOrientation.isLandscape {
            bannerAd.adSize = kGADAdSizeSmartBannerLandscape
        } else {
            bannerAd.adSize = kGADAdSizeSmartBannerPortrait
        }
        
        bannerAd.center = CGPoint(x: CGRectGetMidX(presentingViewController.view.frame), y: CGRectGetMaxY(presentingViewController.view.frame) - (bannerAd.frame.size.height / 2))
    }
}

// MARK: - Requesting Ad

private extension AdMob {
    
    func loadBannerAd() {
        guard let presentingViewController = presentingViewController else { return }
        Debug.print("AdMob banner loading...")
        
        if UIApplication.sharedApplication().statusBarOrientation.isLandscape {
            bannerAd = GADBannerView(adSize: kGADAdSizeSmartBannerLandscape)
        } else {
            bannerAd = GADBannerView(adSize: kGADAdSizeSmartBannerPortrait)
        }
        
        bannerAd?.adUnitID = bannerAdUnitID
        bannerAd?.delegate = self
        bannerAd?.rootViewController = presentingViewController
        bannerAd?.center = CGPoint(x: CGRectGetMidX(presentingViewController.view.frame), y: CGRectGetMaxY(presentingViewController.view.frame) + (bannerAd!.frame.size.height / 2))
        
        let request = GADRequest()
        
        #if DEBUG
            request.testDevices = [kGADSimulatorID]
        #endif
        
        bannerAd?.loadRequest(request)
    }

    func loadInterstitialAd() -> GADInterstitial {
        Debug.print("AdMob interstitial loading...")
        
        let interstitialAd = GADInterstitial(adUnitID: interstitialAdUnitID)
        interstitialAd.delegate = self
        
        let request = GADRequest()
        
        #if DEBUG
            request.testDevices = [kGADSimulatorID]
        #endif
        
        interstitialAd.loadRequest(request)
        
        return interstitialAd
    }
    
    func loadRewardVideoAd() -> GADRewardBasedVideoAd {
        
        let rewardVideoAd = GADRewardBasedVideoAd.sharedInstance()
        
        rewardVideoAd.delegate = self
        let request = GADRequest()
        
        #if DEBUG
            request.testDevices = [kGADSimulatorID]
        #endif
        
        rewardVideoAd.loadRequest(request, withAdUnitID: rewardVideoAdUnitID)
        
        return rewardVideoAd
    }
}

// MARK: - Banner Delegates

extension AdMob: GADBannerViewDelegate {
    
    func adViewDidReceiveAd(bannerView: GADBannerView!) {
        guard let presentingViewController = presentingViewController else { return }
        Debug.print("AdMob banner did receive ad from: \(bannerView.adNetworkClassName)")
        
        presentingViewController.view?.window?.rootViewController?.view.addSubview(bannerView)
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(1.5)
        bannerView.center = CGPoint(x: CGRectGetMidX(presentingViewController.view.frame), y: CGRectGetMaxY(presentingViewController.view.frame) - (bannerView.frame.size.height / 2))
        UIView.commitAnimations()
    }
    
    func adViewWillPresentScreen(bannerView: GADBannerView!) { // gets called only in release mode
        Debug.print("AdMob banner clicked")
        delegate?.adMobAdClicked()
    }
    
    func adViewWillDismissScreen(bannerView: GADBannerView!) {
        Debug.print("AdMob banner about to be closed")
    }
    
    func adViewDidDismissScreen(bannerView: GADBannerView!) { // gets called in only release mode
        Debug.print("AdMob banner closed")
        delegate?.adMobAdClosed()
    }
    
    func adViewWillLeaveApplication(bannerView: GADBannerView!) {
        Debug.print("AdMob banner will leave application")
        delegate?.adMobAdClicked()
    }
    
    func adView(bannerView: GADBannerView!, didFailToReceiveAdWithError error: GADRequestError!) {
        Debug.print(error.localizedDescription)
        
        guard let presentingViewController = presentingViewController else { return }
        
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(1.5)
        bannerView.center = CGPoint(x: CGRectGetMidX(presentingViewController.view.frame), y: CGRectGetMaxY(presentingViewController.view.frame) + (bannerView.frame.size.height / 2))
        bannerView.hidden = true
   
        UIView.commitAnimations()
    }
}

// MARK: - Interstitial Delegates

extension AdMob: GADInterstitialDelegate {
    
    func interstitialDidReceiveAd(ad: GADInterstitial!) {
        Debug.print("AdMob interstitial did receive ad from: \(ad.adNetworkClassName)")
    }
    
    func interstitialWillPresentScreen(ad: GADInterstitial!) {
        Debug.print("AdMob interstitial will present")
        delegate?.adMobAdClicked()
    }
    
    func interstitialWillDismissScreen(ad: GADInterstitial!) {
        Debug.print("AdMob interstitial about to be closed")
    }
    
    func interstitialDidDismissScreen(ad: GADInterstitial!) {
        Debug.print("AdMob interstitial closed, reloading...")
        delegate?.adMobAdClosed()
        interstitialAd = loadInterstitialAd()
    }
    
    func interstitialWillLeaveApplication(ad: GADInterstitial!) {
        Debug.print("AdMob interstitial will leave application")
        delegate?.adMobAdClicked()
    }
    
    func interstitialDidFailToPresentScreen(ad: GADInterstitial!) {
        Debug.print("AdMob interstitial did fail to present")
        // Not sure if to reload here
    }
    
    func interstitial(ad: GADInterstitial!, didFailToReceiveAdWithError error: GADRequestError!) {
        Debug.print(error.localizedDescription)
    }
}

// MARK: - Reward Video Delegates

extension AdMob: GADRewardBasedVideoAdDelegate {
    
    func rewardBasedVideoAdDidOpen(rewardBasedVideoAd: GADRewardBasedVideoAd!) {
        Debug.print("AdMob reward video ad did open")
    }
    
    func rewardBasedVideoAdDidClose(rewardBasedVideoAd: GADRewardBasedVideoAd!) {
        Debug.print("AdMob reward video closed, reloading...")
        delegate?.adMobAdClosed()
        rewardVideoAd = loadRewardVideoAd()
    }
    
    func rewardBasedVideoAdDidReceiveAd(rewardBasedVideoAd: GADRewardBasedVideoAd!) {
        Debug.print("AdMob reward video did receive ad")
    }
    
    func rewardBasedVideoAdDidStartPlaying(rewardBasedVideoAd: GADRewardBasedVideoAd!) {
        Debug.print("AdMob reward video did start playing")
        delegate?.adMobAdClicked()
    }
    
    func rewardBasedVideoAdWillLeaveApplication(rewardBasedVideoAd: GADRewardBasedVideoAd!) {
        Debug.print("AdMob reward video will leave application")
        delegate?.adMobAdClicked()
    }
    
    func rewardBasedVideoAd(rewardBasedVideoAd: GADRewardBasedVideoAd!, didFailToLoadWithError error: NSError!) {
        Debug.print(error.localizedDescription)
    }
    
    func rewardBasedVideoAd(rewardBasedVideoAd: GADRewardBasedVideoAd!, didRewardUserWithReward reward: GADAdReward!) {
        Debug.print("AdMob reward video did reward user")
        delegate?.adMobDidRewardUser(rewardAmount: Int(reward.amount))
    }
}