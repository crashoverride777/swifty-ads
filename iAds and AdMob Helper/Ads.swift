
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

//    v3.4

import iAd
import GoogleMobileAds

/// Hide print statements for release. Can be used for every print statement in your project
struct Debug {
    static func print(object: Any) {
        #if DEBUG
            Swift.print("DEBUG", object) //, terminator: "")
        #endif
    }
}

/// Device check
private struct DeviceCheck {
    static let iPad      = UIDevice.currentDevice().userInterfaceIdiom == .Pad && maxLength == 1024.0
    static let iPadPro   = UIDevice.currentDevice().userInterfaceIdiom == .Pad && maxLength == 1366.0

    static let width     = UIScreen.mainScreen().bounds.size.width
    static let height    = UIScreen.mainScreen().bounds.size.height
    static let maxLength = max(width, height)
    static let minLength = min(width, height)
}

/// Admob ad unit IDs
private struct AdMobUnitID {
    struct Banner {
        static let live = "Enter your real adMob banner ID"
        static let test = "ca-app-pub-3940256099942544/2934735716"
    }
    struct Inter {
        static let live = "Enter your real adMob inter ID"
        static let test = "ca-app-pub-3940256099942544/4411468910"
    }
}

/// Custom ads
private struct CustomAd {
    struct Ad1 {
        static let backgroundColor = UIColor(red:0.08, green:0.62, blue:0.85, alpha:1.0)
        static let headerColor = UIColor.whiteColor()
        static let image = "CustomAd"
        static let headerText = "Played Angry Flappies yet?"
        static let appURL = NSURL(string: "https://itunes.apple.com/gb/app/angry-flappies/id991933749?mt=8")!
    }
    struct Ad2 {
        static let backgroundColor = UIColor.orangeColor()
        static let headerColor = UIColor.blackColor()
        static let image = "CustomAd"
        static let headerText = "Played Angry Flappies yet?"
        static let appURL = NSURL(string: "https://itunes.apple.com/gb/app/angry-flappies/id991933749?mt=8")!
    }
}

/// Delegate
protocol AdsDelegate: class {
    func pauseTasks()
    func resumeTasks()
}

/// Ads singleton class
class Ads: NSObject {
    
    // MARK: - Static Properties
    
    /// Shared instance
    static let sharedInstance = Ads()
    
    // MARK: - Properties
    
    /// Presenting view controller
    var presentingViewController: UIViewController!
    
    /// Delegate
    weak var delegate: AdsDelegate?
    
    /// iAd
    private var iAdsAreSupported = false
    private var iAdBannerAdView: ADBannerView!
    private var iAdInterAd: ADInterstitialAd?
    private var iAdInterAdView = UIView()
    
    /// adMob
    private var adMobBannerAdView: GADBannerView!
    private var adMobInterAd: GADInterstitial?
    private var adMobBannerAdID: String!
    private var adMobInterAdID: String!
    
    /// Custom ad
    private var customAdView = UIView()
    private var customAdHeaderLabel: UILabel!
    private var customAdImage: UIImageView!
    private var customAdURL: NSURL!
    private var customAdCount = 0
    private var customAdInterval = 0
    private var customAdIntervalCounter = 0
    
    /// Inter ads close button (iAd and customAd)
    private var interAdCloseButton = UIButton(type: UIButtonType.System)
    
    /// Removed Ads
    private var removedAds = false
    
    // MARK: - Init
    private override init() {
        super.init()
        Debug.print("Ads init")
        Debug.print("Google Mobile Ads SDK version: " + GADRequest.sdkVersion())
        
        /// Check if in test or release mode
        adMobCheckAdUnitID()
        
        /// Check iAds are supported and preload inter ads first time
        iAdsAreSupported = iAdTimeZoneSupported()
        if iAdsAreSupported {
            iAdInterAd = iAdLoadInterAd()
        }
        adMobInterAd = adMobLoadInterAd() // always load adMob
    }
    
    // MARK: - User Methods
    
    /// Prepare with custom ads
    func includeCustomAds(totalCustomAds customAdCount: Int, interval: Int) {
        self.customAdCount = customAdCount
        self.customAdInterval = interval
    }
    
    /// Show banner ads
    func showBannerAd(withDelay delay: NSTimeInterval) {
        guard !removedAds else { return }
        NSTimer.scheduledTimerWithTimeInterval(delay, target: self, selector: "showBannerAd", userInfo: nil, repeats: false)
    }
    
