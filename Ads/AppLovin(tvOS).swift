
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

//    v5.3

/*
    Abstract:
    A Singleton class to manage adverts from AppLovin. This class is only included in the tvOS version of the project.
*/

import Foundation

/// Hide print statements for release
/// Dont forget to add the custom "-D DEBUG" flag in Targets -> BuildSettings -> SwiftCompiler-CustomFlags -> DEBUG) for your tvOS target)
func print(items: Any..., separator: String = " ", terminator: String = "\n") {
    #if DEBUG
        Swift.print(items[0], separator: separator, terminator: terminator)
    #endif
}

/// Delegate
protocol AppLovinDelegate: class {
    func appLovinAdClicked()
    func appLovinAdClosed()
    func appLovinAdDidRewardUser(rewardAmount rewardAmount: Int)
}

// MARK: - Interstitial

class AppLovinInter: NSObject {
    
    // MARK: - Static Properties
    
    static let sharedInstance = AppLovinInter()
    
    // MARK: - Properties
    
    /// Delegate
    weak var delegate: AppLovinDelegate?
    
    /// Interval counter
    private var intervalCounter = 0
    
    /// Removed ads
    private var removedAds = false
    
    // MARK: - Init
    
    private override init() {
        super.init()
        
        // Load SDK
        ALSdk.initializeSdk()
    }
    
    /// Show interstitial ad randomly
    func show(withInterval interval: Int = 0) {
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
        
        ALInterstitialAd.shared().adLoadDelegate = self
        ALInterstitialAd.shared().adDisplayDelegate = self
        ALInterstitialAd.shared().adVideoPlaybackDelegate = self // This will only ever be used if you have video ads enabled.
        ALInterstitialAd.shared().show()
    }
    
    /// Remove
    func remove() {
        removedAds = true
    }
}

/// Loading Delegates

extension AppLovinInter: ALAdLoadDelegate {
    
    func adService(adService: ALAdService, didLoadAd ad: ALAd) {
        print("AppLovin interstitial did load ad")
    }
    
    func adService(adService: ALAdService, didFailToLoadAdWithError code: Int32) {
        print("AppLovin interstitial did fail to load ad, error code: \(code)")
    }
}

/// Display Delegates

extension AppLovinInter: ALAdDisplayDelegate {
    
    func ad(ad: ALAd, wasDisplayedIn view: UIView) {
        print("AppLovin interstitial ad was displayed")
        delegate?.appLovinAdClicked()
    }
    
    func ad(ad: ALAd, wasClickedIn view: UIView) {
        print("AppLovin interstitial ad was clicked")
        delegate?.appLovinAdClicked()
    }
    
    func ad(ad: ALAd, wasHiddenIn view: UIView) {
        print("AppLovin interstitial ad was hidden")
        delegate?.appLovinAdClosed()
    }
}

/// Video Playback Delegates

extension AppLovinInter: ALAdVideoPlaybackDelegate {
    
    func videoPlaybackBeganInAd(ad: ALAd) {
        print("AppLovin interstitial video playback began in ad \(ad)")
    }
    
    func videoPlaybackEndedInAd(ad: ALAd, atPlaybackPercent percentPlayed: NSNumber, fullyWatched wasFullyWatched: Bool) {
        print("AppLovin interstitial video playback ended in ad \(ad) at percentage \(percentPlayed)")
        
        guard wasFullyWatched else { return }
        print("AppLovin interstitial user declined to view ad")
    }
}

// MARK: - Reward Videos

class AppLovinReward: NSObject {
    
    // MARK: - Static Properties
    
    static let sharedInstance = AppLovinReward()
    
    // MARK: - Properties
    
    /// Delegate
    weak var delegate: AppLovinDelegate?
    
    /// Reward amount
    /// This will be updated once a reward video started playing
    private var rewardAmount = 1
    
    /// Interval counter
    private var intervalCounter = 0
    
    /// Removed ads
    private var removedAds = false
    
    /// Check if reward video is ready (e.g to hide a reward video button)
    var isReady: Bool {
        return ALIncentivizedInterstitialAd.isReadyForDisplay()
    }
    
    // MARK: - Init
    
    private override init() {
        super.init()
        
        // Load SDK
        // Uncomment this if you are only using this class and not regular inter ads as well
        //ALSdk.initializeSdk()
        
        // Preload first video
        preload()
    }
    
