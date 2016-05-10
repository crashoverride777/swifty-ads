
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

/*
    Abstract:
    A Singleton class to manage banner and interstitial adverts from iAd. This class is only included in the iOS version of the project.
*/

import iAd

/// Hide print statements for release
private struct Debug {
    static func print(object: Any) {
        #if DEBUG
            Swift.print("DEBUG", object) //, terminator: "")
        #endif
    }
}

/// Delegates
protocol IAdDelegate: class {
    func iAdPause()
    func iAdResume()
}

protocol IAdErrorDelegate: class {
    func iAdBannerFail()
    func iAdInterFail()
}

/// Ads singleton class
class IAd: NSObject {
    
    // MARK: - Static Properties
    
    /// Shared instance
    static let sharedInstance = IAd()
    
    // MARK: - Properties
    
    // Check time zone support
    var timeZoneSupport: Bool {
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
    
    /// Delegates
    weak var delegate: IAdDelegate?
    weak var errorDelegate: IAdErrorDelegate?
    
    /// Presenting view controller
    private var presentingViewController: UIViewController?
    
    /// Removed ads
    private var removedAds = false
    
    /// Ads
    private var bannerAdView: ADBannerView?
    private var interAd: ADInterstitialAd?
    private var interAdView = UIView()
    
    /// Inter ads close button (iAd and customAd)
    private var interAdCloseButton = UIButton(type: UIButtonType.System)
    
    // MARK: - Init
    private override init() {
        super.init()
        
        /// Preload first inter ad
        interAd = loadInterAd()
    }
    
    /// SetUp
    func setUp(viewController viewController: UIViewController) {
        presentingViewController = viewController
    }
    
    /// Show banner ads
    func showBannerWithDelay(delay: NSTimeInterval) {
        guard !removedAds else { return }
        NSTimer.scheduledTimerWithTimeInterval(delay, target: self, selector: #selector(showBanner), userInfo: nil, repeats: false)
    }
    
    func showBanner() {
        guard !removedAds else { return }
        //presentingViewController.canDisplayBannerAds = true // // uncomment line to resize view for banner ads. Delegates will not work
        loadBannerAd() // comment out if above line is used, no need to manually create banner ads with canDisplayBannerAds = true
    }
    
    /// Show inter ads
    func showInterRandomly(randomness randomness: UInt32) {
        guard !removedAds else { return }
        
        let randomInterAd = Int(arc4random_uniform(randomness)) // get a random number between 0 and 2, so 33%
        guard randomInterAd == 0 else { return }
        showInter()
    }
    
    func showInter() {
        guard !removedAds else { return }
        showInterAd()
    }
    
    /// Remove banner ads
    func removeBanner() {
        bannerAdView?.delegate = nil
        bannerAdView?.removeFromSuperview()
        presentingViewController?.canDisplayBannerAds = false
        
        guard let view = presentingViewController?.view else { return }
        
        for subview in view.subviews {
            if let iAdBanner = subview as? ADBannerView {
                iAdBanner.delegate = nil
                iAdBanner.removeFromSuperview()
            }
        }
    }
    
    /// Remove all ads (IAPs)
    func removeAll() {
        Debug.print("Removed all ads")
        removedAds = true
        removeBanner()
        interAd?.delegate = nil
        interAdView.removeFromSuperview()
    }
    
    /// Orientation changed
    func orientationChanged() {
        guard let presentingViewController = presentingViewController else { return }
        Debug.print("Adjusting ads for new device orientation")
        
        bannerAdView?.frame = presentingViewController.view.bounds
        bannerAdView?.sizeThatFits(presentingViewController.view.frame.size)
        bannerAdView?.center = CGPoint(x: CGRectGetMidX(presentingViewController.view.frame), y: CGRectGetMaxY(presentingViewController.view.frame) - (bannerAdView!.frame.size.height / 2))
        
        interAdView.frame = presentingViewController.view.bounds
    }
}

// MARK: - Private Methods
private extension IAd {
    
    /// iAd load banner
    func loadBannerAd() {
        guard let presentingViewController = presentingViewController else { return }
        Debug.print("iAd banner loading...")
        bannerAdView = ADBannerView(adType: .Banner)
        bannerAdView?.frame = presentingViewController.view.bounds
        bannerAdView?.sizeThatFits(presentingViewController.view.frame.size)
        bannerAdView?.center = CGPoint(x: CGRectGetMidX(presentingViewController.view.frame), y: CGRectGetMaxY(presentingViewController.view.frame) + (bannerAdView!.frame.size.height / 2))
        bannerAdView?.delegate = self
    }
    
    /// iAd load inter
    func loadInterAd() -> ADInterstitialAd {
        Debug.print("iAds inter loading...")
        
        let iAdInterAd = ADInterstitialAd()
        iAdInterAd.delegate = self
        
        prepareInterAdCloseButton()
        
        return iAdInterAd
    }
    
    /// iAd show inter
    func showInterAd() {
        guard let presentingViewController = presentingViewController else { return }
        guard interAd != nil && interAd!.loaded else {
            Debug.print("iAds inter is not ready, reloading and trying AdMob")
            interAd = loadInterAd()
            
            errorDelegate?.iAdInterFail()
            return
        }
        
        Debug.print("iAds inter showing")
        interAdView.frame = presentingViewController.view.bounds
        presentingViewController.view?.window?.rootViewController?.view.addSubview(interAdView)
        interAd?.presentInView(interAdView)
        UIViewController.prepareInterstitialAds()
        interAdView.addSubview(interAdCloseButton)
    }
}

// MARK: - Banner Delegates
extension IAd: ADBannerViewDelegate {
    
    func bannerViewWillLoadAd(banner: ADBannerView!) {
        Debug.print("iAds banner will load")
    }
    
    func bannerViewDidLoadAd(banner: ADBannerView!) {
        guard let presentingViewController = presentingViewController else { return }
        Debug.print("iAds banner did load, showing")
        presentingViewController.view?.window?.rootViewController?.view.addSubview(banner)
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(1.5)
        banner.center = CGPoint(x: CGRectGetMidX(presentingViewController.view.frame), y: CGRectGetMaxY(presentingViewController.view.frame) - (banner.frame.size.height / 2))
        UIView.commitAnimations()
    }
    
    func bannerViewActionShouldBegin(banner: ADBannerView!, willLeaveApplication willLeave: Bool) -> Bool {
        Debug.print("iAds banner clicked")
        delegate?.iAdPause()
        return true
    }
    
    func bannerViewActionDidFinish(banner: ADBannerView!) {
        Debug.print("iAds banner closed")
        delegate?.iAdResume()
        
        /// Adjust for ipads incase orientation was portrait. iAd banners on ipads are shown in landscape and they get messed up after closing
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            banner.hidden = true
            let delay: NSTimeInterval = 1 // use delay it wont work
            NSTimer.scheduledTimerWithTimeInterval(delay, target: self, selector: #selector(orientationChanged), userInfo: nil, repeats: false)
            NSTimer.scheduledTimerWithTimeInterval(delay, target: self, selector: #selector(showBannerAgain), userInfo: nil, repeats: false)
        }
    }
    func showBannerAgain() {
        bannerAdView?.hidden = false
    }
    
    func bannerView(banner: ADBannerView!, didFailToReceiveAdWithError error: NSError!) {
        Debug.print(error.localizedDescription)
        guard let presentingViewController = presentingViewController else { return }
        
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(1.5)
        banner.hidden = true
        banner.center = CGPoint(x: CGRectGetMidX(presentingViewController.view.frame), y: CGRectGetMaxY(presentingViewController.view.frame) + (banner.frame.size.height / 2))
        banner.delegate = nil
        banner.removeFromSuperview()
        
        errorDelegate?.iAdBannerFail()
        
        UIView.commitAnimations()
    }
}

// MARK: - Inter Delegates
extension IAd: ADInterstitialAdDelegate {
    
    func interstitialAdDidLoad(interstitialAd: ADInterstitialAd!) {
        Debug.print("iAds inter did load")
    }
    
    func interstitialAdDidUnload(interstitialAd: ADInterstitialAd!) {
        Debug.print("iAds inter did unload")
    }
    
    func interstitialAd(interstitialAd: ADInterstitialAd!, didFailWithError error: NSError!) {
        Debug.print(error.localizedDescription)
        interAdView.removeFromSuperview()
        //iAdInterAd = iAdLoadInterAd() // can cause issues when no internet, gets stuck in loop
    }
}

// MARK: - Close Button
extension IAd {
    
    private func prepareInterAdCloseButton() {
        
        let maxLength = max(UIScreen.mainScreen().bounds.size.width, UIScreen.mainScreen().bounds.size.height)
        let iPad      = UIDevice.currentDevice().userInterfaceIdiom == .Pad && maxLength == 1024.0
        let iPadPro   = UIDevice.currentDevice().userInterfaceIdiom == .Pad && maxLength == 1366.0
        
        if iPadPro {
            interAdCloseButton.frame = CGRect(x: 28, y: 28, width: 37, height: 37)
            interAdCloseButton.layer.cornerRadius = 18
        } else if iPad {
            interAdCloseButton.frame = CGRect(x: 19, y: 19, width: 28, height: 28)
            interAdCloseButton.layer.cornerRadius = 14
        } else {
            interAdCloseButton.frame = CGRect(x: 12, y: 12, width: 21, height: 21)
            interAdCloseButton.layer.cornerRadius = 11
        }
        
        interAdCloseButton.setTitle("X", forState: .Normal)
        interAdCloseButton.setTitleColor(UIColor.grayColor(), forState: .Normal)
        interAdCloseButton.backgroundColor = UIColor.whiteColor()
        interAdCloseButton.layer.borderColor = UIColor.grayColor().CGColor
        interAdCloseButton.layer.borderWidth = 2
        interAdCloseButton.addTarget(self, action: #selector(pressedInterAdCloseButton(_:)), forControlEvents: UIControlEvents.TouchDown)
    }
    
    func pressedInterAdCloseButton(sender: UIButton) {
        Debug.print("Inter ad closed")
        interAdView.removeFromSuperview()
        interAd = loadInterAd()
    }
}