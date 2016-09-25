
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
 App lovin
 
 Singleton class to manage adverts from AppLovin. This class is only used in the tvOS version of the project.
 */
final class AppLovin: NSObject {
    
    // MARK: - Static Properties
    
    /// Shared instance
    static let shared = AppLovin()
    
    // MARK: - Properties
    
    /// Delegate
    weak var delegate: AdsDelegate?
    
    /// Check if reward video is ready (e.g to hide a reward video button)
    var isRewardedVideoReady: Bool {
        return ALIncentivizedInterstitialAd.isReadyForDisplay()
    }
    
    /// Is watching reward video
    fileprivate var isWatchingRewardedVideo = false
    
    /// Reward amount
    /// This will be updated once a reward video started playing
    fileprivate var rewardAmount = 1
    
    /// Interval counter
    private var intervalCounter = 0
    
    /// Removed ads
    private var removedAds = false
    
    // MARK: - Init
    
    /// Private singleton init
    private override init() {
        super.init()
        
        // Load SDK
        ALSdk.initializeSdk()
        
        // Preload reward video first time
        ALIncentivizedInterstitialAd.shared().preloadAndNotify(self)
    }
    
    /// Show interstitial ad
    ///
    /// - parameter interval: The interval of when to show the ad, e.g every 4th time. Defaults to 0.
    func showInterstitial(withInterval interval: Int = 0) {
        guard !removedAds else { return }
        
        guard ALInterstitialAd.isReadyForDisplay() else {
            print("AppLovin interstitial ad not ready, reloading...")
            return
        }
        
        if interval != 0 {
            intervalCounter += 1
            guard intervalCounter >= interval else { return }
            intervalCounter = 0
        }
        
        isWatchingRewardedVideo = false
        
        ALInterstitialAd.shared().adLoadDelegate = self
        ALInterstitialAd.shared().adDisplayDelegate = self
        ALInterstitialAd.shared().adVideoPlaybackDelegate = self // This will only ever be used if you have video ads enabled.
        ALInterstitialAd.shared().show()
    }
    
    /// Show rewarded video ad
    ///
    /// - parameter interval: The interval of when to show the ad, e.g every 4th time. Defaults to 0.
    func showRewardedVideo(withInterval interval: Int = 0) {
        //guard !removedAds else { return }
        
        guard ALIncentivizedInterstitialAd.isReadyForDisplay() else {
            print("AppLovin reward video not ready, reloading...")
            ALIncentivizedInterstitialAd.shared().preloadAndNotify(self)
            return
        }
        
        if interval != 0 {
            intervalCounter += 1
            guard intervalCounter >= interval else { return }
            intervalCounter = 0
        }
        
        isWatchingRewardedVideo = true
        
        ALIncentivizedInterstitialAd.shared().adDisplayDelegate = self
        ALIncentivizedInterstitialAd.shared().adVideoPlaybackDelegate = self
        ALIncentivizedInterstitialAd.shared().showAndNotify(self) // Shared not used here in tvOS demo, check if different
    }
    
    /// Remove ads (in app purchases)
    func removeAll() {
        removedAds = true
    }
}

// MARK: ALAdLoadDelegate

extension AppLovin: ALAdLoadDelegate {
    
    func adService(_ adService: ALAdService, didLoad ad: ALAd) {
        print("AppLovin video did load ad")
    }
    
    func adService(_ adService: ALAdService, didFailToLoadAdWithError code: Int32) {
        print("AppLovin video did fail to load ad, error code: \(code)")
    }
}

// MARK: ALAdDisplayDelegate

extension AppLovin: ALAdDisplayDelegate {
    
    func ad(_ ad: ALAd, wasDisplayedIn view: UIView) {
        print("AppLovin video ad was displayed")
        delegate?.adClicked()
    }
    
    func ad(_ ad: ALAd, wasClickedIn view: UIView) {
        print("AppLovin video ad was clicked")
        delegate?.adClicked()
    }
    
    func ad(_ ad: ALAd, wasHiddenIn view: UIView) {
        print("AppLovin video ad was hidden")
        delegate?.adClosed()
        
        // Preload next rewarded video if watching rewarded video ad
        guard isWatchingRewardedVideo else { return }
        ALIncentivizedInterstitialAd.shared().preloadAndNotify(self)
    }
}

