
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

//    v5.5.2

import Foundation

/**
 Ads manager
 
 Singleton class to manage adverts from AdMob as well as your own custom ads.
 */
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
    var isRewardedVideoReady: Bool {
        #if os(iOS)
            return AdMob.shared.isRewardedVideoReady
        #endif
        #if os(tvOS)
            return AppLovin.shared.isRewardedVideoReady
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
    
    /// Private singleton nit
    private init() { }
    
    // MARK: - Set Up
    
    /// Setup ads helpers
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
    /// - parameter interval: The interval of when to show the ad. Defaults to 0.
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
    /// - parameter interval: The interval of when to show the ad. Defaults to 0.
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
    /// Call this when an orientation change happens (e.g landscape->portrait happended)
    func adjustForOrientation() {
        CustomAd.shared.adjustForOrientation()
        #if os(iOS)
            AdMob.shared.adjustForOrientation()
        #endif
    }
}
