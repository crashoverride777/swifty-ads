//
//  PlainViewController.swift
//  SwiftyAdsDemo
//
//  Created by Dominik Ringler on 19/10/2020.
//  Copyright © 2020 Dominik Ringler. All rights reserved.
//

import UIKit

final class PlainViewController: UIViewController {
    
    // MARK: - Outlets
    
    @IBOutlet private weak var consentFormButton: UIButton!
    
    // MARK: - Properties

    private var swiftyAds: SwiftyAdsType!
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .blue
        refresh()
        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: .adConsentStatusDidChange, object: nil)
        AdPresenter.showBanner(from: self, swiftyAds: swiftyAds)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { _ in
            self.swiftyAds.updateBannerForOrientationChange(isLandscape: size.width > size.height)
        })
    }

    // MARK: - Public Methods

    func configure(swiftyAds: SwiftyAdsType) {
        self.swiftyAds = swiftyAds
    }
}

// MARK: - Private Methods

private extension PlainViewController {
    
    @IBAction func showInterstitialAdButtonPressed(_ sender: Any) {
        AdPresenter.showInterstitialAd(from: self, swiftyAds: swiftyAds)
    }
    
    @IBAction func showRewardedAdButtonPressed(_ sender: Any) {
        AdPresenter.showRewardedAd(from: self, swiftyAds: swiftyAds, onReward: { rewardAmount in
            // update coins, diamonds etc
        })
    }
    
    @IBAction func disableAdsButtonPressed(_ sender: Any) {
        swiftyAds.disable()
    }
    
    @IBAction func showConsentFormButtonPressed(_ sender: Any) {
        swiftyAds.askForConsent(from: self)
    }
    
    @objc func refresh() {
        consentFormButton.isHidden = !swiftyAds.isRequiredToAskForConsent
    }
}
