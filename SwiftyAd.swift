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
private enum LocalizedString {
    static let sorry = "Sorry"
    static let ok = "OK"
    static let noVideo = "No video available to watch at the moment."
}

/// SwiftyAdsDelegate
protocol SwiftyAdDelegate: class {
    /// SwiftyAd did open
    func swiftyAdDidOpen(_ swiftyAd: SwiftyAd)
    /// SwiftyAd did close
    func swiftyAdDidClose(_ swiftyAd: SwiftyAd)
    /// SwiftyAd did reward user
    func swiftyAd(_ swiftyAd: SwiftyAd, didRewardUserWithAmount rewardAmount: Int)
}

/**
 SwiftyAd
 
 A helper class to manage adverts from AdMob.
 */
final class SwiftyAd: NSObject {
    
    /// Banner position
    enum BannerPosition {
        case bottom
        case top
    }
    
    // MARK: - Static Properties
    
    /// Shared instance
    static let shared = SwiftyAd()
    
    // MARK: - Properties
    
    /// Delegates
    weak var delegate: SwiftyAdDelegate?
    
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
    
    /// Ads
    private var bannerViewAd: GADBannerView?
    private var interstitialAd: GADInterstitial?
    private var rewardedVideoAd: GADRewardBasedVideoAd?
    
    /// Test Ad Unit IDs. Will get set to real ID in setup method
    private var bannerViewAdUnitID = "ca-app-pub-3940256099942544/2934735716"
    private var interstitialAdUnitID = "ca-app-pub-3940256099942544/4411468910"
    private var rewardedVideoAdUnitID = "ca-app-pub-1234567890123456/1234567890" // todo -> doesnt seem to work anymore
    
    /// Interval counter
    private var intervalCounter = 0
    
    /// Reward amount backup
    private var rewardAmountBackup = 1
    
    /// Banner position
    private var bannerPosition = BannerPosition.bottom
    
    /// Banner size
    private var bannerSize: GADAdSize {
        let isLandscape = UIApplication.shared.statusBarOrientation.isLandscape
        return isLandscape ? kGADAdSizeSmartBannerLandscape : kGADAdSizeSmartBannerPortrait
    }
    
    // MARK: - Init
    
    /// Init
    private override init() { }
    
    // MARK: - Setup
    
    /// Setup
    ///
    /// - parameter bannerID: The banner adUnitID for this app.
    /// - parameter interstitialID: The interstitial adUnitID for this app.
    /// - parameter rewardedVideoID: The rewarded video adUnitID for this app.
    /// - parameter rewardAmountBackup: The rewarded amount backup used incase the server amount cannot be fetched or is 0. Defaults to 1.
    func setup(withBannerID bannerID: String, interstitialID: String, rewardedVideoID: String, rewardAmountBackup: Int = 1) {
        self.rewardAmountBackup = rewardAmountBackup
        
        print("Google Mobile Ads SDK version \(GADRequest.sdkVersion())")
        
        #if !DEBUG
            bannerViewAdUnitID = bannerID
            interstitialAdUnitID = interstitialID
            rewardedVideoAdUnitID = rewardedVideoID
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
    /// - parameter interval: The interval of when to show the ad, e.g every 4th time this method is called. Defaults to nil.
    func showInterstitial(from viewController: UIViewController, withInterval interval: Int? = nil) {
        guard !isRemoved, isInterstitialReady else { return }
        
        if let interval = interval {
            intervalCounter += 1
            guard intervalCounter >= interval else { return }
            intervalCounter = 0
        }
    
        print("AdMob interstitial is showing")
        interstitialAd?.present(fromRootViewController: viewController)
    }
    
    // MARK: - Show Reward Video
    
    /// Show rewarded video ad
    /// Do not show automatically, use a dedicated reward video button.
    ///
    /// - parameter viewController: The view controller that will present the ad.
    func showRewardedVideo(from viewController: UIViewController) {
        guard isRewardedVideoReady else {
            showNoVideoAvailableAlert(from: viewController)
            return
        }

        print("AdMob reward video is showing")
        rewardedVideoAd?.present(fromRootViewController: viewController)
    }
    
    // MARK: - Remove Banner
    
    /// Remove banner ads
    func removeBanner() {
        print("Removed banner ad")
        
        bannerViewAd?.delegate = nil
        bannerViewAd?.removeFromSuperview()
        bannerViewAd = nil
    }
    
    // MARK: - Update For Orientation
    
    /// Handle orientation chang
    func updateOrientation() {
        print("AdMob banner orientation updated")
        guard let bannerViewAd = bannerViewAd else { return }
        bannerViewAd.adSize = bannerSize
        setBannerToOnScreenPosition(bannerViewAd, from: bannerViewAd.rootViewController)
    }
}

// MARK: - Requesting Ad

private extension SwiftyAd {
    
