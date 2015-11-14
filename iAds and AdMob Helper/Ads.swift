
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

//    v1.8.2


import iAd
import GoogleMobileAds

class Ads: NSObject {
    
    // MARK: - Properties
    
    /// shared instance
    static let sharedInstance = Ads()
    
    /// presenting view controller
    var presentingViewController: UIViewController!
    
    /// iads are supported
    private var iAdsAreSupported = false
    
    /// iad inter ad
    private var iAdInterAd: ADInterstitialAd?
    
    /// iad inter ad view
    private var iAdInterAdView = UIView()
    
    /// iad inter ad close button
    private var iAdInterAdCloseButton = UIButton(type: UIButtonType.System)
    
    /// admob inter ad
    private var adMobInterAd: GADInterstitial?
    
    /// admob banner ad id
    private var adMobBannerAdID = AdUnitID.Banner.test // change "test" to "live" when releasing
    
    /// admob inter ad id
    private var adMobInterAdID = AdUnitID.Inter.test  // change "test" to "live" when releasing
   
    /// admob ids
    private struct AdUnitID {
        struct Banner {
            static let live = "Your real banner adUnit ID from your google adMob account"
            static let test = "ca-app-pub-3940256099942544/2934735716"
        }
        struct Inter {
            static let live = "Your real inter adUnit ID from your google adMob account"
            static let test = "ca-app-pub-3940256099942544/4411468910"
        }
    }
    
    // MARK: - Init
    override init() {
        super.init()
        print("Ads helper init")
        
        /// check if iads are supported
        iAdsAreSupported = iAdTimeZoneSupported()
        
        /// preload inter ads
        if iAdsAreSupported {
            iAdInterAd = iAdLoadInterAd()
        }
        adMobInterAd = adMobLoadInterAd() // always load AdMob
    }
   
    // MARK: - User Methods
    
    /// show banner ad with delay
    func showBannerAdDelayed() {
        NSTimer.scheduledTimerWithTimeInterval(0.8, target: self, selector: "showBannerAd", userInfo: nil, repeats: false)
    }
    
    /// show banner ad
    func showBannerAd() {
        if iAdsAreSupported {
            iAdLoadBannerAd()
        } else {
            adMobLoadBannerAd()
        }
    }
    
    /// show inter ad
    func showInterAd() {
        if iAdsAreSupported {
            iAdShowInterAd()
        } else {
            adMobShowInterAd()
        }
    }
    
    /// show inter ad randomly (33% chance)
    func showInterAdRandomly() {
        let randomInterAd = Int(arc4random() % 3)
        print("randomInterAd = \(randomInterAd)")
        if randomInterAd == 1 {
            if iAdsAreSupported {
                iAdShowInterAd()
            } else {
                adMobShowInterAd()
            }
        }
    }
    
    /// remove banner ads
    func removeBannerAds() {
        print("Removed banner ads")
        if appDelegate.iAdBannerAdView != nil {
            appDelegate.iAdBannerAdView.delegate = nil
            appDelegate.iAdBannerAdView.removeFromSuperview()
        }
        
        if appDelegate.adMobBannerAdView != nil {
            appDelegate.adMobBannerAdView.delegate = nil
            appDelegate.adMobBannerAdView.removeFromSuperview()
        }
    }
    
    /// remove all ads
    func removeAllAds() {
        print("Removed all ads")
        if appDelegate.iAdBannerAdView != nil {
            appDelegate.iAdBannerAdView.delegate = nil
            appDelegate.iAdBannerAdView.removeFromSuperview()
        }
        
        if iAdInterAd != nil {
            iAdInterAd!.delegate = nil
            iAdInterAdCloseButton.removeFromSuperview()
            iAdInterAdView.removeFromSuperview()
        }
        
        if appDelegate.adMobBannerAdView != nil {
            appDelegate.adMobBannerAdView.delegate = nil
            appDelegate.adMobBannerAdView.removeFromSuperview()
        }
        
        if adMobInterAd != nil {
            adMobInterAd!.delegate = nil
        }
    }
    
