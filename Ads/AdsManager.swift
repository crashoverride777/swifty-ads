
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

//    v5.5

/*
    Abstract: 
    A Singleton class to manage adverts from AdMob, AppLovin and your own custom ads.
*/

import Foundation

final class AdsManager {
    
    // MARK: - Static Properties
    
    /// Shared instance
    static let shared = AdsManager()
    
    // MARK: - Properties
    
    /// Delegate
    weak var delegate: AdsDelegate? {
        didSet {
            CustomAd.shared.delegate = delegate
            #if os(iOS)
                AdMob.shared.delegate = delegate
            #endif
            #if os(tvOS)
                AppLovin.shared.delegate = delegate
            #endif
        }
    }
    
    /// Reward video check
    var rewardedVideoIsReady: Bool {
        #if os(iOS)
            return AdMob.shared.rewardedVideoIsReady
        #endif
        #if os(tvOS)
            return AppLovin.shared.rewardedVideoIsReady
        #endif
    }
    
    /// Our games counter
    fileprivate var customAdInterval = 0
    fileprivate var customAdCounter = 0 {
        didSet {
            if customAdCounter == customAdInterval {
                customAdCounter = 0
            }
        }
    }
    fileprivate var customAdShownCounter = 0
    fileprivate var customAdMaxPerSession = 0
    
    /// Interval counter
    fileprivate var intervalCounter = 0
    
    // MARK: - Init
    
    /// Init
    fileprivate init() {
    
    }
    
    // MARK: - Set Up
    
    /// Set up ads helpers
    ///
    /// - parameter customAdsInterval: The interval of how often to show a custom ad mixed in between real ads.
    /// - parameter maxCustomAdsPerSession: The max number of custom ads to show per session.
    func setup(customAdsInterval: Int, maxCustomAdsPerSession: Int) {
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
            CustomAd.shared.show()
        }
        else {
            #if os(iOS)
                AdMob.shared.showInterstitial()
            #endif
            #if os(tvOS)
                AppLovin.shared.showInterstitial()
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
            AdMob.shared.showRewardedVideo()
        #endif
        #if os(tvOS)
            AppLovin.shared.showRewardedVideo()
        #endif
    }
    
    // MARK: - Remove
    
    /// Remove banner
    func removeBanner() {
        #if os(iOS)
            AdMob.shared.removeBanner()
        #endif
    }
    
    /// Remove all
    func removeAll() {
        CustomAd.shared.remove()
        #if os(iOS)
            AdMob.shared.removeAll()
        #endif
        #if os(tvOS)
            AppLovin.shared.removeAll()
        #endif
    }
    
    // MARK: - Orientation Changed
    
    /// Orientation changed
    /// Call this when an orientation change (e.g landscape->portrait happended)
    func adjustForOrientation() {
        CustomAd.shared.adjustForOrientation()
        #if os(iOS)
            AdMob.shared.adjustForOrientation()
        #endif
    }
}
