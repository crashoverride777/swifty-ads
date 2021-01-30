//
//  AdPresenter.swift
//  SwiftyAdsDemo
//
//  Created by Dominik Ringler on 19/10/2020.
//  Copyright © 2020 Dominik Ringler. All rights reserved.
//

import UIKit

// Convenience helper for this demo project to display ads
enum AdPresenter {
    
    static func showBanner(from viewController: UIViewController, swiftyAds: SwiftyAdsType) {
        swiftyAds.showBanner(
            from: viewController,
            atTop: false,
            isUsingSafeArea: true,
            animationDuration: 1.5,
            onOpen: ({
                print("SwiftyAds banner ad did open")
            }),
            onClose: ({
                print("SwiftyAds banner ad did close")
            }),
            onError: ({ error in
                print("SwiftyAds banner ad error \(error)")
            })
        )
    }
    
    static func showInterstitialAd(from viewController: UIViewController, swiftyAds: SwiftyAdsType) {
        swiftyAds.showInterstitial(
            from: viewController,
            withInterval: 2,
            onOpen: ({
                print("SwiftyAds interstitial ad did open")
            }),
            onClose: ({
                print("SwiftyAds interstitial ad did close")
            }),
            onError: ({ error in
                print("SwiftyAds interstitial ad error \(error)")
            })
        )
    }
    
    static func showRewardedAd(from viewController: UIViewController,
                               swiftyAds: SwiftyAdsType,
                               onReward: @escaping (Int) -> Void) {
        swiftyAds.showRewardedVideo(
            from: viewController,
            onOpen: ({
                print("SwiftyAds rewarded video ad did open")
            }),
            onClose: ({
                print("SwiftyAds rewarded video ad did close")
            }),
            onError: ({ error in
                print("SwiftyAds rewarded video ad error \(error)")
            }),
            onNotReady: ({
                let alertController = UIAlertController(
                    title: "Sorry",
                    message: "No video available to watch at the moment.",
                    preferredStyle: .alert
                )
                alertController.addAction(UIAlertAction(title: "Ok", style: .cancel))
                viewController.present(alertController, animated: true)
            }),
            onReward: ({ rewardAmount in
                print("SwiftyAds rewarded video ad did reward user with \(rewardAmount)")
                onReward(rewardAmount)
            })
        )
    }
}
