
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

//    v4.0

//    Dont forget to add the custom "-D DEBUG" flag in Targets -> BuildSettings -> SwiftCompiler-CustomFlags -> DEBUG)

/*
    Abstract:
    A Singleton class to manage banner and interstitial adverts from AdMob. This class is only included in the iOS version of the project.
*/

import GoogleMobileAds

/// Admob ad unit IDs
private enum AdMobUnitID: String {
    // Real IDs
    #if !DEBUG
    case Banner = "ca-app-pub-2427795328331194/3512503063"
    case Inter = "ca-app-pub-2427795328331194/4989236269"
    // Test IDs
    #else
    case Banner = "ca-app-pub-3940256099942544/2934735716"
    case Inter = "ca-app-pub-3940256099942544/4411468910"
    #endif
}

/// Delegates
protocol AdMobDelegate: class {
    func adMobPause()
    func adMobResume()
}

protocol AdMobErrorDelegate: class {
    func adMobBannerFail()
    func adMobInterFail()
}

/// Ads singleton class
class AdMob: NSObject {
    
    // MARK: - Static Properties
    
    /// Shared instance
    static let sharedInstance = AdMob()
    
    // MARK: - Properties
    
    /// Delegates
    weak var delegate: AdMobDelegate?
    weak var errorDelegate: AdMobErrorDelegate?
    
    /// Presenting view controller
    private var presentingViewController: UIViewController?
    
    /// Removed ads
    private var removedAds = false
    
    /// Ads
    private var bannerAdView: GADBannerView?
    private var interAd: GADInterstitial?
    
    // MARK: - Init
    
    private override init() {
        super.init()
        Debug.print("Google Mobile Ads SDK version: " + GADRequest.sdkVersion())
        
        // Preload first inter ad
        interAd = loadInterAd()
    }
    
    // MARK: - User Methods
    
    /// SetUp
    func setUp(viewController viewController: UIViewController) {
        presentingViewController = viewController
    }
    
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
    
    /// Show inter ad randomly
    func showInterRandomly(randomness randomness: UInt32) {
        guard !removedAds else { return }
        
        let randomInterAd = Int(arc4random_uniform(randomness)) // get a random number between 0 and 2, so 33%
        guard randomInterAd == 0 else { return }
        showInterAd()
    }
    
    /// Show inter ad
    func showInter() {
        guard !removedAds else { return }
        showInterAd()
    }
    
    /// Remove banner ads
    func removeBanner() {
        bannerAdView?.delegate = nil
        bannerAdView?.removeFromSuperview()
        
        guard let view = presentingViewController?.view else { return }
        
        for subview in view.subviews {
            if let adMobBanner = subview as? GADBannerView {
                adMobBanner.delegate = nil
                adMobBanner.removeFromSuperview()
            }
        }
    }
    
    /// Remove all ads (IAPs)
    func removeAll() {
        Debug.print("Removed all ads")
        removedAds = true
        removeBanner()
        interAd?.delegate = nil
    }
    
    /// Orientation changed
    func orientationChanged() {
        guard let presentingViewController = presentingViewController else { return }
        
        if UIApplication.sharedApplication().statusBarOrientation.isLandscape {
            bannerAdView?.adSize = kGADAdSizeSmartBannerLandscape
        } else {
            bannerAdView?.adSize = kGADAdSizeSmartBannerPortrait
        }
        bannerAdView?.center = CGPoint(x: CGRectGetMidX(presentingViewController.view.frame), y: CGRectGetMaxY(presentingViewController.view.frame) - (bannerAdView!.frame.size.height / 2))
    }
}

// MARK: - Private Methods
private extension AdMob {
    
