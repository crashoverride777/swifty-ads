
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
    
    var iAdsAreSupported = false
    
    var interAd = ADInterstitialAd()
    var interAdView = UIView()
    var interAdCloseButton = UIButton(type: UIButtonType.System)
    var interAdLoaded = false
    
    var googleInterAd: GADInterstitial!
    
    var googleBannerType = kGADAdSizeSmartBannerPortrait //kGADAdSizeSmartBannerLandscape
    
    struct ID {
        static let bannerLive = "Your real banner ad ID from your adMob account"
        static let interLive = "Your real inter ad ID from your adMob account"
        
        static let bannerTest = "ca-app-pub-3940256099942544/2934735716"
        static let interTest = "ca-app-pub-3940256099942544/4411468910"
    }
    
    override init() {
        super.init()
        
        print("Ads Helper init")
        iAdsAreSupported = iAdTimeZoneSupported()
        preloadFirstSupportedInterAd()
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
        print("Loading banner ads")
        appDelegate.bannerAdView = ADBannerView(frame: presentingViewController.view.bounds)
         appDelegate.bannerAdView.delegate = self
        appDelegate.bannerAdView.sizeToFit()
        appDelegate.bannerAdView.center = CGPoint(x: CGRectGetMidX(presentingViewController.view.frame), y: CGRectGetMaxY(presentingViewController.view.frame) + (appDelegate.bannerAdView.frame.size.height / 2))
    }
    
    // MARK: AdMob
    func loadGoogleBannerAd() {
        print("Loading adMob banner ad")
        print("Google Mobile Ads SDK version: " + GADRequest.sdkVersion())
        appDelegate.googleBannerAdView = GADBannerView(adSize: googleBannerType)
        appDelegate.googleBannerAdView.adUnitID = ID.bannerTest //ID.bannerLive
        appDelegate.googleBannerAdView.delegate = self
        appDelegate.googleBannerAdView.rootViewController = presentingViewController
        appDelegate.googleBannerAdView.center = CGPoint(x: CGRectGetMidX(presentingViewController.view.frame), y: CGRectGetMaxY(presentingViewController.view.frame) + (appDelegate.googleBannerAdView.frame.size.height / 2))
    
        
        let request = GADRequest()
        
        //#if DEBUG // make sure to set the D-DEBUG flag in your project othewise this wont work
        request.testDevices = [ kGADSimulatorID ];
        //#endif
        
        appDelegate.googleBannerAdView.loadRequest(request)
    }
    
    // MARK: - Inter Ads
    func preloadFirstSupportedInterAd() {
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
        print("iAds Inter preloading")
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
            print("iAds Inter showing")
            presentingViewController.view.addSubview(interAdView)
            interAd.presentInView(interAdView)
            UIViewController.prepareInterstitialAds()
            interAdView.addSubview(interAdCloseButton)
            
            // pause game, music etc
        } else {
            print("iAds Inter cannot be shown, reloading")
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
        print("AdMob Inter preloading")
        
        let googleInterAd = GADInterstitial(adUnitID: ID.interTest) // ID.interLive
        googleInterAd.delegate = self
        
        let request = GADRequest()
        
        //#if DEBUG // set flag as above and comment out line below
        request.testDevices = [ kGADSimulatorID ];
        //#endif
        
        googleInterAd.loadRequest(request)
        
        return googleInterAd
    }
    
    func showGoogleInterAd() {
        print("AdMob Inter showing")
        if googleInterAd.isReady == true {
            googleInterAd.presentFromRootViewController(presentingViewController)
            
            // pause game, music etc.
        } else {
            print("AdMob Inter cannot be shown, reloading")
            googleInterAd = preloadGoogleInterAd()
        }
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
        appDelegate.bannerAdView.delegate = nil
        appDelegate.bannerAdView.removeFromSuperview()
        
        appDelegate.googleBannerAdView.delegate = nil
        appDelegate.googleBannerAdView.removeFromSuperview()
        
        interAd.delegate = nil
        interAdCloseButton.removeFromSuperview()
        interAdView.removeFromSuperview()
        
        if googleInterAd != nil {
            googleInterAd.delegate = nil
        }
    }

    // MARK: - Check iAd Support
    func iAdTimeZoneSupported() -> Bool {
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

// MARK: - iAds Banner Delegates
extension Ads: ADBannerViewDelegate {
    
    func bannerViewWillLoadAd(banner: ADBannerView!) {
        
    }
    
    func bannerViewDidLoadAd(banner: ADBannerView!) {
        print("iAds banner did load")
        presentingViewController.view.addSubview(appDelegate.bannerAdView)
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(1.5)
        appDelegate.bannerAdView.center = CGPoint(x: CGRectGetMidX(presentingViewController.view.frame), y: CGRectGetMaxY(presentingViewController.view.frame) - (appDelegate.bannerAdView.frame.size.height / 2))
        UIView.commitAnimations()
    }
    
    func bannerViewActionShouldBegin(banner: ADBannerView!, willLeaveApplication willLeave: Bool) -> Bool {
        print("iAds Banner clicked")
        
        // pause game, music etc
        
        return true
    }
    
    func bannerViewActionDidFinish(banner: ADBannerView!) {
        print("iAds banner closed")
        
        // resume game, music etc
    }
    
    func bannerView(banner: ADBannerView!, didFailToReceiveAdWithError error: NSError!) {
        print("iAds banner error")
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(1.5)
        appDelegate.bannerAdView.center = CGPoint(x: CGRectGetMidX(presentingViewController.view.frame), y: CGRectGetMaxY(presentingViewController.view.frame) + (appDelegate.bannerAdView.frame.size.height / 2))
        appDelegate.bannerAdView.hidden = true
        appDelegate.bannerAdView.delegate = nil
        UIView.commitAnimations()
        
        loadGoogleBannerAd()
    }
}

// MARK: - iAds Inter Delegates
extension Ads: ADInterstitialAdDelegate {
    
    func interstitialAdDidLoad(interstitialAd: ADInterstitialAd!) {
        print("iAds Inter did preload")
        interAdView = UIView()
        interAdView.frame = presentingViewController.view.bounds
        interAdLoaded = true
    }
    
    func interstitialAdDidUnload(interstitialAd: ADInterstitialAd!) {
        print("iAds Inter did unload")
    }
    
    func interstitialAd(interstitialAd: ADInterstitialAd!, didFailWithError error: NSError!) {
        print("iAds Inter error")
        print(error.localizedDescription)
        interAdCloseButton.removeFromSuperview()
        interAdView.removeFromSuperview()
        interAd.delegate = nil
        interAdLoaded = false
        
        preloadInterAd()
    }
}

// MARK: - AdMob Banner Delegates
extension Ads: GADBannerViewDelegate {
    
    func adViewDidReceiveAd(bannerView: GADBannerView!) {
        print("AdMob banner did load")
        presentingViewController.view.addSubview(appDelegate.googleBannerAdView)
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(1.5)
        appDelegate.googleBannerAdView.center = CGPoint(x: CGRectGetMidX(presentingViewController.view.frame), y: CGRectGetMaxY(presentingViewController.view.frame) - (appDelegate.googleBannerAdView.frame.size.height / 2))
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
        appDelegate.googleBannerAdView.center = CGPoint(x: CGRectGetMidX(presentingViewController.view.frame), y: CGRectGetMaxY(presentingViewController.view.frame) + (appDelegate.googleBannerAdView.frame.size.height / 2))
        appDelegate.googleBannerAdView.hidden = true
        UIView.commitAnimations()
        
        if iAdsAreSupported == true {
            appDelegate.googleBannerAdView.delegate = nil
            appDelegate.bannerAdView.delegate = self
        }
    }
}

// MARK: - AdMob Inter Delegates
extension Ads:  GADInterstitialDelegate {
    
    func interstitialDidReceiveAd(ad: GADInterstitial!) {
        print("AdMob Inter did preload")
    }
    
    func interstitialWillPresentScreen(ad: GADInterstitial!) {
        print("AdMob Inter will present")
        
        // pause game, music etc
    }
    
    func interstitialWillDismissScreen(ad: GADInterstitial!) {
        print("AdMob Inter about to be closed")
    }
    
    func interstitialDidDismissScreen(ad: GADInterstitial!) {
        print("AdMob Inter closed")
        googleInterAd = preloadGoogleInterAd()
        
        // resume game, music etc
    }
    
    func interstitialWillLeaveApplication(ad: GADInterstitial!) {
        print("AdMob Inter about to leave app")
        
        // pause game, music etc
    }
    
    func interstitial(ad: GADInterstitial!, didFailToReceiveAdWithError error: GADRequestError!) {
        print("AdMob Inter error")
        googleInterAd = preloadGoogleInterAd()
    }
}