    func showBannerAd() {
        guard !removedAds else { return }
      
        if iAdsAreSupported {
            //presentingViewController.canDisplayBannerAds = true // // uncomment line to resize view for banner ads. Delegates will not work
            iAdLoadBannerAd() // comment out if above line is used, no need to manually create banner ads with canDisplayBannerAds = true
        } else {
            adMobLoadBannerAd()
        }
    }
    
    /// Show inter ads
    func showInterAd(randomness randomNumber: UInt32) {
        guard !removedAds else { return }
        let randomInterAd = Int(arc4random() % randomNumber)
        guard randomInterAd == 1 else { return }
        showInterAd()
    }
    
    func showInterAd() {
        guard !removedAds else { return }
        guard customAdCount != 0 else {
            showingInterAd()
            return
        }
        
        customAdIntervalCounter++
        guard customAdIntervalCounter == customAdInterval else {
            showingInterAd()
            return
        }
        customAdIntervalCounter = 0

        let randomCustomInterAd = Int(arc4random() % UInt32(customAdCount))
        switch randomCustomInterAd {
            case 0:
                let customAd1 = customAdShow(CustomAd.Ad1.backgroundColor, headerColor: CustomAd.Ad1.headerColor, headerText: CustomAd.Ad1.headerText, imageName: CustomAd.Ad1.image, appURL: CustomAd.Ad1.appURL)
                presentingViewController.view.addSubview(customAd1)
            case 1:
                let customAd2 = customAdShow(CustomAd.Ad2.backgroundColor, headerColor: CustomAd.Ad2.headerColor, headerText: CustomAd.Ad2.headerText, imageName: CustomAd.Ad2.image, appURL: CustomAd.Ad2.appURL)
                presentingViewController.view.addSubview(customAd2)
            default:
                break
        }
    }
    
    /// Remove banner ads
    func removeBannerAd() {
        presentingViewController?.canDisplayBannerAds = false
        iAdBannerAdView?.delegate = nil
        iAdBannerAdView?.removeFromSuperview()
        adMobBannerAdView?.delegate = nil
        adMobBannerAdView?.removeFromSuperview()
    }
    
    /// Remove all ads (IAPs)
    func removeAllAds() {
        Debug.print("Removed all ads")
        
        // Removed Ads
        removedAds = true
        
        // Banners
        removeBannerAd()
        
        // Inter
        iAdInterAd?.delegate = nil
        iAdInterAdView.removeFromSuperview()
        adMobInterAd?.delegate = nil
        
        // Custom ad
        customAdView.removeFromSuperview()
    }
    
    /// Orientation changed
    func orientationChanged() {
        Debug.print("Adjusting ads for new device orientation")
        
        // iAds
        iAdBannerAdView?.frame = presentingViewController.view.bounds
        iAdBannerAdView?.center = CGPoint(x: CGRectGetMidX(presentingViewController.view.frame), y: CGRectGetMaxY(presentingViewController.view.frame) - (iAdBannerAdView.frame.size.height / 2))
        
        iAdInterAdView.frame = presentingViewController.view.bounds
        
        // Admob
        if UIApplication.sharedApplication().statusBarOrientation.isLandscape {
            adMobBannerAdView?.adSize = kGADAdSizeSmartBannerLandscape
        } else {
            adMobBannerAdView?.adSize = kGADAdSizeSmartBannerPortrait
        }
        adMobBannerAdView?.center = CGPoint(x: CGRectGetMidX(presentingViewController.view.frame), y: CGRectGetMaxY(presentingViewController.view.frame) - (adMobBannerAdView.frame.size.height / 2))
        
        // Custom ad
        customAdView.frame = CGRect(x: 0, y: 0, width: presentingViewController.view.frame.width, height: presentingViewController.view.frame.height)
        customAdHeaderLabel?.frame = CGRectMake(0, 0, presentingViewController.view.frame.width, presentingViewController.view.frame.height)
        customAdHeaderLabel?.center = CGPoint(x: customAdView.frame.width / 2, y: CGRectGetMinY(customAdView.frame) + 80)
        customAdImage?.frame = CGRectMake(0, 0, presentingViewController.view.frame.width / 1.1, presentingViewController.view.frame.height / 2)
        customAdImage?.contentMode = UIViewContentMode.ScaleAspectFit
        customAdImage?.center.x = customAdView.center.x
        customAdImage?.center.y = customAdView.center.y + 20
    }
    