    /// Load banner ad
    func loadBannerAd(from viewController: UIViewController) {
        print("AdMob banner ad loading...")
    
        bannerViewAd?.removeFromSuperview()
        bannerViewAd = GADBannerView(adSize: bannerSize)
        
        guard let bannerViewAd = bannerViewAd else { return }
       
        bannerViewAd.adUnitID = bannerViewAdUnitID
        bannerViewAd.delegate = self
        bannerViewAd.rootViewController = viewController
        bannerViewAd.isHidden = true
        setBannerToOffScreenPosition(bannerViewAd, from: viewController)
        
        viewController.view.addSubview(bannerViewAd)
        
        let request = GADRequest()
        #if DEBUG
            request.testDevices = [kGADSimulatorID]
        #endif
        bannerViewAd.load(request)
    }

    /// Load interstitial ad
    func loadInterstitialAd() {
        print("AdMob interstitial ad loading...")
        
        interstitialAd = GADInterstitial(adUnitID: interstitialAdUnitID)
        
        guard let interstitialAd = interstitialAd else { return }
        
        interstitialAd.delegate = self
        
        let request = GADRequest()
        #if DEBUG
            request.testDevices = [kGADSimulatorID]
        #endif
        interstitialAd.load(request)
    }
    
    /// Load rewarded video ad
    func loadRewardedVideoAd() {
        print("AdMob rewarded video ad loading...")
        
        rewardedVideoAd = GADRewardBasedVideoAd.sharedInstance()
        
        guard let rewardedVideoAd = rewardedVideoAd else { return }
        
        rewardedVideoAd.delegate = self
        
        let request = GADRequest()
        #if DEBUG
            request.testDevices = [kGADSimulatorID]
        #endif
        rewardedVideoAd.load(request, withAdUnitID: rewardedVideoAdUnitID)
    }
}

// MARK: - GADBannerViewDelegate

extension SwiftyAd: GADBannerViewDelegate {
    
    // Did receive
    func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        print("AdMob banner did receive ad from: \(bannerView.adNetworkClassName ?? "")")
    
        bannerView.isHidden = false
        UIView.animate(withDuration: 1.5) { [weak self] in
            self?.setBannerToOnScreenPosition(bannerView, from: bannerView.rootViewController)
        }
    }
    
    // Will present
    func adViewWillPresentScreen(_ bannerView: GADBannerView) { // gets called only in release mode
        print("AdMob banner clicked")
        delegate?.swiftyAdDidOpen(self)
    }
    
    // Will dismiss
    func adViewWillDismissScreen(_ bannerView: GADBannerView) {
        print("AdMob banner about to be closed")
    }
    
    // Did dismiss
    func adViewDidDismissScreen(_ bannerView: GADBannerView) { // gets called in only release mode
        print("AdMob banner closed")
        delegate?.swiftyAdDidClose(self)
    }
    
    // Will leave application
    func adViewWillLeaveApplication(_ bannerView: GADBannerView) {
        print("AdMob banner will leave application")
        delegate?.swiftyAdDidOpen(self)
    }
    
    // Did fail to receive
    func adView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: GADRequestError) {
        print(error.localizedDescription)
        
        UIView.animate(withDuration: 1.5 , animations: { [weak self] in
            self?.setBannerToOffScreenPosition(bannerView, from: bannerView.rootViewController)
        }, completion: { finish in
            bannerView.isHidden = true
        })
    }
}

// MARK: - GADInterstitialDelegate

extension SwiftyAd: GADInterstitialDelegate {
    
    // Did receive
    func interstitialDidReceiveAd(_ ad: GADInterstitial) {
        print("AdMob interstitial did receive ad from: \(ad.adNetworkClassName ?? "")")
    }
    
    // Will present
    func interstitialWillPresentScreen(_ ad: GADInterstitial) {
        print("AdMob interstitial will present")
        delegate?.swiftyAdDidOpen(self)
    }
    
