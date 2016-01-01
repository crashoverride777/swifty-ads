
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

//    Dont forget to add the custom "-D DEBUG" flag in Targets -> BuildSettings -> SwiftCompiler-CustomFlags -> DEBUG)

//    v3.0

#if os(iOS)
import iAd
import GoogleMobileAds
#endif

// MARK: - Ads Delegate
protocol AdsDelegate: class {
    func pause()
    func resume()
}
// Give empty default implementation so you dont have to confirm to both methods in your SKScene if you only use 1.
extension AdsDelegate {
    func pauseTasks() { }
    func resumeTasks() { }
}

#if os(iOS)
class Ads: NSObject {
    
    // MARK: - Static Properties
    
    /// Shared instance
    static let sharedInstance = Ads()
    
    /// Admob ad unit ids
    private struct AdUnitID {
        struct Banner {
            static let live = "Enter your real adMob banner ID"
            static let test = "ca-app-pub-3940256099942544/2934735716"
        }
        struct Inter {
            static let live = "Enter your real adMob inter ID"
            static let test = "ca-app-pub-3940256099942544/4411468910"
        }
    }
    
    /// Custom ad 1 settings
    private struct CustomAd1 {
        static let backgroundColor = UIColor(red:0.08, green:0.62, blue:0.85, alpha:1.0)
        static let headerColor = UIColor.whiteColor()
        static let image = "CustomAd"
        static let headerText = "Played Angry Flappies yet?"
        static let appURL = NSURL(string: "https://itunes.apple.com/gb/app/angry-flappies/id991933749?mt=8")!
    }
    
    // MARK: - Properties
    
    /// Presenting view controller
    var presentingViewController: UIViewController!
    
    /// Delegate
    weak var delegate: AdsDelegate?
    
    /// Removed Ads
    private var removedAds = false
    
    /// iAds are supported
    private var iAdsAreSupported = false
    
    /// iAd inter
    private var iAdInterAd: ADInterstitialAd?
    
    /// iAd inter view
    private var iAdInterAdView = UIView()
    
    /// iAd inter close button
    private var iAdInterAdCloseButton = UIButton(type: UIButtonType.System)
    
    /// Admob inter
    private var adMobInterAd: GADInterstitial?
    
    /// admob banner id
    private var adMobBannerAdID: String!
    
    /// Admob inter id
    private var adMobInterAdID: String!
    
    /// Custom ad view
    private var customAdView = UIView()
    
    /// Custom ad header
    private var customAdHeaderLabel: UILabel!
    
    /// Custom ad image
    private var customAdImage: UIImageView!
    
    /// Custom ad URL
    private var customAdURL: NSURL!
    
    /// Custom ad counter
    private var customAdCounter = 0
    
    // MARK: - Init
    private override init() {
        super.init()
        Debug.print("Ads init")
        Debug.print("Google Mobile Ads SDK version: " + GADRequest.sdkVersion())
        
        /// Check if in test or release mode
        adMobCheckAdUnitID()
        
        /// Check iAd support
        iAdsAreSupported = iAdTimeZoneSupported()
        
        /// preload inter ads first time
        if iAdsAreSupported {
            iAdInterAd = iAdLoadInterAd()
        }
        adMobInterAd = adMobLoadInterAd() // always load adMob
    }
    
    // MARK: - User Methods
    