    /// device orientation changed
    func orientationChanged() {
        print("Device orientation changed, adjusting ads")
        
        // iad
        if appDelegate.iAdBannerAdView != nil {
            appDelegate.iAdBannerAdView.frame = presentingViewController.view.bounds
            appDelegate.iAdBannerAdView.center = CGPoint(x: CGRectGetMidX(presentingViewController.view.frame), y: CGRectGetMaxY(presentingViewController.view.frame) - (appDelegate.iAdBannerAdView.frame.size.height / 2))
        }
        
        iAdInterAdView.frame = presentingViewController.view.bounds
        
        // admob
        if appDelegate.adMobBannerAdView != nil {
            if UIApplication.sharedApplication().statusBarOrientation.isLandscape {
                appDelegate.adMobBannerAdView.adSize = kGADAdSizeSmartBannerLandscape
            } else {
                appDelegate.adMobBannerAdView.adSize = kGADAdSizeSmartBannerPortrait
            }
        
            appDelegate.adMobBannerAdView.center = CGPoint(x: CGRectGetMidX(presentingViewController.view.frame), y: CGRectGetMaxY(presentingViewController.view.frame) - (appDelegate.adMobBannerAdView.frame.size.height / 2))
        }
    }
    
    // MARK: - Internal Methods

    /// iad show banner ad
    private func iAdLoadBannerAd() {
        print("iAd banner ad loading...")
        appDelegate.iAdBannerAdView = ADBannerView(frame: presentingViewController.view.bounds)
        appDelegate.iAdBannerAdView.delegate = self
        appDelegate.iAdBannerAdView.center = CGPoint(x: CGRectGetMidX(presentingViewController.view.frame), y: CGRectGetMaxY(presentingViewController.view.frame) + (appDelegate.iAdBannerAdView.frame.size.height / 2))
    }
    
    /// iad load inter ad
    private func iAdLoadInterAd() -> ADInterstitialAd {
        print("iAd inter ad loading...")
        let iAdInterAd = ADInterstitialAd()
        iAdInterAd.delegate = self
        
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            iAdInterAdCloseButton.frame = CGRectMake(18, 18, 27, 27)
        } else {
            iAdInterAdCloseButton.frame = CGRectMake(13, 13, 22, 22)
        }
        
        iAdInterAdCloseButton.layer.cornerRadius = 12
        iAdInterAdCloseButton.setTitle("X", forState: .Normal)
        iAdInterAdCloseButton.setTitleColor(UIColor.grayColor(), forState: .Normal)
        iAdInterAdCloseButton.backgroundColor = UIColor.whiteColor()
        iAdInterAdCloseButton.layer.borderColor = UIColor.grayColor().CGColor
        iAdInterAdCloseButton.layer.borderWidth = 2
        iAdInterAdCloseButton.addTarget(self, action: "iAdPressedInterAdCloseButton:", forControlEvents: UIControlEvents.TouchDown)
        