    // Will dismiss
    func interstitialWillDismissScreen(_ ad: GADInterstitial) {
        print("AdMob interstitial about to be closed")
    }
    
    // Did dismiss
    func interstitialDidDismissScreen(_ ad: GADInterstitial) {
        print("AdMob interstitial closed, reloading...")
        delegate?.swiftyAdDidClose(self)
        loadInterstitialAd()
    }
    
    // Will leave application
    func interstitialWillLeaveApplication(_ ad: GADInterstitial) {
        print("AdMob interstitial will leave application")
        delegate?.swiftyAdDidOpen(self)
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

extension SwiftyAd: GADRewardBasedVideoAdDelegate {
    
    // Did open
    func rewardBasedVideoAdDidOpen(_ rewardBasedVideoAd: GADRewardBasedVideoAd) {
        print("AdMob reward video ad did open")
    }
    
    // Did close
    func rewardBasedVideoAdDidClose(_ rewardBasedVideoAd: GADRewardBasedVideoAd) {
        print("AdMob reward video closed, reloading...")
        delegate?.swiftyAdDidClose(self)
        loadRewardedVideoAd()
    }
    
    // Did receive
    func rewardBasedVideoAdDidReceive(_ rewardBasedVideoAd: GADRewardBasedVideoAd) {
        print("AdMob reward video did receive ad")
    }
    
    // Did start playing
    func rewardBasedVideoAdDidStartPlaying(_ rewardBasedVideoAd: GADRewardBasedVideoAd) {
        print("AdMob reward video did start playing")
        delegate?.swiftyAdDidOpen(self)
    }
    
    // Will leave application
    func rewardBasedVideoAdWillLeaveApplication(_ rewardBasedVideoAd: GADRewardBasedVideoAd) {
        print("AdMob reward video will leave application")
        delegate?.swiftyAdDidOpen(self)
    }
    
    // Did fail to load
    func rewardBasedVideoAd(_ rewardBasedVideoAd: GADRewardBasedVideoAd, didFailToLoadWithError error: Error) {
        print(error.localizedDescription)
        
        // Do not reload here as it might cause endless preloads when internet problems
    }
    
    // Did reward user
    func rewardBasedVideoAd(_ rewardBasedVideoAd: GADRewardBasedVideoAd, didRewardUserWith reward: GADAdReward) {
        print("AdMob reward video did reward user with \(reward)")
        
        let rewardInt = Int(truncating: reward.amount)
        let rewardAmount = rewardInt <= 0 ? rewardAmountBackup : rewardInt
        delegate?.swiftyAd(self, didRewardUserWithAmount: rewardAmount)
    }
}

// MARK: - Banner Positions

private extension SwiftyAd {
    
    func setBannerToOnScreenPosition(_ bannerAd: GADBannerView, from viewController: UIViewController?) {
        guard let viewController = viewController else { return }
        
        switch self.bannerPosition {
        case .bottom:
            bannerAd.center = CGPoint(x: viewController.view.frame.midX, y: viewController.view.frame.maxY - (bannerAd.frame.height / 2))
        case .top:
            bannerAd.center = CGPoint(x: viewController.view.frame.midX, y: viewController.view.frame.minY + (bannerAd.frame.height / 2))
        }
    }
    
    func setBannerToOffScreenPosition(_ bannerAd: GADBannerView, from viewController: UIViewController?) {
        guard let viewController = viewController else { return }
        
        switch self.bannerPosition {
        case .bottom:
            bannerAd.center = CGPoint(x: viewController.view.frame.midX, y: viewController.view.frame.maxY + (bannerAd.frame.height / 2))
        case .top:
            bannerAd.center = CGPoint(x: viewController.view.frame.midX, y: viewController.view.frame.minY - (bannerAd.frame.height / 2))
        }
    }
}

// MARK: - Alert

private extension SwiftyAd {
    
    func showNoVideoAvailableAlert(from viewController: UIViewController) {
        let alertController = UIAlertController(title: LocalizedString.sorry, message: LocalizedString.noVideo, preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: LocalizedString.ok, style: .cancel)
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

// MARK: - Print

private extension SwiftyAd {
    
    /// Overrides the default print method so it print statements only show when in DEBUG mode
    func print(_ items: Any...) {
        #if DEBUG
            Swift.print(items)
        #endif
    }
}
