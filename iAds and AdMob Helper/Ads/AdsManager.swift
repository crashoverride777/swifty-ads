
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

//    v5.0

/*
    Abstract:
    A Singleton class to manage adverts from AdMob as well as your own custom ads. This class is only included in the iOS version of the project.
*/

import UIKit

/// Delegate
protocol AdsDelegate: class {
    func adClicked()
    func adClosed()
    func adDidRewardUser(rewardAmount rewardAmount: Int)
}

/// Ads manager class
class AdsManager: NSObject {
    
    // MARK: - Static Properties
    
    static let sharedInstance = AdsManager()
    
    // MARK: - Properties
    
    /// Delegate
    weak var delegate: AdsDelegate?
    
    /// Ads helpers
    private let adMob = AdMob.sharedInstance
    private let customAd = CustomAd.sharedInstance
    
    // MARK: - Init
    private override init() {
        super.init()
        
        // Delegates
        adMob.delegate = self
        customAd.delegate = self
    }
    
    // MARK: - Set Up
    
    /// Set up ads helpers
    func setUp(viewController viewController: UIViewController, customAdsInterval: Int) {
        adMob.setUp(viewController: viewController)
        customAd.setUp(viewController: viewController, interval: customAdsInterval)
    }
    
    // MARK: - Show Banner
    
    /// Show banner ad with delay
    func showBannerWithDelay(delay: NSTimeInterval) {
        NSTimer.scheduledTimerWithTimeInterval(delay, target: self, selector: #selector(showBanner), userInfo: nil, repeats: false)
    }
    
    /// Show banner ad
    func showBanner() {
        adMob.showBanner()
    }
    
    // MARK: - Show Interstitial Ads
    
    /// Show inter ad randomly
    func showInterstitialRandomly(randomness randomness: UInt32) {
        guard Int(arc4random_uniform(randomness)) == 0 else { return }
        showInterstitial()
    }
    
    /// Show inter ad
    func showInterstitial() {
        
        guard !customAd.isFinishedForSession else {
            adMob.showInterstitial()
            return
        }
        
        switch customAd.intervalCounter {
            
        case 0, customAd.interval:
            customAd.show()
            
        default:
            adMob.showInterstitial()
        }
        
        customAd.intervalCounter += 1
    }
    
    // MARK: - Show Reward Video
    
    /// Show reward video ad randomly
    func showRewardVideoRandomly(randomness randomness: UInt32) {
        guard Int(arc4random_uniform(randomness)) == 0 else { return }
        showRewardVideo()
    }
    
    /// Show reward video ad
    func showRewardVideo() {
        adMob.showRewardVideo()
    }
    
    // MARK: - Remove
    
    /// Remove banner
    func removeBanner() {
        adMob.removeBanner()
    }
    
    /// Remove all
    func removeAll() {
        adMob.removeAll()
        customAd.remove()
    }
    
    // MARK: - Orientation Changed
    
    /// Orientation changed
    func orientationChanged() {
        adMob.orientationChanged()
        customAd.orientationChanged()
    }
}

// MARK: - Delegates
extension AdsManager: AdMobDelegate, CustomAdDelegate {
    
    // AdMob
    func adMobAdClicked() {
        delegate?.adClicked()
    }
    
    func adMobAdClosed() {
        delegate?.adClosed()
    }
    
    func adMobDidRewardUser(rewardAmount rewardAmount: Int) {
        delegate?.adDidRewardUser(rewardAmount: rewardAmount)
    }
    
    /// Custom ads
    func customAdClicked() {
        delegate?.adClicked()
    }
    
    func customAdClosed() {
        delegate?.adClosed()
    }
}