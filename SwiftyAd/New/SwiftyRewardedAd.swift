//
//  SwiftyRewardedAd.swift
//  SwiftyAd
//
//  Created by Dominik Ringler on 21/02/2020.
//  Copyright © 2020 Dominik. All rights reserved.
//

import GoogleMobileAds

protocol SwiftyRewardedAdDelegate: AnyObject {
    func swiftyRewardedAdDidOpen(_ bannerAd: SwiftyRewardedAd)
    func swiftyRewardedAdDidClose(_ bannerAd: SwiftyRewardedAd)
    func swiftyRewardedAd(_ swiftyAd: SwiftyRewardedAd, didRewardUserWithAmount rewardAmount: Int)
}

protocol SwiftyRewardedAdType: AnyObject {
    var isReady: Bool { get }
    func load()
    func show(from viewController: UIViewController)
}

final class SwiftyRewardedAd: NSObject {
    
    // MARK: - Properties
    
    private let configuration: AdConfiguration
    private let requestBuilder: GADRequestBuilderType
    private unowned let delegate: SwiftyRewardedAdDelegate
    private let hasConsent: () -> Bool
    
    private var rewardedVideoAd: GADRewardBasedVideoAd?
    
    // MARK: - Init
    
    init(configuration: AdConfiguration,
         requestBuilder: GADRequestBuilderType,
         delegate: SwiftyRewardedAdDelegate,
         hasConsent: @escaping () -> Bool) {
        self.configuration = configuration
        self.requestBuilder = requestBuilder
        self.delegate = delegate
        self.hasConsent = hasConsent
    }
}

// MARK: - SwiftyRewardedAdType

extension SwiftyRewardedAd: SwiftyRewardedAdType {
    
    /// Check if reward video is ready (e.g to hide a reward video button)
    /// Will try to reload an ad if it returns false.
    public var isReady: Bool {
        guard rewardedVideoAd?.isReady == true else {
            print("AdMob reward video is not ready, reloading...")
            load()
            return false
        }
        return true
    }
    
    /// Preload ad
    func load() {
        guard hasConsent() else { return }
        
        rewardedVideoAd = GADRewardBasedVideoAd.sharedInstance()
        rewardedVideoAd?.delegate = self
        let request = requestBuilder.build()
        rewardedVideoAd?.load(request, withAdUnitID: configuration.rewardedVideoAdUnitId)
    }
    
    /// Show rewarded video ad
    ///
    /// - parameter viewController: The view controller that will present the ad.
    public func show(from viewController: UIViewController) {
        guard hasConsent() else { return }
        if isReady {
            rewardedVideoAd?.present(fromRootViewController: viewController)
        } else {
            let alertController = UIAlertController(
                title: LocalizedString.sorry,
                message: LocalizedString.noVideo,
                preferredStyle: .alert
            )
            alertController.addAction(UIAlertAction(title: LocalizedString.ok, style: .cancel))
            viewController.present(alertController, animated: true)
        }
    }
}

// MARK: - GADRewardBasedVideoAdDelegate

extension SwiftyRewardedAd: GADRewardBasedVideoAdDelegate {
    
    public func rewardBasedVideoAdDidReceive(_ rewardBasedVideoAd: GADRewardBasedVideoAd) {
        print("AdMob reward based video did receive ad from: \(rewardBasedVideoAd.adNetworkClassName ?? "")")
    }
    
    public func rewardBasedVideoAdDidStartPlaying(_ rewardBasedVideoAd: GADRewardBasedVideoAd) {
        delegate.swiftyRewardedAdDidOpen(self)
    }
    
    public func rewardBasedVideoAdDidOpen(_ rewardBasedVideoAd: GADRewardBasedVideoAd) {
    }
    
    public func rewardBasedVideoAdWillLeaveApplication(_ rewardBasedVideoAd: GADRewardBasedVideoAd) {
        delegate.swiftyRewardedAdDidOpen(self)
    }
    
    public func rewardBasedVideoAdDidClose(_ rewardBasedVideoAd: GADRewardBasedVideoAd) {
        delegate.swiftyRewardedAdDidClose(self)
        load()
    }
    
    public func rewardBasedVideoAdDidCompletePlaying(_ rewardBasedVideoAd: GADRewardBasedVideoAd) {
        
    }
    
    public func rewardBasedVideoAd(_ rewardBasedVideoAd: GADRewardBasedVideoAd, didFailToLoadWithError error: Error) {
        print(error.localizedDescription)
        // Do not reload here as it might cause endless loading loops if no/slow internet
    }
    
    public func rewardBasedVideoAd(_ rewardBasedVideoAd: GADRewardBasedVideoAd, didRewardUserWith reward: GADAdReward) {
        print("AdMob reward based video ad did reward user with \(reward)")
        let rewardAmount = Int(truncating: reward.amount)
        delegate.swiftyRewardedAd(self, didRewardUserWithAmount: rewardAmount)
    }
}