    /// AdMob Custom methods (2 delegates dont get called)
    func adMobBannerClicked() {
        Debug.print("AdMob banner clicked")
        delegate?.pauseTasks()
    }
    
    func adMobBannerClosed() {
        Debug.print("AdMob banner closed")
        delegate?.resumeTasks()
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
        iAdBannerAdView = ADBannerView(frame: presentingViewController.view.bounds)
        iAdBannerAdView.delegate = self
        iAdBannerAdView.center = CGPoint(x: CGRectGetMidX(presentingViewController.view.frame), y: CGRectGetMaxY(presentingViewController.view.frame) + (iAdBannerAdView.frame.size.height / 2)) // not sure why divided by 2
    }
    
    /// iAd load inter
    private func iAdLoadInterAd() -> ADInterstitialAd {
        Debug.print("iAds inter loading...")
        
        let iAdInterAd = ADInterstitialAd()
        iAdInterAd.delegate = self
        
        prepareInterAdCloseButton()
        
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
        iAdInterAdView.addSubview(interAdCloseButton)
    }
    
    /// AdMob check ad unit id
    private func adMobCheckAdUnitID() {
        #if DEBUG
            Debug.print("Ads in test mode")
            adMobBannerAdID = AdMobUnitID.Banner.test
            adMobInterAdID = AdMobUnitID.Inter.test
        #endif
        
        #if !DEBUG
            Debug.print("Ads in live mode")
            adMobBannerAdID = AdMobUnitID.Banner.live
            adMobInterAdID = AdMobUnitID.Inter.live
        #endif
    }
    
    /// Admob banner
    private func adMobLoadBannerAd() {
        Debug.print("AdMob banner loading...")
        
        if UIApplication.sharedApplication().statusBarOrientation.isLandscape {
            adMobBannerAdView = GADBannerView(adSize: kGADAdSizeSmartBannerLandscape)
        } else {
            adMobBannerAdView = GADBannerView(adSize: kGADAdSizeSmartBannerPortrait)
        }
        
        adMobBannerAdView.adUnitID = adMobBannerAdID
        adMobBannerAdView.delegate = self
        adMobBannerAdView.rootViewController = presentingViewController
        adMobBannerAdView.center = CGPoint(x: CGRectGetMidX(presentingViewController.view.frame), y: CGRectGetMaxY(presentingViewController.view.frame) + (adMobBannerAdView.frame.size.height / 2))
        
        let request = GADRequest()
        
        #if DEBUG
            request.testDevices = [kGADSimulatorID]
        #endif
        
        adMobBannerAdView.loadRequest(request)
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
        let font = "Damascus"
        if DeviceCheck.iPadPro {
            customAdHeaderLabel.font = UIFont(name: font, size: 62)
        } else if DeviceCheck.iPad {
            customAdHeaderLabel.font = UIFont(name: font, size: 36)
        } else {
            customAdHeaderLabel.font = UIFont(name: font, size: 28)
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
        let downloadArea = UIButton()
        downloadArea.frame = CGRectMake(0, 0, customAdView.frame.size.width, customAdView.frame.size.height)
        downloadArea.backgroundColor = UIColor.clearColor()
        downloadArea.addTarget(self, action: "customAdPressedDownloadButton:", forControlEvents: UIControlEvents.TouchDown)
        downloadArea.center = CGPoint(x: CGRectGetMidX(customAdView.frame), y: CGRectGetMidY(customAdView.frame))
        customAdView.addSubview(downloadArea)
        
        // Close button
        prepareInterAdCloseButton()
        customAdView.addSubview(interAdCloseButton)
        
        // Return custom ad view
        return customAdView
    }
    
    /// Pressed custom inter download button
    func customAdPressedDownloadButton(sender: UIButton) {
        UIApplication.sharedApplication().openURL(customAdURL)
    }
    
    /// Prepare inter ad close button
    private func prepareInterAdCloseButton() {
        if DeviceCheck.iPadPro {
            interAdCloseButton.frame = CGRectMake(28, 28, 37, 37)
            interAdCloseButton.layer.cornerRadius = 18
        } else if DeviceCheck.iPad {
            interAdCloseButton.frame = CGRectMake(19, 19, 28, 28)
            interAdCloseButton.layer.cornerRadius = 14
        } else {
            interAdCloseButton.frame = CGRectMake(12, 12, 21, 21)
            interAdCloseButton.layer.cornerRadius = 11
        }
        
        interAdCloseButton.setTitle("X", forState: .Normal)
        interAdCloseButton.setTitleColor(UIColor.grayColor(), forState: .Normal)
        interAdCloseButton.backgroundColor = UIColor.whiteColor()
        interAdCloseButton.layer.borderColor = UIColor.grayColor().CGColor
        interAdCloseButton.layer.borderWidth = 2
        interAdCloseButton.addTarget(self, action: "pressedInterAdCloseButton:", forControlEvents: UIControlEvents.TouchDown)
    }
    
    /// Pressed inter ad close button
    func pressedInterAdCloseButton(sender: UIButton) {
        Debug.print("Inter ad closed")
        customAdView.removeFromSuperview()
        iAdInterAdView.removeFromSuperview()
        iAdInterAd = iAdLoadInterAd()
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
        presentingViewController.view.addSubview(iAdBannerAdView)
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(1.5)
        iAdBannerAdView.center = CGPoint(x: CGRectGetMidX(presentingViewController.view.frame), y: CGRectGetMaxY(presentingViewController.view.frame) - (iAdBannerAdView.frame.size.height / 2))
        UIView.commitAnimations()
    }
    
    func bannerViewActionShouldBegin(banner: ADBannerView!, willLeaveApplication willLeave: Bool) -> Bool {
        Debug.print("iAds banner clicked")
        delegate?.pauseTasks()
        return true
    }
    
    func bannerViewActionDidFinish(banner: ADBannerView!) {
        Debug.print("iAds banner closed")
        delegate?.resumeTasks()
        
        /// Adjust for ipads incase orientation was portrait. iAd banners on ipads are shown in landscape and they get messed up after closing
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            iAdBannerAdView.hidden = true
            let delay: NSTimeInterval = 1 // use delay it wont work
            NSTimer.scheduledTimerWithTimeInterval(delay, target: self, selector: "orientationChanged", userInfo: nil, repeats: false)
            NSTimer.scheduledTimerWithTimeInterval(delay, target: self, selector: "showBannerAgain", userInfo: nil, repeats: false)
        }
    }
    func showBannerAgain() {
        iAdBannerAdView.hidden = false
    }
    
