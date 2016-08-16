
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

//    v5.4

/*
    Abstract: 
    A Singleton class to manage adverts from AdMob, AppLovin and your own custom ads.
*/

import Foundation

final class AdsManager {
    
    // MARK: - Static Properties
    
    /// Shared instance
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
                AppLovin.sharedInstance.delegate = delegate
            #endif
        }
    }
    
    /// Reward video check
    var rewardedVideoIsReady: Bool {
        #if os(iOS)
            return AdMob.sharedInstance.rewardedVideoIsReady
        #endif
        #if os(tvOS)
            return AppLovin.sharedInstance.rewardedVideoIsReady
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
    
    /// Init
    private init() {
    
    }
    
    // MARK: - Set Up
    
    /// Set up ads helpers
    ///
    /// - parameter customAdsInterval: The interval of how often to show a custom ad mixed in between real ads.
    /// - parameter maxCustomAdsPerSession: The max number of custom ads to show per session.
    func setup(customAdsInterval customAdsInterval: Int, maxCustomAdsPerSession: Int) {
        self.customAdInterval = customAdsInterval
        self.customAdMaxPerSession = maxCustomAdsPerSession
    }
    
    // MARK: - Show Interstitial Ad
    
    /// Show inter ad
    ///
    /// - parameter withInterval: The interval of when to show the ad. Defaults to 0.
    func showInterstitial(withInterval interval: Int = 0) {
        
        if interval != 0 {
            intervalCounter += 1
            guard intervalCounter >= interval else { return }
            intervalCounter = 0
        }
        
        if (customAdCounter == 0 || customAdCounter == customAdInterval) && customAdShownCounter < customAdMaxPerSession {
            customAdShownCounter += 1
            CustomAd.sharedInstance.show()
        }
        else {
            #if os(iOS)
                AdMob.sharedInstance.showInterstitial()
            #endif
            #if os(tvOS)
                AppLovin.sharedInstance.showInterstitial()
            #endif
        }
        
        customAdCounter += 1
    }
    
    // MARK: - Show Reward Video
    
    /// Show rewarded video ad
    ///
    /// - parameter withInterval: The interval of when to show the ad. Defaults to 0.
    func showRewardedVideo(withInterval interval: Int = 0) {
        if interval != 0 {
            intervalCounter += 1
            guard intervalCounter >= interval else { return }
            intervalCounter = 0
        }
        
        #if os(iOS)
            AdMob.sharedInstance.showRewardedVideo()
        #endif
        #if os(tvOS)
            AppLovin.sharedInstance.showRewardedVideo()
        #endif
    }
    
    // MARK: - Remove
    
    /// Remove banner
    func removeBanner() {
        #if os(iOS)
            AdMob.sharedInstance.removeBanner()
        #endif
    }
    
    /// Remove all
    func removeAll() {
        CustomAd.sharedInstance.remove()
        #if os(iOS)
            AdMob.sharedInstance.removeAll()
        #endif
        #if os(tvOS)
            AppLovin.sharedInstance.removeAll()
        #endif
    }
    
    // MARK: - Orientation Changed
    
    /// Orientation changed
    /// Call this when an orientation change (e.g landscape->portrait happended)
    func adjustForOrientation() {
        CustomAd.sharedInstance.adjustForOrientation()
        #if os(iOS)
            AdMob.sharedInstance.adjustForOrientation()
        #endif
    }
}