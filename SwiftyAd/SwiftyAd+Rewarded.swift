//
//  SwiftyAd+Rewarded.swift
//  SwiftyAdExample
//
//  Created by Dominik Ringler on 23/05/2019.
//  Copyright © 2019 Dominik. All rights reserved.
//

import GoogleMobileAds

//// MARK: - Load Ads
//
//extension SwiftyAd {
//    
//    func loadRewardedVideoAd() {
//        guard hasConsent else { return }
//        
//        rewardedVideoAd = GADRewardBasedVideoAd.sharedInstance()
//        rewardedVideoAd?.delegate = self
//        let request = requestBuilder.build()
//        rewardedVideoAd?.load(request, withAdUnitID: configuration.rewardedVideoAdUnitId)
//    }
//}
//
//// MARK: - GADRewardBasedVideoAdDelegate
//
//extension SwiftyAd: GADRewardBasedVideoAdDelegate {
//    
//    public func rewardBasedVideoAdDidReceive(_ rewardBasedVideoAd: GADRewardBasedVideoAd) {
//        print("AdMob reward based video did receive ad from: \(rewardBasedVideoAd.adNetworkClassName ?? "")")
//    }
//    
//    public func rewardBasedVideoAdDidStartPlaying(_ rewardBasedVideoAd: GADRewardBasedVideoAd) {
//        delegate?.swiftyAdDidOpen(self)
//    }
//    
//    public func rewardBasedVideoAdDidOpen(_ rewardBasedVideoAd: GADRewardBasedVideoAd) {
//    }
//    
//    public func rewardBasedVideoAdWillLeaveApplication(_ rewardBasedVideoAd: GADRewardBasedVideoAd) {
//        delegate?.swiftyAdDidOpen(self)
//    }
//    
//    public func rewardBasedVideoAdDidClose(_ rewardBasedVideoAd: GADRewardBasedVideoAd) {
//        delegate?.swiftyAdDidClose(self)
//        loadRewardedVideoAd()
//    }
//    
//    public func rewardBasedVideoAdDidCompletePlaying(_ rewardBasedVideoAd: GADRewardBasedVideoAd) {
//        
//    }
//    
//    public func rewardBasedVideoAd(_ rewardBasedVideoAd: GADRewardBasedVideoAd, didFailToLoadWithError error: Error) {
//        print(error.localizedDescription)
//        // Do not reload here as it might cause endless loading loops if no/slow internet
//    }
//    
//    public func rewardBasedVideoAd(_ rewardBasedVideoAd: GADRewardBasedVideoAd, didRewardUserWith reward: GADAdReward) {
//        print("AdMob reward based video ad did reward user with \(reward)")
//        let rewardAmount = Int(truncating: reward.amount)
//        delegate?.swiftyAd(self, didRewardUserWithAmount: rewardAmount)
//    }
//}
