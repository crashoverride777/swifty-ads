
//  Created by Dominik Ringler on 22/08/2015.

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

class Ads: NSObject, ADBannerViewDelegate, ADInterstitialAdDelegate, GADBannerViewDelegate, GADInterstitialDelegate {
    
    // MARK: - Properties
    static let sharedInstance = Ads()
    
    var presentingViewController: UIViewController!
    
    var iAdsAreSupported = false
    
    var interAd = ADInterstitialAd()
    var interAdView = UIView()
    var interAdCloseButton = UIButton.buttonWithType(UIButtonType.System) as! UIButton
    var interAdLoaded = false
    
    var googleInterAd: GADInterstitial!
    
    var googleBannerType = kGADAdSizeSmartBannerPortrait //kGADAdSizeSmartBannerLandscape
    
    struct ID {
        static let bannerLive = "Your real banner ad ID from your adMob account"
        static let interLive = "Your real inter ad ID from your adMob account"
        
        static let bannerTest = "ca-app-pub-3940256099942544/2934735716"
        static let interTest = "ca-app-pub-3940256099942544/4411468910"
    }
    
    // MARK: - Banner Ads
    class func loadSupportedBannerAd() {
        Ads.sharedInstance.loadSupportedBannerAd()
    }
    
    func loadSupportedBannerAd() {
        if iAdsAreSupported == true {
            loadBannerAd()
        } else {
            loadGoogleBannerAd()
        }
    }
    
    // MARK: iAds
    func loadBannerAd() {
        appDelegate.bannerAdView = ADBannerView(frame: presentingViewController.view.bounds)
         appDelegate.bannerAdView.delegate = self
        appDelegate.bannerAdView.sizeToFit()
        appDelegate.bannerAdView.center = CGPoint(x: CGRectGetMidX(presentingViewController.view.frame), y: CGRectGetMaxY(presentingViewController.view.frame) + (appDelegate.bannerAdView.frame.size.height / 2))
    }
    
    // MARK: AdMob
    func loadGoogleBannerAd() {
        println("Google Mobile Ads SDK version: " + GADRequest.sdkVersion())
        appDelegate.googleBannerAdView = GADBannerView(adSize: googleBannerType)
        appDelegate.googleBannerAdView.adUnitID = ID.bannerTest //ID.bannerLive
        appDelegate.googleBannerAdView.delegate = self
        appDelegate.googleBannerAdView.rootViewController = presentingViewController
        appDelegate.googleBannerAdView.center = CGPoint(x: CGRectGetMidX(presentingViewController.view.frame), y: CGRectGetMaxY(presentingViewController.view.frame) + (appDelegate.googleBannerAdView.frame.size.height / 2))
    
        
        var request = GADRequest()
        
        //#if DEBUG // make sure to set the D-DEBUG flag in your project othewise this wont work
        request.testDevices = [ kGADSimulatorID ];
        //#endif
        
        appDelegate.googleBannerAdView.loadRequest(request)
    }
    
    // MARK: - Inter Ads
    class func preloadSupportedInterAd() {
        Ads.sharedInstance.preloadSupportedInterAd()
    }
    
    func preloadSupportedInterAd() {
        if iAdsAreSupported == true {
            preloadInterAd()
        } else {
            googleInterAd = preloadGoogleInterAd()
        }
    }
    
    class func showSupportedInterAd() {
        Ads.sharedInstance.showSupportedInterAd()
    }
    
    func showSupportedInterAd() {
        if iAdsAreSupported == true {
            showInterAd()
        } else {
            showGoogleInterAd()
        }
    }
    
    // MARK: iAds
    func preloadInterAd() {
        println("iAds Inter preloading")
        interAd = ADInterstitialAd()
        interAd.delegate = self
        
        interAdCloseButton.frame = CGRectMake(13, 13, 22, 22)
        interAdCloseButton.layer.cornerRadius = 12
        interAdCloseButton.setTitle("X", forState: .Normal)
        interAdCloseButton.setTitleColor(UIColor.grayColor(), forState: .Normal)
        interAdCloseButton.backgroundColor = UIColor.whiteColor()
        interAdCloseButton.layer.borderColor = UIColor.grayColor().CGColor
        interAdCloseButton.layer.borderWidth = 2
        interAdCloseButton.addTarget(self, action: "pressedCloseButton:", forControlEvents: UIControlEvents.TouchDown)
    }
    
