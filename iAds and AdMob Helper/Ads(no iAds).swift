//
//  Ads(no iAds).swift
//  iAds and AdMob Helper
//
//  Created by Dominik on 02/05/2016.
//  Copyright © 2016 Dominik Ringler. All rights reserved.
//

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

//    v3.7.1

/*
 Abstract:
 A Singleton class to manage banner and interstitial custom adverts and ads from AdMob. This class is only included in the iOS version of the project.
 */

import GoogleMobileAds


/*

 
/// Hide print statements for release. Can be used for every print statement in your project
struct Debug {
    static func print(object: Any) {
        #if DEBUG
            Swift.print("DEBUG", object) //, terminator: "")
        #endif
    }
}
 
/// Admob ad unit IDs
private struct AdMobUnitID {
 
    static var Banner: String {
        #if !DEBUG
        return "Enter your real adMob banner ID" // REAL ID
        #else
        return "ca-app-pub-3940256099942544/2934735716"
        #endif
    }
 
    static var Inter: String {
        #if !DEBUG
        return "Enter your real adMob inter ID" // REAL ID
        #else
        return "ca-app-pub-3940256099942544/4411468910"
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

/// Custom ads settings
private struct CustomAd {
    struct Ad1 {
        static let backgroundColor = UIColor(red:0.08, green:0.62, blue:0.85, alpha:1.0)
        static let headerColor = UIColor.whiteColor()
        static let image = "CustomAd"
        static let headerText = "Played Angry Flappies yet?"
        static let appURL = NSURL(string: "https://itunes.apple.com/gb/app/angry-flappies/id991933749?mt=8")
    }
    struct Ad2 {
        static let backgroundColor = UIColor.orangeColor()
        static let headerColor = UIColor.blackColor()
        static let image = "CustomAd"
        static let headerText = "Played Angry Flappies yet?"
        static let appURL = NSURL(string: "https://itunes.apple.com/gb/app/angry-flappies/id991933749?mt=8")
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
 
    /// Delegate
    weak var delegate: AdsDelegate?
 
    /// Presenting view controller
    private var presentingViewController: UIViewController?
 
    /// AdMob
    private var adMobBannerAdView: GADBannerView?
    private var adMobInterAd: GADInterstitial?
    private var adMobBannerAdID = AdMobUnitID.Banner
    private var adMobInterAdID = AdMobUnitID.Inter
    
    /// Custom ad
    private var customAdView = UIView()
    private var customAdHeaderLabel: UILabel?
    private var customAdImage: UIImageView?
    private var customAdURL: NSURL?
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
        Debug.print("Google Mobile Ads SDK version: " + GADRequest.sdkVersion())
 
        /// Preload first adMob inter ad
        adMobInterAd = adMobLoadInterAd()
    }
    
    // MARK: - User Methods
    
    /// SetUp
    func setUp(viewController viewController: UIViewController, customAdsCount: Int, customAdsInterval: Int) {
        self.presentingViewController = viewController
        self.customAdCount = customAdsCount
        self.customAdInterval = customAdsInterval
    }
 
    /// Show banner ads
    func showBannerWithDelay(delay: NSTimeInterval) {
        guard !removedAds else { return }
        NSTimer.scheduledTimerWithTimeInterval(delay, target: self, selector: #selector(Ads.showBanner), userInfo: nil, repeats: false)
    }
    
    func showBanner() {
        guard !removedAds else { return }
        
        adMobLoadBannerAd()
    }
    
    /// Show inter ads
    func showInterRandomly(randomness randomness: UInt32) {
        guard !removedAds else { return }
        let randomInterAd = Int(arc4random() % randomness)
        guard randomInterAd == 1 else { return }
        showInter()
    }
    
    func showInter() {
        guard !removedAds else { return }
        guard customAdCount != 0 else {
            showingInterAd()
            return
        }
        
        customAdIntervalCounter += 1
        
        guard customAdIntervalCounter == customAdInterval else {
            showingInterAd()
            return
        }
        
        customAdIntervalCounter = 0
        
        let randomCustomInterAd = Int(arc4random() % UInt32(customAdCount))
        
        switch randomCustomInterAd {
            
        case 0:
            if let customAd1 = createCustomAd(CustomAd.Ad1.backgroundColor, headerColor: CustomAd.Ad1.headerColor, headerText: CustomAd.Ad1.headerText, imageName: CustomAd.Ad1.image, appURL: CustomAd.Ad1.appURL) {
                presentingViewController?.view?.window?.rootViewController?.view.addSubview(customAd1)
            }
            
        case 1:
            if let customAd2 = createCustomAd(CustomAd.Ad2.backgroundColor, headerColor: CustomAd.Ad2.headerColor, headerText: CustomAd.Ad2.headerText, imageName: CustomAd.Ad2.image, appURL: CustomAd.Ad2.appURL) {
                presentingViewController?.view?.window?.rootViewController?.view.addSubview(customAd2)
            }
            
        default:
            break
        }
    }
    
    /// Remove banner ads
    func removeBanner() {
        adMobBannerAdView?.delegate = nil
        adMobBannerAdView?.removeFromSuperview()
        presentingViewController?.canDisplayBannerAds = false
        
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
 
        // Removed Ads
        removedAds = true
        
        // Banners
        removeBanner()
        
        // Inter
        adMobInterAd?.delegate = nil
        
        // Custom ad
        customAdView.removeFromSuperview()
    }
    
    /// Orientation changed
    func orientationChanged() {
        guard let presentingViewController = presentingViewController else { return }
        Debug.print("Adjusting ads for new device orientation")
        
        // Admob
        if UIApplication.sharedApplication().statusBarOrientation.isLandscape {
            adMobBannerAdView?.adSize = kGADAdSizeSmartBannerLandscape
        } else {
            adMobBannerAdView?.adSize = kGADAdSizeSmartBannerPortrait
        }
        adMobBannerAdView?.center = CGPoint(x: CGRectGetMidX(presentingViewController.view.frame), y: CGRectGetMaxY(presentingViewController.view.frame) - (adMobBannerAdView!.frame.size.height / 2))
        
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
    
    /// Showing inter ad
    private func showingInterAd() {
        adMobShowInterAd()
    }
}

// MARK: - AdMob
private extension Ads {
    
    /// Admob banner
    func adMobLoadBannerAd() {
        guard let presentingViewController = presentingViewController else { return }
        Debug.print("AdMob banner loading...")
        
        if UIApplication.sharedApplication().statusBarOrientation.isLandscape {
            adMobBannerAdView = GADBannerView(adSize: kGADAdSizeSmartBannerLandscape)
        } else {
            adMobBannerAdView = GADBannerView(adSize: kGADAdSizeSmartBannerPortrait)
        }
        
        adMobBannerAdView?.adUnitID = adMobBannerAdID
        adMobBannerAdView?.delegate = self
        adMobBannerAdView?.rootViewController = presentingViewController
        adMobBannerAdView?.center = CGPoint(x: CGRectGetMidX(presentingViewController.view.frame), y: CGRectGetMaxY(presentingViewController.view.frame) + (adMobBannerAdView!.frame.size.height / 2))
        
        let request = GADRequest()
        
        #if DEBUG
            request.testDevices = [kGADSimulatorID]
        #endif
        
        adMobBannerAdView?.loadRequest(request)
    }
    
    /// Admob inter
    func adMobLoadInterAd() -> GADInterstitial {
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
    func adMobShowInterAd() {
        guard adMobInterAd != nil && adMobInterAd!.isReady else { // calls interDidReceiveAd
            Debug.print("AdMob inter is not ready, reloading")
            adMobInterAd = adMobLoadInterAd() // do not try iAd again incase of error with both and than they show at the wrong time
            return
        }
        
        Debug.print("AdMob inter showing...")
        guard let rootViewController = presentingViewController?.view?.window?.rootViewController else { return }
        adMobInterAd?.presentFromRootViewController(rootViewController)
    }
}

// MARK: - AdMob Banner Delegates
extension Ads: GADBannerViewDelegate {
    
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
        delegate?.pauseTasks()
    }
    
    func adViewDidDismissScreen(bannerView: GADBannerView!) { // dont get called unless model view
        Debug.print("AdMob banner closed")
        delegate?.resumeTasks()
    }
    
    func adView(bannerView: GADBannerView!, didFailToReceiveAdWithError error: GADRequestError!) {
        Debug.print(error.localizedDescription)
        guard let presentingViewController = presentingViewController else { return }
        
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(1.5)
        bannerView.center = CGPoint(x: CGRectGetMidX(presentingViewController.view.frame), y: CGRectGetMaxY(presentingViewController.view.frame) + (bannerView.frame.size.height / 2))
        bannerView.hidden = true
        
        UIView.commitAnimations()
    }
}

// MARK: - AdMob Inter Delegates
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
        //adMobInterAd = adMobLoadInterAd() // can cause issues when no internet, gets stuck in loop
    }
}

// MARK: - Custom Ads
extension Ads {
    
    /// Custom ad show
    private func createCustomAd(backgroundColor: UIColor, headerColor: UIColor, headerText: String, imageName: String, appURL: NSURL?) -> UIView? {
        guard let presentingViewController = presentingViewController else { return nil }
        
        // App URL
        customAdURL = appURL
        
        // Custom view
        customAdView.frame = CGRect(x: 0, y: 0, width: presentingViewController.view.frame.width, height: presentingViewController.view.frame.height)
        customAdView.backgroundColor = backgroundColor
        
        // Header
        customAdHeaderLabel = UILabel()
        customAdHeaderLabel?.text = headerText
        let font = "Damascus"
        if DeviceCheck.iPadPro {
            customAdHeaderLabel?.font = UIFont(name: font, size: 62)
        } else if DeviceCheck.iPad {
            customAdHeaderLabel?.font = UIFont(name: font, size: 36)
        } else {
            customAdHeaderLabel?.font = UIFont(name: font, size: 28)
        }
        customAdHeaderLabel?.frame = CGRectMake(0, 0, presentingViewController.view.frame.width, presentingViewController.view.frame.height)
        customAdHeaderLabel?.center = CGPoint(x: customAdView.frame.width / 2, y: CGRectGetMinY(customAdView.frame) + 80)
        customAdHeaderLabel?.textAlignment = NSTextAlignment.Center
        customAdHeaderLabel?.textColor = headerColor
        customAdView.addSubview(customAdHeaderLabel!)
        
        // Image
        customAdImage = UIImageView(image: UIImage(named: imageName))
        customAdImage?.frame = CGRectMake(0, 0, presentingViewController.view.frame.width / 1.1, presentingViewController.view.frame.height / 2)
        customAdImage?.contentMode = UIViewContentMode.ScaleAspectFit
        customAdImage?.center.x = customAdView.center.x
        customAdImage?.center.y = customAdView.center.y + 20
        customAdView.addSubview(customAdImage!)
        
        // Download button
        let downloadArea = UIButton()
        downloadArea.frame = CGRectMake(0, 0, customAdView.frame.size.width, customAdView.frame.size.height)
        downloadArea.backgroundColor = UIColor.clearColor()
        downloadArea.addTarget(self, action: #selector(Ads.customAdPressedDownloadButton(_:)), forControlEvents: UIControlEvents.TouchDown)
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
        if let url = customAdURL {
            UIApplication.sharedApplication().openURL(url)
        }
    }
}

// MARK: - Inter ad close button
extension Ads {
    
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
        interAdCloseButton.addTarget(self, action: #selector(Ads.pressedInterAdCloseButton(_:)), forControlEvents: UIControlEvents.TouchDown)
    }
    
    /// Pressed inter ad close button
    func pressedInterAdCloseButton(sender: UIButton) {
        Debug.print("Inter ad closed")
        customAdView.removeFromSuperview()
    }
} 
 
 
 
*/