    func bannerView(banner: ADBannerView!, didFailToReceiveAdWithError error: NSError!) {
        Debug.print("iAds banner error")
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(1.5)
        iAdBannerAdView.hidden = true
        iAdBannerAdView.center = CGPoint(x: CGRectGetMidX(presentingViewController.view.frame), y: CGRectGetMaxY(presentingViewController.view.frame) + (iAdBannerAdView.frame.size.height / 2))
        iAdBannerAdView.delegate = nil
        iAdBannerAdView.removeFromSuperview()
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
        iAdInterAdView.removeFromSuperview()
        iAdInterAd = iAdLoadInterAd()
    }
}

// MARK: - Delegates AdMob Banner
extension Ads: GADBannerViewDelegate {
    
    func adViewDidReceiveAd(bannerView: GADBannerView!) {
        Debug.print("AdMob banner did load, showing")
        presentingViewController.view.addSubview(adMobBannerAdView)
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(1.5)
        adMobBannerAdView.center = CGPoint(x: CGRectGetMidX(presentingViewController.view.frame), y: CGRectGetMaxY(presentingViewController.view.frame) - (adMobBannerAdView.frame.size.height / 2))
        UIView.commitAnimations()
    }
    
    func adViewWillPresentScreen(bannerView: GADBannerView!) { // dont get called unless modal view
        Debug.print("AdMob banner clicked")
        delegate?.pauseTasks()
    }

    func adViewDidDismissScreen(bannerView: GADBannerView!) { // dont get called unless model view
        Debug.print("AdMob banner closed")
        delegate?.resumeTasks()
    }

    func adView(bannerView: GADBannerView!, didFailToReceiveAdWithError error: GADRequestError!) {
        Debug.print("AdMob banner error")
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(1.5)
        adMobBannerAdView.center = CGPoint(x: CGRectGetMidX(presentingViewController.view.frame), y: CGRectGetMaxY(presentingViewController.view.frame) + (adMobBannerAdView.frame.size.height / 2))
        adMobBannerAdView.hidden = true
        
        if iAdsAreSupported {
            adMobBannerAdView.delegate = nil
            adMobBannerAdView.removeFromSuperview()
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
        adMobInterAd = adMobLoadInterAd()
    }
}