    func showInterAd() {
        if interAd.loaded == true && interAdLoaded == true {
            println("iAds Inter showing")
            presentingViewController.view.addSubview(interAdView)
            interAd.presentInView(interAdView)
            UIViewController.prepareInterstitialAds()
            interAdView.addSubview(interAdCloseButton)
            
            // pause game, music etc
        } else {
            println("iAds Inter cannot be shown, reloading")
            preloadInterAd()
        }
    }
    
    func pressedCloseButton(sender: UIButton) {
        interAdCloseButton.removeFromSuperview()
        interAdView.removeFromSuperview()
        interAd.delegate = nil
        interAdLoaded = false
        
        preloadInterAd()
        
        // resume game, music etc
    }
    
    // MARK: AdMob
    func preloadGoogleInterAd() -> GADInterstitial {
        println("AdMob Inter preloading")
        
        var googleInterAd = GADInterstitial(adUnitID: ID.interTest) // when going live change ID.interTest to ID.interLive
        googleInterAd.delegate = self
        
        var request = GADRequest()
        
        //#if DEBUG // set flag as above or comment out line below
        request.testDevices = [ kGADSimulatorID ];
        //#endif
        
        googleInterAd.loadRequest(request)
        
        return googleInterAd
    }
    
    func showGoogleInterAd() {
        println("AdMob Inter showing")
        if googleInterAd.isReady == true {
            googleInterAd.presentFromRootViewController(presentingViewController)
        } else {
            googleInterAd = preloadGoogleInterAd()
        }
        
        // pause game, music etc.
    }
    
    // MARK: - Remove Banner Ads
    class func removeBannerAds() {
        Ads.sharedInstance.removeBannerAds()
    }
    
    func removeBannerAds() {
        appDelegate.bannerAdView.delegate = nil
        appDelegate.bannerAdView.removeFromSuperview()
        
        appDelegate.googleBannerAdView.delegate = nil
        appDelegate.googleBannerAdView.removeFromSuperview()
    }
    
    // MARK: - Remove All Ads
    class func removeAllAds() {
        Ads.sharedInstance.removeAllAds()
    }
    
    func removeAllAds() {
        appDelegate.bannerAdView.removeFromSuperview()
        appDelegate.bannerAdView.delegate = nil
        
        appDelegate.googleBannerAdView.removeFromSuperview()
        appDelegate.googleBannerAdView.delegate = nil
        
        interAdCloseButton.removeFromSuperview()
        interAdView.removeFromSuperview()
        interAd.delegate = nil
        
        if googleInterAd != nil {
            googleInterAd.delegate = nil
        }
    }

    // MARK: - iAds Check Support
    class func iAdsCheckSupport() {
        Ads.sharedInstance.iAdsCheckSupport()
    }
    
    func iAdsCheckSupport() {
        iAdsAreSupported = iAdTimeZoneSupported()
    }
    
    func iAdTimeZoneSupported() -> Bool {
        let iAdTimeZones = "America/;US/;Pacific/;Asia/Tokyo;Europe/".componentsSeparatedByString(";")
        var myTimeZone = NSTimeZone.localTimeZone().name
        for zone in iAdTimeZones {
            if (myTimeZone.hasPrefix(zone)) {
                println("iAds supported")
                return true
            }
        }
        println("iAds not supported")
        return false
    }
}

// MARK: - iAds Banner Delegates
extension Ads: ADBannerViewDelegate {
    
    func bannerViewWillLoadAd(banner: ADBannerView!) {
        
    }
    
    func bannerViewDidLoadAd(banner: ADBannerView!) {
        println("iAds banner did load")
        presentingViewController.view.addSubview(appDelegate.bannerAdView)
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(1.5)
        appDelegate.bannerAdView.center = CGPoint(x: CGRectGetMidX(presentingViewController.view.frame), y: CGRectGetMaxY(presentingViewController.view.frame) - (appDelegate.bannerAdView.frame.size.height / 2))
        UIView.commitAnimations()
    }
    
    func bannerViewActionShouldBegin(banner: ADBannerView!, willLeaveApplication willLeave: Bool) -> Bool {
        println("iAds Banner clicked")
        // pause game, music etc
        
        return true
    }
    
    func bannerViewActionDidFinish(banner: ADBannerView!) {
        println("iAds banner closed")
        // resume game, music etc
    }
    
