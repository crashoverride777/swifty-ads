
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

//    v1.7


import iAd
import GoogleMobileAds

class Ads: NSObject {
    
    // MARK: - Properties
    static let sharedInstance = Ads()
    
    var presentingViewController: UIViewController!
    
    private var iAdsAreSupported = false
    private var iAdInterAd = ADInterstitialAd()
    private var iAdInterAdView = UIView()
    private var iAdInterAdCloseButton = UIButton(type: UIButtonType.System)
    
    private var adMobInterAd: GADInterstitial!
    
    // adMob Unit ID
    private struct AdUnitID {
        static let bannerLive = "Your real banner adUnit ID from your google adMob account"
        static let interLive = "Your real inter adUnit ID from your google adMob account"
        
        static let bannerTest = "ca-app-pub-3940256099942544/2934735716"
        static let interTest = "ca-app-pub-3940256099942544/4411468910"
    }
    
    // MARK: - Init
    override init() {
        super.init()
        print("Ads helper init")
        iAdsAreSupported = iAdTimeZoneSupported()
        
        // Preload inter ads
        if iAdsAreSupported {
            iAdLoadInterAd()
        }
        adMobInterAd = adMobLoadInterAd() // always load AdMob
    }
   
    // MARK: - User Functions
    
    // Load Supported Banner Ad
    func showSupportedBannerAd() {
        if iAdsAreSupported {
            iAdLoadBannerAd()
        } else {
            adMobLoadBannerAd()
        }
    }
    
    // Show Supported Inter Ad
    func showSupportedInterAd() {
        if iAdsAreSupported {
            iAdShowInterAd()
        } else {
            adMobShowInterAd()
        }
    }
    
    // Show Supported Inter Ad Randomly
    func showSupportedInterAdRandomly() {
        let randomInterAd = Int(arc4random() % 4)
        print("randomInterAd = \(randomInterAd)")
        if randomInterAd == 1 {
            if iAdsAreSupported {
                iAdShowInterAd()
            } else {
                adMobShowInterAd()
            }
        }
    }
    
    // Remove Banner Ads
    func removeBannerAds() {
        print("Removed banner ads")
        appDelegate.iAdBannerAdView.delegate = nil
        appDelegate.iAdBannerAdView.removeFromSuperview()
        
        appDelegate.adMobBannerAdView.delegate = nil
        appDelegate.adMobBannerAdView.removeFromSuperview()
    }
    
    // Remove All Ads
    func removeAllAds() {
        print("Removed all ads")
        appDelegate.iAdBannerAdView.delegate = nil
        appDelegate.iAdBannerAdView.removeFromSuperview()
        
        appDelegate.adMobBannerAdView.delegate = nil
        appDelegate.adMobBannerAdView.removeFromSuperview()
        
        iAdInterAd.delegate = nil
        iAdInterAdCloseButton.removeFromSuperview()
        iAdInterAdView.removeFromSuperview()
        
        if adMobInterAd != nil {
            adMobInterAd.delegate = nil
        }
    }
    
    // Orientation Changed
    func deviceOrientationChanged() {
        print("Device orientation changed, adjusting ads")
        
        // iAds
        appDelegate.iAdBannerAdView.frame = presentingViewController.view.bounds
        appDelegate.iAdBannerAdView.center = CGPoint(x: CGRectGetMidX(presentingViewController.view.frame), y: CGRectGetMaxY(presentingViewController.view.frame) - (appDelegate.iAdBannerAdView.frame.size.height / 2))
        
        iAdInterAdView.frame = presentingViewController.view.bounds
        
        // AdMob
        if UIApplication.sharedApplication().statusBarOrientation.isLandscape {
            appDelegate.adMobBannerAdView.adSize = kGADAdSizeSmartBannerLandscape
        } else {
            appDelegate.adMobBannerAdView.adSize = kGADAdSizeSmartBannerPortrait
        }
        
        appDelegate.adMobBannerAdView.center = CGPoint(x: CGRectGetMidX(presentingViewController.view.frame), y: CGRectGetMaxY(presentingViewController.view.frame) - (appDelegate.adMobBannerAdView.frame.size.height / 2))
    }
    
    // MARK: - Internal Functions

    // iAd Banner
    private func iAdLoadBannerAd() {
        print("iAd banner ad loading...")
        appDelegate.iAdBannerAdView = ADBannerView(frame: presentingViewController.view.bounds)
        appDelegate.iAdBannerAdView.delegate = self
        appDelegate.iAdBannerAdView.center = CGPoint(x: CGRectGetMidX(presentingViewController.view.frame), y: CGRectGetMaxY(presentingViewController.view.frame) + (appDelegate.iAdBannerAdView.frame.size.height / 2))
    }
    
    // iAd Inter
    private func iAdLoadInterAd() {
        print("iAd inter ad loading...")
        iAdInterAd = ADInterstitialAd()  // always create new instance with inter ads
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
    }
    
    private func iAdShowInterAd() {
        if iAdInterAd.loaded {
            print("iAd inter showing")
            //iAdInterAdView = UIView()
            iAdInterAdView.frame = presentingViewController.view.bounds
            presentingViewController.view.addSubview(iAdInterAdView)
            iAdInterAd.presentInView(iAdInterAdView)
            UIViewController.prepareInterstitialAds()
            iAdInterAdView.addSubview(iAdInterAdCloseButton)
            
            pauseTasks()
        } else {
            print("iAd inter cannot be shown, reloading and trying adMob...")
            iAdLoadInterAd()
            adMobShowInterAd() // try AdMob
            
        }
    }
    
