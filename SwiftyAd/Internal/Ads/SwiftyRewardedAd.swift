//
//  SwiftyRewardedAd.swift
//  SwiftyAd
//
//  Created by Dominik Ringler on 21/02/2020.
//  Copyright © 2020 Dominik. All rights reserved.
//

import GoogleMobileAds
#warning("use closures?")
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
    
    private let adUnitId: String
    private let request: () -> GADRequest
    private unowned let delegate: SwiftyRewardedAdDelegate
    
    private var rewardBasedVideoAd: GADRewardBasedVideoAd?
    
    // MARK: - Init
    
    init(adUnitId: String,
         request: @escaping () -> GADRequest,
         delegate: SwiftyRewardedAdDelegate) {
        self.adUnitId = adUnitId
        self.request = request
        self.delegate = delegate
    }
}

// MARK: - SwiftyRewardedAdType

extension SwiftyRewardedAd: SwiftyRewardedAdType {
    
    var isReady: Bool {
        guard rewardBasedVideoAd?.isReady == true else {
            print("AdMob reward video is not ready, reloading...")
            load()
            return false
        }
        return true
    }
    
    func load() {
        rewardBasedVideoAd = .sharedInstance()
        rewardBasedVideoAd?.delegate = self
        rewardBasedVideoAd?.load(request(), withAdUnitID: adUnitId)
    }
 
    func show(from viewController: UIViewController) {
        if isReady {
            rewardBasedVideoAd?.present(fromRootViewController: viewController)
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
    
    func rewardBasedVideoAdDidReceive(_ rewardBasedVideoAd: GADRewardBasedVideoAd) {
        print("AdMob reward based video did receive ad from: \(rewardBasedVideoAd.adNetworkClassName ?? "")")
    }
    
    func rewardBasedVideoAdDidStartPlaying(_ rewardBasedVideoAd: GADRewardBasedVideoAd) {
        delegate.swiftyRewardedAdDidOpen(self)
    }
    
    func rewardBasedVideoAdDidOpen(_ rewardBasedVideoAd: GADRewardBasedVideoAd) {
    }
    
    func rewardBasedVideoAdWillLeaveApplication(_ rewardBasedVideoAd: GADRewardBasedVideoAd) {
        delegate.swiftyRewardedAdDidOpen(self)
    }
    
    func rewardBasedVideoAdDidClose(_ rewardBasedVideoAd: GADRewardBasedVideoAd) {
        delegate.swiftyRewardedAdDidClose(self)
        load()
    }
    
    func rewardBasedVideoAdDidCompletePlaying(_ rewardBasedVideoAd: GADRewardBasedVideoAd) {
        
    }
    
    func rewardBasedVideoAd(_ rewardBasedVideoAd: GADRewardBasedVideoAd, didFailToLoadWithError error: Error) {
        print(error.localizedDescription)
        // Do not reload here as it might cause endless loading loops if no/slow internet
    }
    
    func rewardBasedVideoAd(_ rewardBasedVideoAd: GADRewardBasedVideoAd, didRewardUserWith reward: GADAdReward) {
        print("AdMob reward based video ad did reward user with \(reward)")
        let rewardAmount = Int(truncating: reward.amount)
        delegate.swiftyRewardedAd(self, didRewardUserWithAmount: rewardAmount)
    }
}
