//    The MIT License (MIT)
//
//    Copyright (c) 2015-2022 Dominik Ringler
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

import GoogleMobileAds

protocol SwiftyAdsRewardedType: AnyObject {
    var isReady: Bool { get }
    func load()
    func show(from viewController: UIViewController,
              onOpen: (() -> Void)?,
              onClose: (() -> Void)?,
              onError: ((Error) -> Void)?,
              onNotReady: (() -> Void)?,
              onReward: @escaping (NSDecimalNumber) -> Void)
}

final class SwiftyAdsRewarded: NSObject {

    // MARK: - Properties

    private let environment: SwiftyAdsEnvironment
    private let adUnitId: String
    private let request: () -> GADRequest
    
    private var onOpen: (() -> Void)?
    private var onClose: (() -> Void)?
    private var onError: ((Error) -> Void)?
    
    private var rewardedAd: GADRewardedAd?
    
    // MARK: - Initialization
    
    init(environment: SwiftyAdsEnvironment, adUnitId: String, request: @escaping () -> GADRequest) {
        self.environment = environment
        self.adUnitId = adUnitId
        self.request = request
    }
}

// MARK: - SwiftyAdsRewardedType

extension SwiftyAdsRewarded: SwiftyAdsRewardedType {
    var isReady: Bool {
        rewardedAd != nil
    }
    
    func load() {
        GADRewardedAd.load(withAdUnitID: adUnitId, request: request()) { [weak self] (ad, error) in
            guard let self = self else { return }

            if let error = error {
                self.onError?(error)
                return
            }

            self.rewardedAd = ad
            self.rewardedAd?.fullScreenContentDelegate = self
            
        }
    }
 
    func show(from viewController: UIViewController,
              onOpen: (() -> Void)?,
              onClose: (() -> Void)?,
              onError: ((Error) -> Void)?,
              onNotReady: (() -> Void)?,
              onReward: @escaping (NSDecimalNumber) -> Void) {
        self.onOpen = onOpen
        self.onClose = onClose
        self.onError = onError
        
        guard let rewardedAd = rewardedAd else {
            load()
            onError?(SwiftyAdsError.rewardedAdNotLoaded)
            onNotReady?()
            return
        }

        do {
            try rewardedAd.canPresent(fromRootViewController: viewController)
            let rewardAmount = rewardedAd.adReward.amount
            rewardedAd.present(fromRootViewController: viewController, userDidEarnRewardHandler: {
                onReward(rewardAmount)
            })
        } catch {
            load()
            onError?(error)
            onNotReady?()
            return
        }
    }
}

// MARK: - GADFullScreenContentDelegate

extension SwiftyAdsRewarded: GADFullScreenContentDelegate {
    func adDidRecordImpression(_ ad: GADFullScreenPresentingAd) {
        if case .development = environment {
            print("SwiftyAdsRewarded did record impression for ad: \(ad)")
        }
    }

    func adWillPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        onOpen?()
    }

    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        // Nil out reference
        rewardedAd = nil
        // Send callback
        onClose?()
        // Load the next ad so its ready for displaying
        load()
    }

    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        onError?(error)
    }
}