        return iAdInterAd
    }
    
    /// iad show inter ad
    private func iAdShowInterAd() {
        guard iAdInterAd != nil else {
            print("iAd inter is nil, reloading")
            iAdInterAd = iAdLoadInterAd()
            return
        }
        
        if iAdInterAd!.loaded {
            print("iAd inter showing")
            iAdInterAdView.frame = presentingViewController.view.bounds
            presentingViewController.view.addSubview(iAdInterAdView)
            iAdInterAd!.presentInView(iAdInterAdView)
            UIViewController.prepareInterstitialAds()
            iAdInterAdView.addSubview(iAdInterAdCloseButton)
            
            //pauseTasks() // not really needed for inter as you tend to show them when not playing.
        } else {
            print("iAd inter not ready, reloading and trying adMob...")
            iAdInterAd = iAdLoadInterAd()
            adMobShowInterAd() // try AdMob
            
        }
    }
    
    /// iad inter ad pressed close button
    func iAdPressedInterAdCloseButton(sender: UIButton) { // dont make private as its called with a selector
        print("iAd inter closed")
        iAdInterAd!.delegate = nil
        iAdInterAdCloseButton.removeFromSuperview()
        iAdInterAdView.removeFromSuperview()
        iAdInterAd = iAdLoadInterAd()
        
        //resumeTasks() // not really needed for inter as you tend to not show them during gameplay
    }
    
    /// adbob show banner ad
    private func adMobLoadBannerAd() {
        print("AdMob banner loading...")
        print("Google Mobile Ads SDK version: " + GADRequest.sdkVersion())
        
        if UIApplication.sharedApplication().statusBarOrientation.isLandscape {
            appDelegate.adMobBannerAdView = GADBannerView(adSize: kGADAdSizeSmartBannerLandscape)
        } else {
            appDelegate.adMobBannerAdView = GADBannerView(adSize: kGADAdSizeSmartBannerPortrait)
        }
        
        appDelegate.adMobBannerAdView.adUnitID = adMobBannerAdID
        appDelegate.adMobBannerAdView.delegate = self
        appDelegate.adMobBannerAdView.rootViewController = presentingViewController
        appDelegate.adMobBannerAdView.center = CGPoint(x: CGRectGetMidX(presentingViewController.view.frame), y: CGRectGetMaxY(presentingViewController.view.frame) + (appDelegate.adMobBannerAdView.frame.size.height / 2))
        
        let request = GADRequest()
        
        #if DEBUG
        // make sure to set the D-DEBUG flag in your project othewise this wont work.
        // otherwise comment out line below
        request.testDevices = [ kGADSimulatorID ];
        #endif
        
        appDelegate.adMobBannerAdView.loadRequest(request)
    }
    
    /// admob load inter ad
    private func adMobLoadInterAd() -> GADInterstitial {
        print("AdMob inter loading...")
        
        let adMobInterAd = GADInterstitial(adUnitID: adMobInterAdID)
        adMobInterAd.delegate = self
        
        let request = GADRequest()
        
        #if DEBUG
        // make sure to set the D-DEBUG flag in your project or this wont work.
        // otherwise comment out line below
        request.testDevices = [ kGADSimulatorID ];
        #endif
        
        adMobInterAd.loadRequest(request)
        
        return adMobInterAd
    }
    
    /// admob show inter ad
    private func adMobShowInterAd() {
        guard adMobInterAd != nil else {
            print("AdMob inter is nil, reloading")
            adMobInterAd = adMobLoadInterAd()
            return
        }
        
        if adMobInterAd!.isReady {
            print("AdMob inter showing")
            adMobInterAd!.presentFromRootViewController(presentingViewController)
            // pauseTasks() // not really needed for inter as you tend to not show them during gameplay
        } else {
            print("AdMob inter is not ready, reloading...")
            adMobInterAd = adMobLoadInterAd()
            /*
            Do not try iAd again like it does for banner ads.
            They might might get stuck in a loop if there are connection problems
            and the ad than might show at an unexpected moment
            */
        }
    }
    
    /// check if iads are supported
    private func iAdTimeZoneSupported() -> Bool {
        let iAdTimeZones = "America/;US/;Pacific/;Asia/Tokyo;Europe/".componentsSeparatedByString(";")
        let myTimeZone = NSTimeZone.localTimeZone().name
        for zone in iAdTimeZones {
            if (myTimeZone.hasPrefix(zone)) {
                print("iAds supported")
                return true
            }
        }
        print("iAds not supported")
        return false
    }
    
    /// pause tasks in the app/game
    private func pauseTasks() {
        // Pause app/game, music etc here.
        // you could use NSNotifactionCenter or Delegates to call methods in other SKScenes / ViewControllers
    }
    
    /// resume tasks in the app/game
    private func resumeTasks() {
        // Resume app/game, music etc here.
        // you could use NSNotifactionCenter or Delegates to call methods in other SKScenes / ViewControllers
    }
}

// MARK: - Delegates

/// iad banner ad
extension Ads: ADBannerViewDelegate {
    
    func bannerViewWillLoadAd(banner: ADBannerView!) {
    }
    
    func bannerViewDidLoadAd(banner: ADBannerView!) {
        print("iAd banner did load, showing")
        presentingViewController.view.addSubview(appDelegate.iAdBannerAdView)
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(1.5)
        appDelegate.iAdBannerAdView.center = CGPoint(x: CGRectGetMidX(presentingViewController.view.frame), y: CGRectGetMaxY(presentingViewController.view.frame) - (appDelegate.iAdBannerAdView.frame.size.height / 2))
        UIView.commitAnimations()
    }
    
    func bannerViewActionShouldBegin(banner: ADBannerView!, willLeaveApplication willLeave: Bool) -> Bool {
        print("iAd banner clicked")
        pauseTasks()
        
        return true
    }
    
    func bannerViewActionDidFinish(banner: ADBannerView!) {
        print("iAd banner closed")
        resumeTasks()
    }
    