    /// Show banner ad delayed
    func showBannerAdDelayed() {
        guard !removedAds else { return }
        NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "showBannerAd", userInfo: nil, repeats: false)
    }
    
    /// Show banner ad
    func showBannerAd() {
        guard !removedAds else { return }
        if iAdsAreSupported {
            iAdLoadBannerAd()
        } else {
            adMobLoadBannerAd()
        }
    }
    
    /// Show inter ad or custom ad randomly
    func showInterAdRandomly(includeCustomAd showCustomAd: Bool) {
        guard !removedAds else { return }
        let randomInterAd = Int(arc4random() % 3)
        guard randomInterAd == 1 else { return }
        showInterAd(includeCustomAd: showCustomAd)
    }
    
    /// Show inter ad
    func showInterAd(includeCustomAd showCustomAd: Bool) {
        guard !removedAds else { return }
        guard showCustomAd else {
            showingInterAd()
            return
        }
        
        customAdCounter++
        
        // Custom ad 1
        if customAdCounter == 4 {
            customAdCounter = 0 // delete if more than one custom ad
            let customAd1 = customAdShow(CustomAd1.backgroundColor, headerColor: CustomAd1.headerColor, headerText: CustomAd1.headerText, imageName: CustomAd1.image, appURL: CustomAd1.appURL)
            presentingViewController.view.addSubview(customAd1)
        }
        
        /*// Custom ad 2
        if customAdCounter == 8 {
            customAdCounter = 0
            let customAd2 = customAdShow(CustomAd2.backgroundColor, headerColor: CustomAd2.headerColor, headerText: CustomAd2.headerText, imageName: CustomAd2.image, appURL: CustomAd2.appURL)
            presentingViewController.view.addSubview(customAd2)
        } */
            
        // iAd or AdMob
        else {
            showingInterAd()
        }
    }
    
    /// Remove banner ads
    func removeBannerAd() {
        appDelegate.iAdBannerAdView?.delegate = nil
        appDelegate.iAdBannerAdView?.removeFromSuperview()
        appDelegate.adMobBannerAdView?.delegate = nil
        appDelegate.adMobBannerAdView?.removeFromSuperview()
    }
    
    /// Remove all ads (IAPs)
    func removeAllAds() {
        Debug.print("Removed all ads")
        
        // Removed Ads
        removedAds = true
        
        // iAd and AdMob banner
        removeBannerAd()
        
        // iAd Inter
        iAdInterAd?.delegate = nil
        iAdInterAdCloseButton.removeFromSuperview()
        iAdInterAdView.removeFromSuperview()
        
        // AdMob Inter
        adMobInterAd?.delegate = nil
        
        // Custom ad
        customAdView.removeFromSuperview()
    }
    
    /// Orientation changed
    func orientationChanged() {
        Debug.print("Adjusting ads for new device orientation")
        
        // iAds
        appDelegate.iAdBannerAdView?.frame = presentingViewController.view.bounds
        appDelegate.iAdBannerAdView?.center = CGPoint(x: CGRectGetMidX(presentingViewController.view.frame), y: CGRectGetMaxY(presentingViewController.view.frame) - (appDelegate.iAdBannerAdView.frame.size.height / 2))
        
        iAdInterAdView.frame = presentingViewController.view.bounds
        
        // Admob
        if UIApplication.sharedApplication().statusBarOrientation.isLandscape {
            appDelegate.adMobBannerAdView?.adSize = kGADAdSizeSmartBannerLandscape
        } else {
            appDelegate.adMobBannerAdView?.adSize = kGADAdSizeSmartBannerPortrait
        }
        appDelegate.adMobBannerAdView?.center = CGPoint(x: CGRectGetMidX(presentingViewController.view.frame), y: CGRectGetMaxY(presentingViewController.view.frame) - (appDelegate.adMobBannerAdView.frame.size.height / 2))
        
        // Custom ad
        customAdView.frame = CGRect(x: 0, y: 0, width: presentingViewController.view.frame.width, height: presentingViewController.view.frame.height)
        customAdHeaderLabel?.frame = CGRectMake(0, 0, presentingViewController.view.frame.width, presentingViewController.view.frame.height)
        customAdHeaderLabel?.center = CGPoint(x: customAdView.frame.width / 2, y: CGRectGetMinY(customAdView.frame) + 80)
        customAdImage?.frame = CGRectMake(0, 0, presentingViewController.view.frame.width / 1.1, presentingViewController.view.frame.height / 2)
        customAdImage?.contentMode = UIViewContentMode.ScaleAspectFit
        customAdImage?.center.x = customAdView.center.x
        customAdImage?.center.y = customAdView.center.y + 20
    }
    
    // MARK: - Private Methods
    
    /// Showing inter ad
    private func showingInterAd() {
        if iAdsAreSupported {
            iAdShowInterAd()
        } else {
            adMobShowInterAd()
        }
    }
    
    /// iAd load banner
    private func iAdLoadBannerAd() {
        Debug.print("iAd banner loading...")
        appDelegate.iAdBannerAdView = ADBannerView(frame: presentingViewController.view.bounds)
        appDelegate.iAdBannerAdView.delegate = self
        appDelegate.iAdBannerAdView.center = CGPoint(x: CGRectGetMidX(presentingViewController.view.frame), y: CGRectGetMaxY(presentingViewController.view.frame) + (appDelegate.iAdBannerAdView.frame.size.height / 2)) // not sure why divided by 2
    }
    
    /// iAd load inter
    private func iAdLoadInterAd() -> ADInterstitialAd {
        Debug.print("iAds inter loading...")
        
        let iAdInterAd = ADInterstitialAd()
        iAdInterAd.delegate = self
        
        // close button
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            iAdInterAdCloseButton.frame = CGRectMake(19, 19, 28, 28)
            iAdInterAdCloseButton.layer.cornerRadius = 14
        } else {
            iAdInterAdCloseButton.frame = CGRectMake(12, 12, 21, 21)
            iAdInterAdCloseButton.layer.cornerRadius = 11
        }
        
        iAdInterAdCloseButton.setTitle("X", forState: .Normal)
        iAdInterAdCloseButton.setTitleColor(UIColor.grayColor(), forState: .Normal)
        iAdInterAdCloseButton.backgroundColor = UIColor.whiteColor()
        iAdInterAdCloseButton.layer.borderColor = UIColor.grayColor().CGColor
        iAdInterAdCloseButton.layer.borderWidth = 2
        iAdInterAdCloseButton.addTarget(self, action: "iAdPressedInterAdCloseButton:", forControlEvents: UIControlEvents.TouchDown) // function such as this with content in brackets need : for selector. VIP
        
        return iAdInterAd
    }
    
    /// iAd show inter
    private func iAdShowInterAd() {
        guard iAdInterAd != nil && iAdInterAd!.loaded else {
            Debug.print("iAds inter is not ready, reloading and trying AdMob")
            iAdInterAd = iAdLoadInterAd()
            adMobShowInterAd() // try AdMob
            return
        }
        
        Debug.print("iAds inter showing")
        iAdInterAdView.frame = presentingViewController.view.bounds
        presentingViewController.view.addSubview(iAdInterAdView)
        iAdInterAd!.presentInView(iAdInterAdView)
        UIViewController.prepareInterstitialAds()
        iAdInterAdView.addSubview(iAdInterAdCloseButton)
    }
    
    /// iAd pressed inter close button
    func iAdPressedInterAdCloseButton(sender: UIButton) {
        Debug.print("iAd inter closed")
        iAdInterAd!.delegate = nil
        iAdInterAdCloseButton.removeFromSuperview()
        iAdInterAdView.removeFromSuperview()
        iAdInterAd = iAdLoadInterAd()
    }
    
    /// AdMob check ad unit id
    func adMobCheckAdUnitID() {
        #if DEBUG
            Debug.print("Ads in test mode")
            adMobBannerAdID = AdUnitID.Banner.test
            adMobInterAdID = AdUnitID.Inter.test
        #endif
        
        #if !DEBUG
            Debug.print("Ads in live mode")
            adMobBannerAdID = AdUnitID.Banner.live
            adMobInterAdID = AdUnitID.Inter.live
        #endif
    }
    
    /// Admob banner
    private func adMobLoadBannerAd() {
        Debug.print("AdMob banner loading...")
        
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
            request.testDevices = [kGADSimulatorID]
        #endif
        
        appDelegate.adMobBannerAdView.loadRequest(request)
    }
    
    /// Admob inter
    private func adMobLoadInterAd() -> GADInterstitial {
        Debug.print("AdMob inter loading...")
        
        let googleInterAd = GADInterstitial(adUnitID: adMobInterAdID)
        googleInterAd.delegate = self
        
        let request = GADRequest()
        
        #if DEBUG
            request.testDevices = [kGADSimulatorID]
        #endif
        
        googleInterAd.loadRequest(request)
        
        return googleInterAd
    }
    
    /// Admob show inter
    private func adMobShowInterAd() {
        guard adMobInterAd != nil && adMobInterAd!.isReady else { // calls interDidReceiveAd
            Debug.print("AdMob inter is not ready, reloading")
            adMobInterAd = adMobLoadInterAd() // do not try iAd again incase of error with both and than they show at the wrong time
            return
        }
        
        Debug.print("AdMob inter showing...")
        adMobInterAd!.presentFromRootViewController(presentingViewController)
    }
    
    /// Custom ad show
    private func customAdShow(backgroundColor: UIColor, headerColor: UIColor, headerText: String, imageName: String, appURL: NSURL) -> UIView {
        
        // App URL
        customAdURL = appURL
        
        // Custom view
        customAdView.frame = CGRect(x: 0, y: 0, width: presentingViewController.view.frame.width, height: presentingViewController.view.frame.height)
        customAdView.backgroundColor = backgroundColor
        
        // Header
        customAdHeaderLabel = UILabel()
        customAdHeaderLabel.text = headerText
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            customAdHeaderLabel.font = UIFont(name: "Damascus", size: 36)
        } else {
            customAdHeaderLabel.font = UIFont(name: "Damascus", size: 28)
        }
        customAdHeaderLabel.frame = CGRectMake(0, 0, presentingViewController.view.frame.width, presentingViewController.view.frame.height)
        customAdHeaderLabel.center = CGPoint(x: customAdView.frame.width / 2, y: CGRectGetMinY(customAdView.frame) + 80)
        customAdHeaderLabel.textAlignment = NSTextAlignment.Center
        customAdHeaderLabel.textColor = headerColor
        customAdView.addSubview(customAdHeaderLabel)
        
        // Image
        customAdImage = UIImageView(image: UIImage(named: imageName))
        customAdImage.frame = CGRectMake(0, 0, presentingViewController.view.frame.width / 1.1, presentingViewController.view.frame.height / 2)
        customAdImage.contentMode = UIViewContentMode.ScaleAspectFit
        customAdImage.center.x = customAdView.center.x
        customAdImage.center.y = customAdView.center.y + 20
        customAdView.addSubview(customAdImage)
        
        // Download button
        let downloadButton = UIButton()
        downloadButton.frame = CGRectMake(0, 0, customAdView.frame.size.width, customAdView.frame.size.height)
        downloadButton.backgroundColor = UIColor.clearColor()
        downloadButton.addTarget(self, action: "customAdPressedDownloadButton:", forControlEvents: UIControlEvents.TouchDown)
        downloadButton.center = CGPoint(x: CGRectGetMidX(customAdView.frame), y: CGRectGetMidY(customAdView.frame))
        customAdView.addSubview(downloadButton)
        
        // Close button
        let closeButton = UIButton(type: UIButtonType.System)
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            closeButton.frame = CGRectMake(19, 19, 28, 28)
            closeButton.layer.cornerRadius = 14
        } else {
            closeButton.frame = CGRectMake(12, 12, 21, 21)
            closeButton.layer.cornerRadius = 11
        }
        closeButton.setTitle("X", forState: .Normal)
        closeButton.setTitleColor(UIColor.grayColor(), forState: .Normal)
        closeButton.backgroundColor = UIColor.whiteColor()
        closeButton.layer.borderColor = UIColor.grayColor().CGColor
        closeButton.layer.borderWidth = 2
        closeButton.addTarget(self, action: "customAdPressedCloseButton:", forControlEvents: UIControlEvents.TouchDown)
        customAdView.addSubview(closeButton)
        
        // Return custom ad view
        return customAdView
    }
    
    /// Pressed custom inter download button
    func customAdPressedDownloadButton(sender: UIButton) {
        UIApplication.sharedApplication().openURL(customAdURL)
    }
    
    /// Pressed custom inter close button
    func customAdPressedCloseButton(sender: UIButton) {
        customAdView.removeFromSuperview()
    }
    
    /// iAds check support
    private func iAdTimeZoneSupported() -> Bool {
        let iAdTimeZones = "America/;US/;Pacific/;Asia/Tokyo;Europe/".componentsSeparatedByString(";")
        let myTimeZone = NSTimeZone.localTimeZone().name
        for zone in iAdTimeZones {
            if (myTimeZone.hasPrefix(zone)) {
                Debug.print("iAds supported")
                return true
            }
        }
        Debug.print("iAds not supported")
        return false
    }
}

