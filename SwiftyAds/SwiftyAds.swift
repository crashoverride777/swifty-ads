
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

import GoogleMobileAds

/// Localized text (todo)
private enum LocalizedText {
    static let ok = "OK"
    static let sorry = "Sorry"
    static let noVideo = "No video available to watch at the moment."
}


/// SwiftyAdsDelegate
public protocol SwiftyAdsDelegate: class {
    
    /// Ad did open
    func adDidOpen()
    
    /// Ad did close
    func adDidClose()
    
    /// Ad did reward user
    func adDidRewardUser(withAmount rewardAmount: Int)
}

/// SwiftyAdsBannerPosition
enum SwiftyAdsBannerPosition {
    case bottom
    case top
}

/**
 SwiftyAds
 
 Singleton class to manage adverts from AdMob.
 */
final class SwiftyAds: NSObject {
    
    // MARK: - Static Properties
    
    /// Shared instance
    static let shared = SwiftyAds()
    
    // MARK: - Properties
    
    /// Delegates
    weak var delegate: SwiftyAdsDelegate?
    
    /// Remove ads
    var isRemoved = false {
        didSet {
            guard isRemoved else { return }
            removeBanner()
            interstitialAd?.delegate = nil
            interstitialAd = nil
        }
    }
    
    /// Check if interstitial ad is ready (e.g to show alternative ad like a custom ad or something)
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
    
    /// Reward amount backup. If there is a problem fetching the amount from server or its 0 this will be used.
    var rewardAmountBackup = 1
    
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
    
    /// Banner position
    fileprivate var bannerPosition = SwiftyAdsBannerPosition.bottom
    
    /// Banner size
    fileprivate var bannerSize: GADAdSize {
        let isLandscape = UIApplication.shared.statusBarOrientation.isLandscape
        return isLandscape ? kGADAdSizeSmartBannerLandscape : kGADAdSizeSmartBannerPortrait
    }
    
    // MARK: - Init
    
    /// Init
    private override init() {
        print("Google Mobile Ads SDK version \(GADRequest.sdkVersion())")
    }
    
    // MARK: - Setup
    
    /// Setup
    ///
    /// - parameter bannerID: The banner adUnitID for this app.
    /// - parameter interstitialID: The interstitial adUnitID for this app.
    /// - parameter rewardedVideoID: The rewarded video adUnitID for this app.
    func setup(bannerID: String, interstitialID: String, rewardedVideoID: String) {
        #if !DEBUG
            bannerAdUnitID = bannerID
            interstitialAdUnitID = interstitialID
            rewardedVideoAdUnitID = rewardedVideoID
        #endif
        
        loadInterstitialAd()
        loadRewardedVideoAd()
    }
    
    // MARK: - Show Banner
    
    /// Show banner ad
    ///
    /// - parameter position: The position of the banner. Defaults to bottom.
    /// - parameter viewController: The view controller that will present the ad.
    func showBanner(at position: SwiftyAdsBannerPosition = .bottom, from viewController: UIViewController?) {
        guard !isRemoved, let viewController = viewController else { return }
        bannerPosition = position
        loadBannerAd(from: viewController)
    }
    
    // MARK: - Show Interstitial
    
    /// Show interstitial ad randomly
    ///
    /// - parameter interval: The interval of when to show the ad, e.g every 4th time this method is called. Defaults to nil.
    /// - parameter viewController: The view controller that will present the ad.
    func showInterstitial(withInterval interval: Int? = nil, from viewController: UIViewController?) {
        guard !isRemoved, isInterstitialReady else { return }
        
        if let interval = interval {
            intervalCounter += 1
            guard intervalCounter >= interval else { return }
            intervalCounter = 0
        }
        
        guard let viewController = viewController else { return }
        print("AdMob interstitial is showing")
        interstitialAd?.present(fromRootViewController: viewController)
    }
    
    // MARK: - Show Reward Video
    
    /// Show rewarded video ad
    /// Do not show automatically, use a dedicated reward video button.
    ///
    /// - parameter viewController: The view controller that will present the ad.
    func showRewardedVideo(from viewController: UIViewController?) {
        guard isRewardedVideoReady else {
            showAlert(message: LocalizedText.noVideo, from: viewController)
            return
        }
        
        guard let viewController = viewController else { return }
        print("AdMob reward video is showing")
        rewardedVideoAd?.present(fromRootViewController: viewController)
    }
    