    func iAdPressedInterAdCloseButton(sender: UIButton) { // dont make private as its called witha selector 
        print("iAd inter closed")
        iAdInterAd.delegate = nil
        iAdInterAdCloseButton.removeFromSuperview()
        iAdInterAdView.removeFromSuperview()
        iAdLoadInterAd()
        
        resumeTasks()
    }
    
    // AdMob Banner
    private func adMobLoadBannerAd() {
        print("AdMob banner loading...")
        print("Google Mobile Ads SDK version: " + GADRequest.sdkVersion())
        
        if UIApplication.sharedApplication().statusBarOrientation.isLandscape {
            appDelegate.adMobBannerAdView.adSize = kGADAdSizeSmartBannerLandscape
        } else {
            appDelegate.adMobBannerAdView.adSize = kGADAdSizeSmartBannerPortrait
        }
        
        appDelegate.adMobBannerAdView.adUnitID = AdUnitID.bannerTest //AdUnitID.bannerLive
        appDelegate.adMobBannerAdView.delegate = self
        appDelegate.adMobBannerAdView.rootViewController = presentingViewController
        appDelegate.adMobBannerAdView.center = CGPoint(x: CGRectGetMidX(presentingViewController.view.frame), y: CGRectGetMaxY(presentingViewController.view.frame) + (appDelegate.adMobBannerAdView.frame.size.height / 2))
        
        let request = GADRequest()
        
        //#if DEBUG 
        // make sure to set the D-DEBUG flag in your project othewise this wont work.
        // otherwise comment out this line
        request.testDevices = [ kGADSimulatorID ];
        //#endif
        
        appDelegate.adMobBannerAdView.loadRequest(request)
    }
    
    // AdMob Inter
    private func adMobLoadInterAd() -> GADInterstitial {
        print("AdMob inter loading...")
        
        let adMobInterAd = GADInterstitial(adUnitID: AdUnitID.interTest) // AdUnitID.interLive
        adMobInterAd.delegate = self
        
        let request = GADRequest()
        
        //#if DEBUG 
        // make sure to set the D-DEBUG flag in your project othewise this wont work.
        // otherwise comment out this line
        request.testDevices = [ kGADSimulatorID ];
        //#endif
        
        adMobInterAd.loadRequest(request)
        
        return adMobInterAd
    }
    
    private func adMobShowInterAd() {
        print("AdMob inter showing")
        if adMobInterAd.isReady {
            adMobInterAd.presentFromRootViewController(presentingViewController)
            pauseTasks()
        } else {
            print("AdMob inter cannot be shown, reloading...")
            adMobInterAd = adMobLoadInterAd()
            /*
            Do not try iAd again like it does for banner ads.
            They might might get stuck in a loop if there are connection problems
            and the ad than might show at an unexpected moment which is obviously bad
            because they are full screen
            */
        }
    }
    
    // Check iAd Support
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
    
    // Game/App Controls
    private func pauseTasks() {
        // Pause game, music etc here. 
        // You could use NSNotifactionCenter or Delegates to call methods in other SKScenes / ViewControllers
    }
    
    private func resumeTasks() {
        // Resume game, music etc here.
        // You could use NSNotifactionCenter or Delegates to call methods in other SKScenes / ViewControllers
    }
}

// MARK: - Delegates

// iAd Banner
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
        
        appDelegate.iAdBannerAdView.delegate = nil // stop iAd banner from reloading
        adMobLoadBannerAd() // try AdMob
    }
}

// iAds Inter
extension Ads: ADInterstitialAdDelegate {
    
    func interstitialAdDidLoad(interstitialAd: ADInterstitialAd!) {
        print("iAd inter did load")
    }
    
    func interstitialAdDidUnload(interstitialAd: ADInterstitialAd!) {
        print("iAd inter did unload")
    }
    
    func interstitialAd(interstitialAd: ADInterstitialAd!, didFailWithError error: NSError!) {
        print("iAd inter error \(error)")
        iAdInterAd.delegate = nil
        iAdInterAdCloseButton.removeFromSuperview()
        iAdInterAdView.removeFromSuperview()
        iAdLoadInterAd()
    }
}

// AdMob Banner
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
        
        // Try iAd again if supported.
        if iAdsAreSupported {
            appDelegate.adMobBannerAdView.delegate = nil
            appDelegate.iAdBannerAdView.delegate = self
        }
    }
}

// AdMob Inter
extension Ads: GADInterstitialDelegate {
    
    func interstitialDidReceiveAd(ad: GADInterstitial!) {
        print("AdMob inter did load")
    }
    
    func interstitialWillPresentScreen(ad: GADInterstitial!) {
        print("AdMob inter will present")
        pauseTasks()
    }
    
    func interstitialWillDismissScreen(ad: GADInterstitial!) {
        print("AdMob inter about to be closed")
    }
    
    func interstitialDidDismissScreen(ad: GADInterstitial!) {
        print("AdMob inter closed")
        adMobInterAd = adMobLoadInterAd()
        resumeTasks()
    }
    
    func interstitialWillLeaveApplication(ad: GADInterstitial!) {
        print("AdMob inter about to leave app")
        pauseTasks() // dont forget to resume your app/game when going back, use AppDelegate for example
    }
    
    func interstitial(ad: GADInterstitial!, didFailToReceiveAdWithError error: GADRequestError!) {
        print("AdMob inter error")
        adMobInterAd = adMobLoadInterAd()
    }
}