    /// Admob banner
    func loadBannerAd() {
        guard let presentingViewController = presentingViewController else { return }
        Debug.print("AdMob banner loading...")
        
        if UIApplication.sharedApplication().statusBarOrientation.isLandscape {
            bannerAdView = GADBannerView(adSize: kGADAdSizeSmartBannerLandscape)
        } else {
            bannerAdView = GADBannerView(adSize: kGADAdSizeSmartBannerPortrait)
        }
        
        bannerAdView?.adUnitID = AdMobUnitID.Banner.rawValue
        bannerAdView?.delegate = self
        bannerAdView?.rootViewController = presentingViewController
        bannerAdView?.center = CGPoint(x: CGRectGetMidX(presentingViewController.view.frame), y: CGRectGetMaxY(presentingViewController.view.frame) + (bannerAdView!.frame.size.height / 2))
        
        let request = GADRequest()
        
        #if DEBUG
            request.testDevices = [kGADSimulatorID]
        #endif
        
        bannerAdView?.loadRequest(request)
    }
    
    /// Admob inter
    func loadInterAd() -> GADInterstitial {
        Debug.print("AdMob inter loading...")
        
        let googleInterAd = GADInterstitial(adUnitID: AdMobUnitID.Inter.rawValue)
        googleInterAd.delegate = self
        
        let request = GADRequest()
        
        #if DEBUG
            request.testDevices = [kGADSimulatorID]
        #endif
        
        googleInterAd.loadRequest(request)
        
        return googleInterAd
    }
    
    /// Admob show inter
    func showInterAd() {
        guard interAd != nil && interAd!.isReady else { // calls interDidReceiveAd
            Debug.print("AdMob inter is not ready, reloading")
            interAd = loadInterAd() // do not try iAd again incase of error with both and than they show at the wrong time
            return
        }
        
        Debug.print("AdMob inter showing...")
        guard let rootViewController = presentingViewController?.view?.window?.rootViewController else { return }
        interAd?.presentFromRootViewController(rootViewController)
    }
}

// MARK: - AdMob Banner Delegates
extension AdMob: GADBannerViewDelegate {
    
    func adViewDidReceiveAd(bannerView: GADBannerView!) {
        guard let presentingViewController = presentingViewController else { return }
        Debug.print("AdMob banner did load, showing")
        
        presentingViewController.view?.window?.rootViewController?.view.addSubview(bannerView)
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(1.5)
        bannerView.center = CGPoint(x: CGRectGetMidX(presentingViewController.view.frame), y: CGRectGetMaxY(presentingViewController.view.frame) - (bannerView.frame.size.height / 2))
        UIView.commitAnimations()
    }
    
    func adViewWillPresentScreen(bannerView: GADBannerView!) { // dont get called unless modal view
        Debug.print("AdMob banner clicked")
        delegate?.adMobPause()
    }
    
    func adViewDidDismissScreen(bannerView: GADBannerView!) { // dont get called unless model view
        Debug.print("AdMob banner closed")
        delegate?.adMobResume()
    }
    
    func adView(bannerView: GADBannerView!, didFailToReceiveAdWithError error: GADRequestError!) {
        Debug.print(error.localizedDescription)
        guard let presentingViewController = presentingViewController else { return }
        
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(1.5)
        bannerView.center = CGPoint(x: CGRectGetMidX(presentingViewController.view.frame), y: CGRectGetMaxY(presentingViewController.view.frame) + (bannerView.frame.size.height / 2))
        bannerView.hidden = true
        
        errorDelegate?.adMobBannerFail()
        
        UIView.commitAnimations()
    }
}

// MARK: - AdMob Inter Delegates
extension AdMob: GADInterstitialDelegate {
    
    func interstitialDidReceiveAd(ad: GADInterstitial!) {
        Debug.print("AdMob inter did load")
    }
    
    func interstitialWillPresentScreen(ad: GADInterstitial!) {
        Debug.print("AdMob inter will present")
    }
    
    func interstitialWillDismissScreen(ad: GADInterstitial!) {
        Debug.print("AdMob inter about to be closed")
    }
    
    func interstitialDidDismissScreen(ad: GADInterstitial!) {
        Debug.print("AdMob inter closed")
        interAd = loadInterAd()
    }
    
    func interstitialWillLeaveApplication(ad: GADInterstitial!) {
        Debug.print("AdMob inter about to leave app")
    }
    
    func interstitial(ad: GADInterstitial!, didFailToReceiveAdWithError error: GADRequestError!) {
        Debug.print("AdMob inter error")
        errorDelegate?.adMobInterFail()
    }
}