    // MARK: - Remove Banner
    
    /// Remove banner ads
    func removeBanner() {
        print("Removed banner ad")
        
        bannerAd?.delegate = nil
        bannerAd?.removeFromSuperview()
        bannerAd = nil
    }
    
    // MARK: - Update For Orientation
    
    /// Orientation changed
    func updateForOrientation(from viewController: UIViewController) {
        guard let bannerAd = bannerAd else { return }
        bannerAd.adSize = bannerSize
        bannerAd.center = CGPoint(x: viewController.view.frame.midX, y: viewController.view.frame.maxY - (bannerAd.frame.height / 2))
    }
}

// MARK: - Requesting Ad

private extension SwiftyAds {
    
    /// Load banner ad
    func loadBannerAd(from viewController: UIViewController) {
        print("AdMob banner ad loading...")
    
        bannerAd?.removeFromSuperview()
        bannerAd = GADBannerView(adSize: bannerSize)
        bannerAd?.adUnitID = bannerAdUnitID
        bannerAd?.delegate = self
        bannerAd?.rootViewController = viewController
        
        switch bannerPosition {
        case .bottom:
            bannerAd?.center = CGPoint(x: viewController.view.frame.midX, y: viewController.view.frame.maxY + (bannerAd!.frame.height / 2))
        case .top:
            bannerAd?.center = CGPoint(x: viewController.view.frame.midX, y: viewController.view.frame.minY - (bannerAd!.frame.height / 2))
        }
        viewController.view.addSubview(bannerAd!)
        
        let request = GADRequest()
        #if DEBUG
            request.testDevices = [kGADSimulatorID]
        #endif
        bannerAd?.load(request)
    }

    /// Load interstitial ad
    func loadInterstitialAd() {
        print("AdMob interstitial ad loading...")
        
        interstitialAd = GADInterstitial(adUnitID: interstitialAdUnitID)
        interstitialAd?.delegate = self
        
        let request = GADRequest()
        #if DEBUG
            request.testDevices = [kGADSimulatorID]
        #endif
        interstitialAd?.load(request)
    }
    
    /// Load rewarded video ad
    func loadRewardedVideoAd() {
        print("AdMob rewarded video ad loading...")
        
        rewardedVideoAd = GADRewardBasedVideoAd.sharedInstance()
        rewardedVideoAd?.delegate = self
        
        let request = GADRequest()
        #if DEBUG
            request.testDevices = [kGADSimulatorID]
        #endif
        rewardedVideoAd?.load(request, withAdUnitID: rewardedVideoAdUnitID)
    }
}

// MARK: - GADBannerViewDelegate

extension SwiftyAds: GADBannerViewDelegate {
    
    // Did receive
    func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        print("AdMob banner did receive ad from: \(bannerView.adNetworkClassName)")
        guard let viewController = bannerView.rootViewController else { return }
        
        bannerView.isHidden = false
        UIView.animate(withDuration: 1.5) {
            
            switch self.bannerPosition {
            case .bottom:
                bannerView.center = CGPoint(x: viewController.view.frame.midX, y: viewController.view.frame.maxY - (bannerView.frame.height / 2))
            case .top:
                bannerView.center = CGPoint(x: viewController.view.frame.midX, y: viewController.view.frame.minY + (bannerView.frame.height / 2))
            }
        }
    }
    
    // Will present
    func adViewWillPresentScreen(_ bannerView: GADBannerView) { // gets called only in release mode
        print("AdMob banner clicked")
        delegate?.adDidOpen()
    }
    
    // Will dismiss
    func adViewWillDismissScreen(_ bannerView: GADBannerView) {
        print("AdMob banner about to be closed")
    }
    
    // Did dismiss
    func adViewDidDismissScreen(_ bannerView: GADBannerView) { // gets called in only release mode
        print("AdMob banner closed")
        delegate?.adDidClose()
    }
    
    // Will leave application
    func adViewWillLeaveApplication(_ bannerView: GADBannerView) {
        print("AdMob banner will leave application")
        delegate?.adDidOpen()
    }
    
    // Did fail to receive
    func adView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: GADRequestError) {
        print(error.localizedDescription)
        
        UIView.animate(withDuration: 1.5 , animations: {
            if let viewController = bannerView.rootViewController {
                switch self.bannerPosition {
                case .bottom:
                    bannerView.center = CGPoint(x: viewController.view.frame.midX, y: viewController.view.frame.maxY + (bannerView.frame.height / 2))
                case .top:
                    bannerView.center = CGPoint(x: viewController.view.frame.midX, y: viewController.view.frame.minY - (bannerView.frame.height / 2))
                }
            }
            
        }, completion: { finish in
            bannerView.isHidden = true
        })
    }
}