// MARK: - Delegates iAd Banner
extension Ads: ADBannerViewDelegate {
    
    func bannerViewWillLoadAd(banner: ADBannerView!) {
        Debug.print("iAds banner will load")
    }
    
    func bannerViewDidLoadAd(banner: ADBannerView!) {
        Debug.print("iAds banner did load, showing")
        presentingViewController.view.addSubview(appDelegate.iAdBannerAdView)
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(1.5)
        appDelegate.iAdBannerAdView.center = CGPoint(x: CGRectGetMidX(presentingViewController.view.frame), y: CGRectGetMaxY(presentingViewController.view.frame) - (appDelegate.iAdBannerAdView.frame.size.height / 2))
        UIView.commitAnimations()
    }
    
    func bannerViewActionShouldBegin(banner: ADBannerView!, willLeaveApplication willLeave: Bool) -> Bool {
        Debug.print("iAds banner clicked")
        delegate?.pause()
        return true
    }
    
    func bannerViewActionDidFinish(banner: ADBannerView!) {
        Debug.print("iAds banner closed")
        delegate?.resume()
    }
    
    func bannerView(banner: ADBannerView!, didFailToReceiveAdWithError error: NSError!) {
        Debug.print("iAds banner error")
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(1.5)
        appDelegate.iAdBannerAdView.hidden = true
        appDelegate.iAdBannerAdView.center = CGPoint(x: CGRectGetMidX(presentingViewController.view.frame), y: CGRectGetMaxY(presentingViewController.view.frame) + (appDelegate.iAdBannerAdView.frame.size.height / 2))
        appDelegate.iAdBannerAdView.delegate = nil
        appDelegate.iAdBannerAdView.removeFromSuperview()
        adMobLoadBannerAd()
        UIView.commitAnimations()
    }
}