    /// Show randomly
    func show(withInterval interval: Int = 0) {
        guard !removedAds else { return }
        
        guard ALIncentivizedInterstitialAd.isReadyForDisplay() else {
            print("AppLovin reward video not ready, reloading...")
            preload()
            return
        }
        
        if interval != 0 {
            intervalCounter += 1
            guard intervalCounter >= interval else { return }
            intervalCounter = 0
        }
        
        ALIncentivizedInterstitialAd.shared().adDisplayDelegate = self
        ALIncentivizedInterstitialAd.shared().adVideoPlaybackDelegate = self
        ALIncentivizedInterstitialAd.shared().showAndNotify(self) // Shared not used here in tvOS demo, check if different
    }
    
    /// Remove
    func remove() {
        removedAds = true
    }
    
    /// Preload
    private func preload() {
        ALIncentivizedInterstitialAd.shared().preloadAndNotify(self)
    }
}

/// Loading Delegates

extension AppLovinReward: ALAdLoadDelegate {
    
    func adService(adService: ALAdService, didLoadAd ad: ALAd) {
        print("AppLovin reward video did load ad")
    }
    
    func adService(adService: ALAdService, didFailToLoadAdWithError code: Int32) {
        print("AppLovin reward video did fail to load ad, error code: \(code)")
    }
}

/// Display Delegates

extension AppLovinReward: ALAdDisplayDelegate {
    
    func ad(ad: ALAd, wasDisplayedIn view: UIView) {
        print("AppLovin reward video ad was displayed")
        delegate?.appLovinAdClicked()
    }
    
    func ad(ad: ALAd, wasClickedIn view: UIView) {
        print("AppLovin reward video ad was clicked")
        delegate?.appLovinAdClicked()
    }
    
    func ad(ad: ALAd, wasHiddenIn view: UIView) {
        print("AppLovin reward video ad was hidden")
        delegate?.appLovinAdClosed()
        
        preload()
    }
}

/// Video Playback Delegates

extension AppLovinReward: ALAdVideoPlaybackDelegate {
    
    func videoPlaybackBeganInAd(ad: ALAd) {
        print("AppLovin reward video playback began in ad \(ad)")
    }
    
    func videoPlaybackEndedInAd(ad: ALAd, atPlaybackPercent percentPlayed: NSNumber, fullyWatched wasFullyWatched: Bool) {
        print("AppLovin reward video playback ended in ad \(ad) at percentage \(percentPlayed)")
        
        guard wasFullyWatched else { return }
        print("AppLovin reward video was fully watched, rewarding...")
        
        delegate?.appLovinAdDidRewardUser(rewardAmount: rewardAmount)
    }
}

/// Reward Delegates

extension AppLovinReward: ALAdRewardDelegate {
    
    func rewardValidationRequestForAd(ad: ALAd, didSucceedWithResponse response: [NSObject : AnyObject]) {
        print("AppLovin reward video did succeed with response \(response)")
        
        /* AppLovin servers validated the reward. Refresh user balance from your server.  We will also pass the number of coins
         awarded and the name of the currency.  However, ideally, you should verify this with your server before granting it. */
        
        // i.e. - "Coins", "Gold", whatever you set in the dashboard.
        let currencyName = response["currency"]
        
        // For example, "5" or "5.00" if you've specified an amount in the UI.
        let amountGivenString = response["amount"]
        guard let amount = amountGivenString as? NSString else { return }
        
        let amountGiven = amount.floatValue
        
        
        // Do something with this information.
        // MYCurrencyManagerClass.updateUserCurrency(currencyName withChange: amountGiven)
        print("Rewarded \(amountGiven) \(currencyName)")
        
        // By default we'll show a UIAlertView informing your user of the currency & amount earned.
        // If you don't want this, you can turn it off in the Manage Apps UI.
        
        // Save reward amount as INT when not 0 and use when video full watched
        guard amountGiven != 0 else { return }
        rewardAmount = Int(amountGiven)
    }
    
    func rewardValidationRequestForAd(ad: ALAd, didExceedQuotaWithResponse response: [NSObject : AnyObject]) {
        print("AppLovin reward video did exceed quota with reponse \(response)")
        
        // Your user has already earned the max amount you allowed for the day at this point, so
        // don't give them any more money. By default we'll show them a UIAlertView explaining this,
        // though you can change that from the Manage Apps UI.
    }
    
    func rewardValidationRequestForAd(ad: ALAd, wasRejectedWithResponse response: [NSObject : AnyObject]) {
        print("AppLovin reward video was rejected with response \(response)")
        
        // Your user couldn't be granted a reward for this view. This could happen if you've blacklisted
        // them, for example. Don't grant them any currency. By default we'll show them a UIAlertView explaining this,
        // though you can change that from the Manage Apps UI.
    }
    
    func rewardValidationRequestForAd(ad: ALAd, didFailWithError responseCode: Int) {
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
    
    func userDeclinedToViewAd(ad: ALAd) {
        print("AppLovin reward video user declined to view ad")
    }
}