// MARK: ALAdVideoPlaybackDelegate

extension AppLovin: ALAdVideoPlaybackDelegate {
    
    func videoPlaybackBegan(in ad: ALAd) {
        print("AppLovin video playback began in ad \(ad)")
    }
    
    func videoPlaybackEnded(in ad: ALAd, atPlaybackPercent percentPlayed: NSNumber, fullyWatched wasFullyWatched: Bool) {
        print("AppLovin video playback ended in ad \(ad) at percentage \(percentPlayed)")
        
        guard wasFullyWatched else { return }
        print("AppLovin video ad was fully watched")
        
        // Reward if ad was a rewarded video
        guard isWatchingRewardedVideo else { return }
        print("AppLovin video ad was rewarded video, rewarding...")
        delegate?.adDidRewardUser(withAmount: rewardAmount)
    }
}

// MARK: ALAdRewardDelegate

extension AppLovin: ALAdRewardDelegate {
    
    func rewardValidationRequest(for ad: ALAd, didSucceedWithResponse response: [AnyHashable: Any]) {
        print("AppLovin reward video did succeed with response \(response)")
        
        /* AppLovin servers validated the reward. Refresh user balance from your server.  We will also pass the number of coins
         awarded and the name of the currency.  However, ideally, you should verify this with your server before granting it. */
        
        // i.e. - "Coins", "Gold", whatever you set in the dashboard.
        let currencyName = response["currency"]
        
        // For example, "5" or "5.00" if you've specified an amount in the UI.
        let amountGivenString = response["amount"]
        guard let amount = amountGivenString as? NSString else {
            rewardAmount = 1
            return
        }
        
        let amountGiven = amount.floatValue
        
        // Do something with this information.
        // MYCurrencyManagerClass.updateUserCurrency(currencyName withChange: amountGiven)
        print("Rewarded \(amountGiven) \(currencyName)")
        
        // By default we'll show a UIAlertView informing your user of the currency & amount earned.
        // If you don't want this, you can turn it off in the Manage Apps UI.
        
        // Save reward amount as INT. If amount is for some reason 0 or lower set to 1
        guard amountGiven > 0 else {
            rewardAmount = 1
            return
        }
        
        rewardAmount = Int(amountGiven)
    }
    
    func rewardValidationRequest(for ad: ALAd, didExceedQuotaWithResponse response: [AnyHashable: Any]) {
        print("AppLovin reward video did exceed quota with reponse \(response)")
        
        // Your user has already earned the max amount you allowed for the day at this point, so
        // don't give them any more money. By default we'll show them a UIAlertView explaining this,
        // though you can change that from the Manage Apps UI.
    }
    
    func rewardValidationRequest(for ad: ALAd, wasRejectedWithResponse response: [AnyHashable: Any]) {
        print("AppLovin reward video was rejected with response \(response)")
        
        // Your user couldn't be granted a reward for this view. This could happen if you've blacklisted
        // them, for example. Don't grant them any currency. By default we'll show them a UIAlertView explaining this,
        // though you can change that from the Manage Apps UI.
    }
    
    func rewardValidationRequest(for ad: ALAd, didFailWithError responseCode: Int) {
        print("AppLovin reward video did fail with error code \(responseCode)")
        
        switch responseCode {
            
        case Int(kALErrorCodeIncentivizedUserClosedVideo):
            break
            // Your user exited the video prematurely. It's up to you if you'd still like to grant
            // a reward in this case. Most developers choose not to. Note that this case can occur
            // after a reward was initially granted (since reward validation happens as soon as a
            // video is launched).
            
        case Int(kALErrorCodeIncentivizedValidationNetworkTimeout), Int(kALErrorCodeIncentivizedUnknownServerError):
            break
            // Some server issue happened here. Don't grant a reward. By default we'll show the user
            // a UIAlertView telling them to try again later, but you can change this in the
            // Manage Apps UI.
            
        case Int(kALErrorCodeIncentiviziedAdNotPreloaded):
            
            // Indicates that you called for a rewarded video before one was available.
            
            break
            
        default:
            break
        }
    }
    
    func userDeclined(toViewAd ad: ALAd) {
        print("AppLovin reward video user declined to view ad")
    }
}