// MARK: - Delegates iAd Inter
extension Ads: ADInterstitialAdDelegate {
    
    func interstitialAdDidLoad(interstitialAd: ADInterstitialAd!) {
        Debug.print("iAds inter did load")
    }
    
    func interstitialAdDidUnload(interstitialAd: ADInterstitialAd!) {
        Debug.print("iAds inter did unload")
    }
    
    func interstitialAd(interstitialAd: ADInterstitialAd!, didFailWithError error: NSError!) {
        Debug.print("iAds inter error \(error)")
        iAdInterAd!.delegate = nil
        iAdInterAdCloseButton.removeFromSuperview()
        iAdInterAdView.removeFromSuperview()
    }
}

// MARK: - Delegates AdMob Banner
extension Ads: GADBannerViewDelegate {
    
    func adViewDidReceiveAd(bannerView: GADBannerView!) {
        Debug.print("AdMob banner did load, showing")
        presentingViewController.view.addSubview(appDelegate.adMobBannerAdView)
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(1.5)
        appDelegate.adMobBannerAdView.center = CGPoint(x: CGRectGetMidX(presentingViewController.view.frame), y: CGRectGetMaxY(presentingViewController.view.frame) - (appDelegate.adMobBannerAdView.frame.size.height / 2))
        UIView.commitAnimations()
    }
    