    func bannerView(banner: ADBannerView!, didFailToReceiveAdWithError error: NSError!) {
        print("iAd banner error")
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(1.5)
        appDelegate.iAdBannerAdView.center = CGPoint(x: CGRectGetMidX(presentingViewController.view.frame), y: CGRectGetMaxY(presentingViewController.view.frame) + (appDelegate.iAdBannerAdView.frame.size.height / 2))
        appDelegate.iAdBannerAdView.hidden = true
        UIView.commitAnimations()
        
        appDelegate.iAdBannerAdView.delegate = nil // stop iad banner from reloading
        adMobLoadBannerAd() // try admob
    }
}

/// iad inter ad
extension Ads: ADInterstitialAdDelegate {
    
    func interstitialAdDidLoad(interstitialAd: ADInterstitialAd!) {
        print("iAd inter did load")
    }
    
    func interstitialAdDidUnload(interstitialAd: ADInterstitialAd!) {
        print("iAd inter did unload")
    }
    
    func interstitialAd(interstitialAd: ADInterstitialAd!, didFailWithError error: NSError!) {
        print("iAd inter error \(error)")
        iAdInterAd!.delegate = nil
        iAdInterAdCloseButton.removeFromSuperview()
        iAdInterAdView.removeFromSuperview()
        
        //iAdInterAd = iAdLoadInterAd() // not needed, also could cause performance issues when no internet (stuck in loop trying to fetch)
    }
}

/// admob banner ad
extension Ads: GADBannerViewDelegate {
    
    func adViewDidReceiveAd(bannerView: GADBannerView!) {
        print("AdMob banner did load, showing")
        presentingViewController.view.addSubview(appDelegate.adMobBannerAdView)
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(1.5)
        appDelegate.adMobBannerAdView.center = CGPoint(x: CGRectGetMidX(presentingViewController.view.frame), y: CGRectGetMaxY(presentingViewController.view.frame) - (appDelegate.adMobBannerAdView.frame.size.height / 2))
        UIView.commitAnimations()
    }
    
    func adViewWillPresentScreen(bannerView: GADBannerView!) {
        print("AdMob banner clicked")
        pauseTasks()
    }
    
    func adViewDidDismissScreen(bannerView: GADBannerView!) {
        print("AdMob banner closed")
        resumeTasks()
    }
    
    func adView(bannerView: GADBannerView!, didFailToReceiveAdWithError error: GADRequestError!) {
        print("AdMob banner error")
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(1.5)
        appDelegate.adMobBannerAdView.center = CGPoint(x: CGRectGetMidX(presentingViewController.view.frame), y: CGRectGetMaxY(presentingViewController.view.frame) + (appDelegate.adMobBannerAdView.frame.size.height / 2))
        appDelegate.adMobBannerAdView.hidden = true
        UIView.commitAnimations()
        
        // try iad again if supported.
        if iAdsAreSupported {
            appDelegate.adMobBannerAdView.delegate = nil
            appDelegate.iAdBannerAdView.delegate = self
        }
    }
}

/// admob inter ad
extension Ads: GADInterstitialDelegate {
    
    func interstitialDidReceiveAd(ad: GADInterstitial!) {
        print("AdMob inter did load")
    }
    
    func interstitialWillPresentScreen(ad: GADInterstitial!) {
        print("AdMob inter will present")
        // pauseTasks() // not really needed for inter as you tend to show them when not playing.
    }
    
    func interstitialWillDismissScreen(ad: GADInterstitial!) {
        print("AdMob inter about to be closed")
    }
    
    func interstitialDidDismissScreen(ad: GADInterstitial!) {
        print("AdMob inter closed")
        adMobInterAd = adMobLoadInterAd()
        // resumeTasks() // not really needed for inter as you tend to show them when not playing.
    }
    
    func interstitialWillLeaveApplication(ad: GADInterstitial!) {
        print("AdMob inter about to leave app")
        // pauseTasks() // not really needed for inter as you tend to show them when not playing.
    }
    
    func interstitial(ad: GADInterstitial!, didFailToReceiveAdWithError error: GADRequestError!) {
        print("AdMob inter error")
        //adMobInterAd = adMobLoadInterAd() // not really needed, also could cause performance issues when no internet (stuck in loop trying to fetch)
    }
}