    func bannerView(banner: ADBannerView!, didFailToReceiveAdWithError error: NSError!) {
        println("iAds banner error")
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(1.5)
        appDelegate.bannerAdView.center = CGPoint(x: CGRectGetMidX(presentingViewController.view.frame), y: CGRectGetMaxY(presentingViewController.view.frame) + (appDelegate.bannerAdView.frame.size.height / 2))
        appDelegate.bannerAdView.hidden = true
        appDelegate.bannerAdView.delegate = nil // stop delegate, so it wont try to reload, dont removeFromSuperview as that stops all
        UIView.commitAnimations()
        
        loadGoogleBannerAd()
        
        // resume game, music etc
    }
}

// MARK: - iAds Inter Delegates
extension Ads: ADInterstitialAdDelegate {
    
    func interstitialAdDidLoad(interstitialAd: ADInterstitialAd!) {
        println("iAds Inter did preload")
        interAdView = UIView()
        interAdView.frame = presentingViewController.view.bounds
        interAdLoaded = true
    }
    
    func interstitialAdDidUnload(interstitialAd: ADInterstitialAd!) {
        println("iAds Inter did unload")
    }
    
    func interstitialAd(interstitialAd: ADInterstitialAd!, didFailWithError error: NSError!) {
        println("iAds Inter error")
        println(error.localizedDescription)
        interAdCloseButton.removeFromSuperview() // dont think needed anymore but keep incase
        interAdView.removeFromSuperview()
        interAd.delegate = nil
        interAdLoaded = false
        
        preloadInterAd()
    }
}

// MARK: - AdMob Banner Delegates
extension Ads: GADBannerViewDelegate {
    
    func adViewDidReceiveAd(bannerView: GADBannerView!) {
        println("AdMob banner did load")
        presentingViewController.view.addSubview(appDelegate.googleBannerAdView)
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(1.5)
        appDelegate.googleBannerAdView.center = CGPoint(x: CGRectGetMidX(presentingViewController.view.frame), y: CGRectGetMaxY(presentingViewController.view.frame) - (appDelegate.googleBannerAdView.frame.size.height / 2))
        UIView.commitAnimations()
    }
    
    func adViewWillPresentScreen(bannerView: GADBannerView!) {
        println("AdMob banner clicked")
        // pause game, music etc
    }
    
    func adViewDidDismissScreen(bannerView: GADBannerView!) {
        println("AdMob banner closed")
        // resume game, music etc
    }
    
    func adView(bannerView: GADBannerView!, didFailToReceiveAdWithError error: GADRequestError!) {
        println("AdMob banner error")
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(1.5)
        appDelegate.googleBannerAdView.center = CGPoint(x: CGRectGetMidX(presentingViewController.view.frame), y: CGRectGetMaxY(presentingViewController.view.frame) + (appDelegate.googleBannerAdView.frame.size.height / 2))
        appDelegate.googleBannerAdView.hidden = true
        UIView.commitAnimations()
        
        if iAdsAreSupported == true {
            appDelegate.googleBannerAdView.delegate = nil // stop Google delegate
            appDelegate.bannerAdView.delegate = self // reset the iAds delegate so it reloads new iAds
        }
        
        // resume game, music etc
    }
}

// MARK: - AdMob Inter Delegates
extension Ads:  GADInterstitialDelegate {
    
    func interstitialDidReceiveAd(ad: GADInterstitial!) {
        println("AdMob Inter did preload")
    }
    
    func interstitialWillPresentScreen(ad: GADInterstitial!) {
        println("AdMob Inter will present")
        // pause game, music etc
    }
    
    func interstitialWillDismissScreen(ad: GADInterstitial!) {
        println("AdMob Inter about to be closed")
        googleInterAd = preloadGoogleInterAd()
    }
    
    func interstitialDidDismissScreen(ad: GADInterstitial!) {
        println("AdMob Inter closed")
        
        // resume game, music etc
    }
    
    func interstitialWillLeaveApplication(ad: GADInterstitial!) {
        println("AdMob Inter about to leave app")
        
        // pause game, music etc
    }
    
    func interstitial(ad: GADInterstitial!, didFailToReceiveAdWithError error: GADRequestError!) {
        println("AdMob Inter error")
        googleInterAd = preloadGoogleInterAd()
        
        // resume game, music etc
    }
}