    func adViewWillPresentScreen(bannerView: GADBannerView!) {
        Debug.print("AdMob banner clicked")
        delegate?.pause()
    }
    
    func adViewDidDismissScreen(bannerView: GADBannerView!) {
        Debug.print("AdMob banner closed")
        delegate?.resume()
    }
    
    func adView(bannerView: GADBannerView!, didFailToReceiveAdWithError error: GADRequestError!) {
        Debug.print("AdMob banner error")
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(1.5)
        appDelegate.adMobBannerAdView.center = CGPoint(x: CGRectGetMidX(presentingViewController.view.frame), y: CGRectGetMaxY(presentingViewController.view.frame) + (appDelegate.adMobBannerAdView.frame.size.height / 2))
        appDelegate.adMobBannerAdView.hidden = true
        
        if iAdsAreSupported {
            appDelegate.adMobBannerAdView.delegate = nil
            appDelegate.adMobBannerAdView.removeFromSuperview()
            iAdLoadBannerAd()
        }
        
        UIView.commitAnimations()
    }
}

// MARK: - Delegates AdMob Banner
extension Ads: GADInterstitialDelegate {
    
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
        adMobInterAd = adMobLoadInterAd()
    }
    
    func interstitialWillLeaveApplication(ad: GADInterstitial!) {
        Debug.print("AdMob inter about to leave app")
    }
    
    func interstitial(ad: GADInterstitial!, didFailToReceiveAdWithError error: GADRequestError!) {
        Debug.print("AdMob inter error")
    }
}
#endif

// MARK: - Print Debug (can be used for every print statement in your project)
struct Debug {
    static func print(object: Any) {
        
        #if DEBUG
        Swift.print("DEBUG", object) //, terminator: "")
        #endif
    }
}