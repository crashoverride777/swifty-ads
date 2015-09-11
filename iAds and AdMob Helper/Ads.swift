
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
    private var iAdInterAdLoaded = false
    
    private var adMobBannerType = kGADAdSizeSmartBannerPortrait //kGADAdSizeSmartBannerLandscape
    private var adMobInterAd: GADInterstitial!
    
    // adMob Unit ID
    private struct ID {
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
        
        // Preload first inter ad
        if iAdsAreSupported == true {
            iAdLoadInterAd()
        } else {
            adMobInterAd = adMobLoadInterAd()
        }
    }
    
    // MARK: - User Functions
    
    // Load Supported Banner Ad
    class func showSupportedBannerAd() {
        Ads.sharedInstance.showSupportedBannerAd()
    }
    
    func showSupportedBannerAd() {
        if iAdsAreSupported == true {
            iAdLoadBannerAd()
        } else {
            adMobLoadBannerAd()
        }
    }
    
    // Show Supported Inter Ad
    class func showSupportedInterAd() {
        Ads.sharedInstance.showSupportedInterAd()
    }
    
    func showSupportedInterAd() {
        if iAdsAreSupported == true {
            iAdShowInterAd()
        } else {
            adMobShowInterAd()
        }
    }
    
    // Remove Banner Ads
    class func removeBannerAds() {
        Ads.sharedInstance.removeBannerAds()
    }
    
    func removeBannerAds() {
        appDelegate.iAdBannerAdView.delegate = nil
        appDelegate.iAdBannerAdView.removeFromSuperview()
        
        appDelegate.adMobBannerAdView.delegate = nil
        appDelegate.adMobBannerAdView.removeFromSuperview()
    }
    
    // Remove All Ads
    class func removeAllAds() {
        Ads.sharedInstance.removeAllAds()
    }
    
    func removeAllAds() {
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
    
    // MARK: - Internal Functions

    // iAd Banner
    private func iAdLoadBannerAd() {
        print("iAd banner ad loading...")
        appDelegate.iAdBannerAdView = ADBannerView(frame: presentingViewController.view.bounds)
        appDelegate.iAdBannerAdView.delegate = self
        appDelegate.iAdBannerAdView.sizeToFit()
        appDelegate.iAdBannerAdView.center = CGPoint(x: CGRectGetMidX(presentingViewController.view.frame), y: CGRectGetMaxY(presentingViewController.view.frame) + (appDelegate.iAdBannerAdView.frame.size.height / 2))
    }
    
    // iAd Inter
    private func iAdLoadInterAd() {
        print("iAd inter ad loading...")
        iAdInterAd = ADInterstitialAd()
        iAdInterAd.delegate = self
        
        iAdInterAdCloseButton.frame = CGRectMake(13, 13, 22, 22)
        iAdInterAdCloseButton.layer.cornerRadius = 12
        iAdInterAdCloseButton.setTitle("X", forState: .Normal)
        iAdInterAdCloseButton.setTitleColor(UIColor.grayColor(), forState: .Normal)
        iAdInterAdCloseButton.backgroundColor = UIColor.whiteColor()
        iAdInterAdCloseButton.layer.borderColor = UIColor.grayColor().CGColor
        iAdInterAdCloseButton.layer.borderWidth = 2
        iAdInterAdCloseButton.addTarget(self, action: "iAdPressedInterAdCloseButton:", forControlEvents: UIControlEvents.TouchDown)
    }
    
    private func iAdShowInterAd() {
        if iAdInterAd.loaded == true && iAdInterAdLoaded == true {
            print("iAd inter showing")
            presentingViewController.view.addSubview(iAdInterAdView)
            iAdInterAd.presentInView(iAdInterAdView)
            UIViewController.prepareInterstitialAds()
            iAdInterAdView.addSubview(iAdInterAdCloseButton)
            
            // pause game, music etc
        } else {
            print("iAd inter cannot be shown, reloading...")
            iAdLoadInterAd()
        }
    }
    
    func iAdPressedInterAdCloseButton(sender: UIButton) {
        iAdInterAdCloseButton.removeFromSuperview()
        iAdInterAdView.removeFromSuperview()
        iAdInterAd.delegate = nil
        iAdInterAdLoaded = false
        
        iAdLoadInterAd()
        
        // resume game, music etc
    }
    
    // AdMob Banner
    private func adMobLoadBannerAd() {
        print("AdMob banner loading...")
        print("Google Mobile Ads SDK version: " + GADRequest.sdkVersion())
        appDelegate.adMobBannerAdView = GADBannerView(adSize: adMobBannerType)
        appDelegate.adMobBannerAdView.adUnitID = ID.bannerTest //ID.bannerLive
        appDelegate.adMobBannerAdView.delegate = self
        appDelegate.adMobBannerAdView.rootViewController = presentingViewController
        appDelegate.adMobBannerAdView.center = CGPoint(x: CGRectGetMidX(presentingViewController.view.frame), y: CGRectGetMaxY(presentingViewController.view.frame) + (appDelegate.adMobBannerAdView.frame.size.height / 2))
        
        
        let request = GADRequest()
        
        //#if DEBUG // make sure to set the D-DEBUG flag in your project othewise this wont work
        request.testDevices = [ kGADSimulatorID ];
        //#endif
        
        appDelegate.adMobBannerAdView.loadRequest(request)
    }
    
    // AdMob Inter
    private func adMobLoadInterAd() -> GADInterstitial {
        print("AdMob inter loading...")
        
        let adMobInterAd = GADInterstitial(adUnitID: ID.interTest) // ID.interLive
        adMobInterAd.delegate = self
        
        let request = GADRequest()
        
        //#if DEBUG // make sure to set the D-DEBUG flag in your project othewise this wont work.
        request.testDevices = [ kGADSimulatorID ];
        //#endif
        
        adMobInterAd.loadRequest(request)
        
        return adMobInterAd
    }
    
    private func adMobShowInterAd() {
        print("AdMob inter showing")
        if adMobInterAd.isReady == true {
            adMobInterAd.presentFromRootViewController(presentingViewController)
            
            // pause game, music etc.
        } else {
            print("AdMob inter cannot be shown, reloading...")
            adMobInterAd = adMobLoadInterAd()
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
        
        // pause game, music etc
        
        return true
    }
    
    func bannerViewActionDidFinish(banner: ADBannerView!) {
        print("iAd banner closed")
        
        // resume game, music etc
    }
    
    func bannerView(banner: ADBannerView!, didFailToReceiveAdWithError error: NSError!) {
        print("iAd banner error")
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(1.5)
        appDelegate.iAdBannerAdView.center = CGPoint(x: CGRectGetMidX(presentingViewController.view.frame), y: CGRectGetMaxY(presentingViewController.view.frame) + (appDelegate.iAdBannerAdView.frame.size.height / 2))
        appDelegate.iAdBannerAdView.hidden = true
        appDelegate.iAdBannerAdView.delegate = nil
        UIView.commitAnimations()
        
        adMobLoadBannerAd()
    }
}

// iAds Inter
extension Ads: ADInterstitialAdDelegate {
    
    func interstitialAdDidLoad(interstitialAd: ADInterstitialAd!) {
        print("iAd inter did load")
        iAdInterAdView = UIView()
        iAdInterAdView.frame = presentingViewController.view.bounds
        iAdInterAdLoaded = true
    }
    
    func interstitialAdDidUnload(interstitialAd: ADInterstitialAd!) {
        print("iAd inter did unload")
    }
    
    func interstitialAd(interstitialAd: ADInterstitialAd!, didFailWithError error: NSError!) {
        print("iAd inter error")
        print(error.localizedDescription)
        iAdInterAdCloseButton.removeFromSuperview()
        iAdInterAdView.removeFromSuperview()
        iAdInterAd.delegate = nil
        iAdInterAdLoaded = false
        
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
        
        // pause game, music etc
    }
    
    func adViewDidDismissScreen(bannerView: GADBannerView!) {
        print("AdMob banner closed")
        
        // resume game, music etc
    }
    
    func adView(bannerView: GADBannerView!, didFailToReceiveAdWithError error: GADRequestError!) {
        print("AdMob banner error")
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(1.5)
        appDelegate.adMobBannerAdView.center = CGPoint(x: CGRectGetMidX(presentingViewController.view.frame), y: CGRectGetMaxY(presentingViewController.view.frame) + (appDelegate.adMobBannerAdView.frame.size.height / 2))
        appDelegate.adMobBannerAdView.hidden = true
        UIView.commitAnimations()
        
        if iAdsAreSupported == true {
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
        
        // pause game, music etc
    }
    
    func interstitialWillDismissScreen(ad: GADInterstitial!) {
        print("AdMob inter about to be closed")
    }
    
    func interstitialDidDismissScreen(ad: GADInterstitial!) {
        print("AdMob inter closed")
        adMobInterAd = adMobLoadInterAd()
        
        // resume game, music etc
    }
    
    func interstitialWillLeaveApplication(ad: GADInterstitial!) {
        print("AdMob inter about to leave app")
        
        // pause game, music etc
    }
    
    func interstitial(ad: GADInterstitial!, didFailToReceiveAdWithError error: GADRequestError!) {
        print("AdMob inter error")
        adMobInterAd = adMobLoadInterAd()
    }
}