// MARK: - GADInterstitialDelegate

extension SwiftyAds: GADInterstitialDelegate {
    
    // Did receive
    func interstitialDidReceiveAd(_ ad: GADInterstitial) {
        print("AdMob interstitial did receive ad from: \(ad.adNetworkClassName)")
    }
    
    // Will present
    func interstitialWillPresentScreen(_ ad: GADInterstitial) {
        print("AdMob interstitial will present")
        delegate?.adDidOpen()
    }
    
    // Will dismiss
    func interstitialWillDismissScreen(_ ad: GADInterstitial) {
        print("AdMob interstitial about to be closed")
    }
    
    // Did dismiss
    func interstitialDidDismissScreen(_ ad: GADInterstitial) {
        print("AdMob interstitial closed, reloading...")
        delegate?.adDidClose()
        loadInterstitialAd()
    }
    
    // Will leave application
    func interstitialWillLeaveApplication(_ ad: GADInterstitial) {
        print("AdMob interstitial will leave application")
        delegate?.adDidOpen()
    }
    
    // Did fail to present
    func interstitialDidFail(toPresentScreen ad: GADInterstitial) {
        print("AdMob interstitial did fail to present")
    }
    
    // Did fail to receive
    func interstitial(_ ad: GADInterstitial, didFailToReceiveAdWithError error: GADRequestError) {
        print(error.localizedDescription)
        
        // Do not reload here as it might cause endless preloads when internet problems
    }
}

// MARK: - GADRewardBasedVideoAdDelegate

extension SwiftyAds: GADRewardBasedVideoAdDelegate {
    
    // Did open
    func rewardBasedVideoAdDidOpen(_ rewardBasedVideoAd: GADRewardBasedVideoAd) {
        print("AdMob reward video ad did open")
    }
    
    // Did close
    func rewardBasedVideoAdDidClose(_ rewardBasedVideoAd: GADRewardBasedVideoAd) {
        print("AdMob reward video closed, reloading...")
        delegate?.adDidClose()
        loadRewardedVideoAd()
    }
    
    // Did receive
    func rewardBasedVideoAdDidReceive(_ rewardBasedVideoAd: GADRewardBasedVideoAd) {
        print("AdMob reward video did receive ad")
    }
    
    // Did start playing
    func rewardBasedVideoAdDidStartPlaying(_ rewardBasedVideoAd: GADRewardBasedVideoAd) {
        print("AdMob reward video did start playing")
        delegate?.adDidOpen()
    }
    
    // Will leave application
    func rewardBasedVideoAdWillLeaveApplication(_ rewardBasedVideoAd: GADRewardBasedVideoAd) {
        print("AdMob reward video will leave application")
        delegate?.adDidOpen()
    }
    
    // Did fail to load
    func rewardBasedVideoAd(_ rewardBasedVideoAd: GADRewardBasedVideoAd, didFailToLoadWithError error: Error) {
        print(error.localizedDescription)
        
        // Do not reload here as it might cause endless preloads when internet problems
    }
    
    // Did reward user
    func rewardBasedVideoAd(_ rewardBasedVideoAd: GADRewardBasedVideoAd, didRewardUserWith reward: GADAdReward) {
        print("AdMob reward video did reward user with \(reward)")
        
        let rewardAmount = reward.amount == 0 ? rewardAmountBackup : Int(reward.amount)
        delegate?.adDidRewardUser(withAmount: rewardAmount)
    }
}

// MARK: - Alert

private extension SwiftyAds {
    
    func showAlert(message: String, from viewController: UIViewController?) {
        guard let viewController = viewController else { return }
        
        let alertController = UIAlertController(title: LocalizedText.sorry, message: message, preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: LocalizedText.ok, style: .cancel)
        alertController.addAction(okAction)
        
        /*
         `Ad` event handlers may be called on a background queue. Ensure
         this alert is presented on the main queue.
         */
        DispatchQueue.main.async {
            viewController.present(alertController, animated: true)
        }
    }
}
