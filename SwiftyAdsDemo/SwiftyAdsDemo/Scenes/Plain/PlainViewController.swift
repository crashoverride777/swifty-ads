//
//  PlainViewController.swift
//  SwiftyAdsDemo
//
//  Created by Dominik Ringler on 19/10/2020.
//  Copyright © 2020 Dominik Ringler. All rights reserved.
//

import UIKit

final class PlainViewController: UIViewController {
    
    // MARK: - Properties
    
    private let swiftyAds: SwiftyAdsType = SwiftyAds.shared
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        AdPresenter.showBanner(from: self)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { _ in
            self.swiftyAds.updateBannerForOrientationChange(isLandscape: size.width > size.height)
        })
    }
}

// MARK: - Private

private extension PlainViewController {
    
    @IBAction func showInterstitialAdButtonPressed(_ sender: Any) {
        AdPresenter.showInterstitialAd(from: self)
    }
    
    @IBAction func showRewardedAdButtonPressed(_ sender: Any) {
        AdPresenter.showRewardedAd(from: self, onReward: { rewardAmount in
            // update coins, diamonds etc
        })
    }
    
    @IBAction func disableAdsButtonPressed(_ sender: Any) {
        swiftyAds.disable()
    }
    
    @IBAction func showConsentFormButtonPressed(_ sender: Any) {
        swiftyAds.askForConsent(from: self)
    }
}
