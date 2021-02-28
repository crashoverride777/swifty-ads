//
//  SwiftyAdsRewardedInterstitial.swift
//  SwiftyAds
//
//  Created by Dominik Ringler on 28/02/2021.
//  Copyright © 2021 Dominik. All rights reserved.
//

import GoogleMobileAds

protocol SwiftyAdsRewardedInterstitialType: AnyObject {
    var isReady: Bool { get }
    func load()
    func show(from viewController: UIViewController,
              onOpen: (() -> Void)?,
              onClose: (() -> Void)?,
              onError: ((Error) -> Void)?,
              onReward: @escaping (Int) -> Void)
}

final class SwiftyAdsRewardedInterstitial: NSObject {

    // MARK: - Properties

    private let environment: SwiftyAdsEnvironment
    private let adUnitId: String
    private let request: () -> GADRequest
    private var onOpen: (() -> Void)?
    private var onClose: (() -> Void)?
    private var onError: ((Error) -> Void)?

    private var rewardedInterstitialAd: GADRewardedInterstitialAd?

    // MARK: - Initialization

    init(environment: SwiftyAdsEnvironment, adUnitId: String, request: @escaping () -> GADRequest) {
        self.environment = environment
        self.adUnitId = adUnitId
        self.request = request
    }
}

// MARK: - SwiftyAdsRewardedInterstitialType

extension SwiftyAdsRewardedInterstitial: SwiftyAdsRewardedInterstitialType {

    var isReady: Bool {
        rewardedInterstitialAd != nil
    }

    func load() {
        GADRewardedInterstitialAd.load(withAdUnitID: adUnitId, request: request()) { [weak self] (ad, error) in
            guard let self = self else { return }

            if let error = error {
                self.onError?(error)
                return
            }

            self.rewardedInterstitialAd = ad
            self.rewardedInterstitialAd?.fullScreenContentDelegate = self

        }
    }

    func show(from viewController: UIViewController,
              onOpen: (() -> Void)?,
              onClose: (() -> Void)?,
              onError: ((Error) -> Void)?,
              onReward: @escaping (Int) -> Void) {
        self.onOpen = onOpen
        self.onClose = onClose
        self.onError = onError

        guard let rewardedInterstitialAd = rewardedInterstitialAd else {
            load()
            onError?(SwiftyAdsError.rewardedInterstitialAdNotLoaded)
            return
        }

        do {
            try rewardedInterstitialAd.canPresent(fromRootViewController: viewController)
            let rewardAmount = Int(truncating: rewardedInterstitialAd.adReward.amount)
            rewardedInterstitialAd.present(fromRootViewController: viewController, userDidEarnRewardHandler: {
                onReward(rewardAmount)
            })
        } catch {
            load()
            onError?(error)
            return
        }
    }
}

// MARK: - GADFullScreenContentDelegate

extension SwiftyAdsRewardedInterstitial: GADFullScreenContentDelegate {

    func adDidRecordImpression(_ ad: GADFullScreenPresentingAd) {
        if case .debug = environment {
            print("SwiftyAdsRewarded did record impression for ad: \(ad)")
        }
    }

    func adDidPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        onOpen?()
    }

    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        // Nil out reference
        rewardedInterstitialAd = nil
        // Send callback
        onClose?()
        // Load the next ad so its ready for displaying
        load()
    }

    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        onError?(error)
    }
}
