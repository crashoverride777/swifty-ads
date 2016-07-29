
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

//    v5.3.2

/*
    Abstract:
    A Singleton class to manage adverts from AdMob as well as your own custom ads.
*/

import UIKit

class AdsManager: NSObject {
    
    // MARK: - Static Properties
    
    static let sharedInstance = AdsManager()
    
    // MARK: - Properties
    
    /// Delegate
    weak var delegate: AdsDelegate? {
        didSet {
            CustomAd.sharedInstance.delegate = delegate
            
            #if os(iOS)
                AdMob.sharedInstance.delegate = delegate
            #endif
            
            #if os(tvOS)
                AppLovinInter.sharedInstance.delegate = delegate
                AppLovinReward.sharedInstance.delegate = delegate
            #endif
        }
    }
    
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
        
    }
    
    // MARK: - Set Up
    
    /// Set up ads helpers
    func setup(customAdsInterval customAdsInterval: Int, maxCustomAdsPerSession: Int) {
        self.customAdInterval = customAdsInterval
        self.customAdMaxPerSession = maxCustomAdsPerSession
    }
    
    // MARK: - Show Interstitial Ads
    
    /// Show interstitial ad
    func showInterstitial(withInterval interval: Int = 0) {
        
        if interval != 0 {
            intervalCounter += 1
            guard intervalCounter >= interval else { return }
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
            guard intervalCounter >= interval else { return }
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
        
        CustomAd.sharedInstance.adjustForOrientation()
        
        #if os(iOS)
            AdMob.sharedInstance.orientationChanged()
        #endif
    }
}