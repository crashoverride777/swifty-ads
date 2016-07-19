
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

//    v5.2.2

/*
    Abstract:
    A Singleton class to manage adverts from AdMob as well as your own custom ads.
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
    
    /// Reward video check
    var rewardVideoIsReady: Bool {
        #if os(iOS)
            return AdMob.sharedInstance.rewardVideoIsReady
        #endif
        #if os(tvOS)
            return AppLovinReward.sharedInstance.isReady
        #endif
    }
    
    /// Our games counter
    private var customAdInterval = 0
    private var customAdCounter = 0 {
        didSet {
            if customAdCounter == customAdInterval {
                customAdCounter = 0
            }
        }
    }
    private var customAdShownCounter = 0
    private var customAdMaxPerSession = 0
    
    /// Interval counter
    private var intervalCounter = 0
    
    // MARK: - Init
    private override init() {
        super.init()
        
        CustomAd.sharedInstance.delegate = self
        
        #if os(iOS)
            AdMob.sharedInstance.delegate = self
        #endif
        
        #if os(tvOS)
            AppLovinInter.sharedInstance.delegate = self
            AppLovinReward.sharedInstance.delegate = self
        #endif
    }
    
    // MARK: - Set Up
    
    /// Set up ads helpers
    func setup(viewController viewController: UIViewController, customAdsInterval: Int, maxCustomAdsPerSession: Int) {
        self.customAdInterval = customAdsInterval
        self.customAdMaxPerSession = maxCustomAdsPerSession
    }
    
    // MARK: - Show Interstitial Ads
    
    /// Show interstitial ad
    func showInterstitial(withInterval interval: Int = 0) {
        
        if interval != 0 {
            intervalCounter += 1
            guard intervalCounter == interval else { return }
            intervalCounter = 0
        }
        
        guard customAdShownCounter < customAdMaxPerSession else {
            showRealInterstitialAd()
            return
        }
        
        switch customAdCounter {
            
        case 0, customAdInterval:
            customAdShownCounter += 1
            CustomAd.sharedInstance.show()
            
        default:
            showRealInterstitialAd()
        }
        
        customAdCounter += 1
    }
    
    /// Show real interstitial ad
    private func showRealInterstitialAd() {
        #if os(iOS)
            AdMob.sharedInstance.showInterstitial()
        #endif
        #if os(tvOS)
            AppLovinInter.sharedInstance.show()
        #endif
    }
    
    // MARK: - Show Reward Video
    
    /// Show reward video ad
    func showRewardVideo(withInterval interval: Int = 0) {
        
        if interval != 0 {
            intervalCounter += 1
            guard intervalCounter == interval else { return }
            intervalCounter = 0
        }
        
        #if os(iOS)
            AdMob.sharedInstance.showRewardVideo()
        #endif
        
        #if os(tvOS)
            AppLovinReward.sharedInstance.show()
        #endif
    }
    
    // MARK: - Remove
    
    /// Remove all
    func removeAll() {
        
        CustomAd.sharedInstance.remove()
        
        #if os(iOS)
            AdMob.sharedInstance.removeAll()
        #endif
        
        #if os(tvOS)
            AppLovinInter.sharedInstance.remove()
            AppLovinReward.sharedInstance.remove()
        #endif
    }
    
    // MARK: - Orientation Changed
    
    /// Orientation changed
    func orientationChanged() {
        
        CustomAd.sharedInstance.orientationChanged()
        
        #if os(iOS)
            AdMob.sharedInstance.orientationChanged()
        #endif
    }
}

// MARK: -  Delegates
extension AdsManager: CustomAdDelegate {
    
    /// Custom ads
    func customAdClicked() {
        delegate?.adClicked()
    }
    
    func customAdClosed() {
        delegate?.adClosed()
    }
}

#if os(iOS)
    extension AdsManager: AdMobDelegate {
        
        func adMobAdClicked() {
            delegate?.adClicked()
        }
        
        func adMobAdClosed() {
            delegate?.adClosed()
        }
        
        func adMobAdDidRewardUser(rewardAmount rewardAmount: Int) {
            delegate?.adDidRewardUser(rewardAmount: rewardAmount)
        }
    }
#endif

#if os(tvOS)
    extension AdsManager: AppLovinDelegate {
        
        func appLovinAdClicked() {
            delegate?.adClicked()
        }
        
        func appLovinAdClosed() {
            delegate?.adClosed()
        }
        
        func appLovinAdDidRewardUser(rewardAmount rewardAmount: Int) {
            delegate?.adDidRewardUser(rewardAmount: rewardAmount)
        }
    }
#endif