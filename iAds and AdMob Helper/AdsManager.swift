
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
    
    /// Delegate
    weak var delegate: AdsDelegate?
    
    /// Custom ads controls
    private var customAdInterval = 0
    private var customAdIntervalCounter = 0
    
    /// iAds are supported
    private var iAdsAreSupported = false
    
    /// Ads helpers
    private let iAds = IAd.sharedInstance
    private let adMob = AdMob.sharedInstance
    private let customAd = CustomAd.sharedInstance
    
    // MARK: - Init
    private override init() {
        super.init()
        
        // Delegates
        iAds.delegate = self
        adMob.delegate = self
        customAd.delegate = self
        
        iAds.errorDelegate = self
        adMob.errorDelegate = self
        
        // Check if iAds are supported
        iAdsAreSupported = iAds.timeZoneSupport
    }
    
    /// SetUp
    func setUp(viewController viewController: UIViewController, customAdsCount: Int, customAdsInterval: Int) {
        iAds.setUp(viewController: viewController)
        adMob.setUp(viewController: viewController)
        customAd.setUp(viewController: viewController)
        
        customAd.totalCount = customAdsCount
        customAdInterval = customAdsInterval
    }
    
    /// Show banner ad with delay
    func showBannerWithDelay(delay: NSTimeInterval) {
        NSTimer.scheduledTimerWithTimeInterval(delay, target: self, selector: #selector(showBanner), userInfo: nil, repeats: false)
    }
    
    /// Show banner ad
    func showBanner() {
        if iAdsAreSupported {
            iAds.showBanner()
        } else {
            adMob.showBanner()
        }
    }
    
    /// Show inter ad randomly
    func showInterRandomly(randomness randomness: UInt32) {
        let randomInterAd = Int(arc4random_uniform(randomness)) // get a random number between 0 and 2, so 33%
        guard randomInterAd == 0 else { return }
        showInter()
    }
    
    /// Show inter
    func showInter() {
        
        // Check if custom ads are included
        guard customAd.totalCount > 0 else {
            if iAdsAreSupported {
                iAds.showInter()
            } else {
                adMob.showInter()
            }
            return
        }
        
        // Check custom ads
        switch customAdIntervalCounter {
            
        case 0:
            customAd.showInter()
            
        case customAdInterval:
            customAdIntervalCounter = 0
            customAd.showInter()
            
        default:
            if iAdsAreSupported {
                iAds.showInter()
            } else {
                adMob.showInter()
            }
        }
        
        // Increase custom ad interval
        customAdIntervalCounter += 1
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
        customAd.removeAll()
    }
    
    /// Orientation changed
    func orientationChanged() {
        iAds.orientationChanged()
        adMob.orientationChanged()
        customAd.orientationChanged()
    }
}

// MARK: - Action Delegates
extension AdsManager: IAdDelegate, AdMobDelegate, CustomAdDelegate {
 
    // iAds
    func iAdPause() {
        delegate?.pauseTasks()
    }
    func iAdResume() {
        delegate?.resumeTasks()
    }
    
    // AdMob
    func adMobPause() {
        delegate?.pauseTasks()
    }
    func adMobResume() {
        delegate?.resumeTasks()
    }
    
    /// Custom ads
    func customAdPause() {
        delegate?.pauseTasks()
    }
    func customAdResume() {
        delegate?.resumeTasks()
    }
}

// MARK: - Error Delegates
extension AdsManager: IAdErrorDelegate, AdMobErrorDelegate {
    
    /// iAds
    func iAdBannerFail() {
        adMob.showBanner()
    }
    
    func iAdInterFail() {
        adMob.showInter()
    }
    
    /// AdMob
    func adMobBannerFail() {
        guard iAdsAreSupported else { return }
        adMob.removeBanner()
        iAds.showBanner()
    }
    
    func adMobInterFail() { }
}