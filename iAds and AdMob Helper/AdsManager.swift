
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
    A Singleton class to manage banner and interstitial adverts from iAd and AdMob as well as custom ads. This class is only included in the iOS version of the project.
*/

import UIKit

/// Hide print statements for release. Can be used for every print statement in your project
struct Debug {
    static func print(object: Any) {
        #if DEBUG
            Swift.print("DEBUG", object) //, terminator: "")
        #endif
    }
}

/// Device check
struct DeviceCheck {
    
    static let iPad      = UIDevice.currentDevice().userInterfaceIdiom == .Pad && maxLength == 1024.0
    static let iPadPro   = UIDevice.currentDevice().userInterfaceIdiom == .Pad && maxLength == 1366.0
    
    static let width     = UIScreen.mainScreen().bounds.size.width
    static let height    = UIScreen.mainScreen().bounds.size.height
    static let maxLength = max(width, height)
    static let minLength = min(width, height)
}

/// Delegates
protocol AdsDelegate: class {
    func pauseTasks()
    func resumeTasks()
}

/// Ads manager class
class AdsManager: NSObject {
    
    // MARK: - Static Properties
    
    static let sharedInstance = AdsManager()
    
    // MARK: - Properties
    
    /// iAds are supported
    private var iAdsAreSupported = false
    
    /// Ads helpers
    private let iAds = IAds.sharedInstance
    private let adMob = AdMob.sharedInstance
    private let customAds = CustomAds.sharedInstance
    
    // MARK: - Init
    private override init() {
        super.init()
        
        // Error delegates
        iAds.errorDelegate = self
        adMob.errorDelegate = self
        
        // Check if iAds are supported
        iAdsAreSupported = iAds.timeZoneSupport
    }
    
    /// SetUp
    func setUp(viewController viewController: UIViewController, customAdsCount: Int, customAdsInterval: Int) {
        iAds.presentingViewController = viewController
        adMob.presentingViewController = viewController
        customAds.presentingViewController = viewController
        
        customAds.count = customAdsCount
        customAds.interval = customAdsInterval
    }
    
    /// Show banner ads
    func showBannerWithDelay(delay: NSTimeInterval) {
        NSTimer.scheduledTimerWithTimeInterval(delay, target: self, selector: #selector(showBanner), userInfo: nil, repeats: false)
    }
    
    func showBanner() {
        if iAdsAreSupported {
            iAds.showBanner()
        } else {
            adMob.showBanner()
        }
    }
    
    /// Show inter ads
    func showInterRandomly(randomness randomness: UInt32) {
        let randomInterAd = Int(arc4random_uniform(randomness)) // get a random number between 0 and 2, so 33%
        guard randomInterAd == 0 else { return }
        showInterAd()
    }
    
    func showInterAd() {
        
        // Check if custom ads are included
        guard customAds.count > 0 else {
            showingInterAd()
            return
        }
        
        // Check custom ads
        switch customAds.intervalCounter {
            
        case 0:
            customAds.showInter()
            
        case customAds.interval:
            customAds.intervalCounter = 0
            customAds.showInter()
            
        default:
            showingInterAd()
        }
        
        // Increase custom ad interval
        customAds.intervalCounter += 1
    }
    
    /// Remove banner
    func removeBanner() {
        iAds.removeBanner()
        adMob.removeBanner()
    }
    
    /// Remove all
    func removeAll() {
        iAds.removeAll()
        adMob.removeAll()
        customAds.removeAll()
    }
    
    /// Orientation changed
    func orientationChanged() {
        iAds.orientationChanged()
        adMob.orientationChanged()
        customAds.orientationChanged()
    }
    
    /// Showing inter ad
    private func showingInterAd() {
        if iAdsAreSupported {
            iAds.showInter()
        } else {
            adMob.showInter()
        }
    }
}

// MARK: - iAd Error Delegates
extension AdsManager: IAdErrorDelegate {
    
    /// iAds
    func iAdBannerFail() {
        adMob.showBanner()
    }
    
    func iAdInterFail() {
        adMob.showInter()
    }
}

// MARK: - AdMob Error Delegates
extension AdsManager: AdMobErrorDelegate {
    
    func adMobBannerFail() {
        guard iAdsAreSupported else { return }
        adMob.removeBanner()
        iAds.showBanner()
    }
    
    func adMobInterFail() { }
}