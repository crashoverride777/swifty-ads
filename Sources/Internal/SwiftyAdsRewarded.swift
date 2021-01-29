//    The MIT License (MIT)
//
//    Copyright (c) 2015-2021 Dominik Ringler
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
              onReward: @escaping (Int) -> Void)
}

final class SwiftyAdsRewarded: NSObject {
    
    // MARK: - Properties
    
    private let adUnitId: String
    private let request: () -> GADRequest
    private var onOpen: (() -> Void)?
    private var onClose: (() -> Void)?
    private var onReward: ((Int) -> Void)?
    private var onError: ((Error) -> Void)?
    
    private var rewardedAd: GADRewardedAd?
    
    // MARK: - Initialization
    
    init(adUnitId: String, request: @escaping () -> GADRequest) {
        self.adUnitId = adUnitId
        self.request = request
    }
}

// MARK: - SwiftyAdRewardedType

extension SwiftyAdsRewarded: SwiftyAdsRewardedType {
    
    var isReady: Bool {
        rewardedAd?.isReady ?? false
    }
    
    func load() {
        rewardedAd = GADRewardedAd(adUnitID: adUnitId)
        rewardedAd?.load(request()) { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                self.onError?(error)
                return
            }
        }
    }
 
    func show(from viewController: UIViewController,
              onOpen: (() -> Void)?,
              onClose: (() -> Void)?,
              onError: ((Error) -> Void)?,
              onNotReady: (() -> Void)?,
              onReward: @escaping (Int) -> Void) {
        self.onOpen = onOpen
        self.onClose = onClose
        self.onError = onError
        self.onReward = onReward
        
        if isReady {
            rewardedAd?.present(fromRootViewController: viewController, delegate: self)
        } else {
            load()
            onNotReady?()
        }
    }
}

// MARK: - GADRewardedAdDelegate

extension SwiftyAdsRewarded: GADRewardedAdDelegate {
    
    func rewardedAdDidPresent(_ rewardedAd: GADRewardedAd) {
        print("SwiftyAdsRewarded did present ad from: \(rewardedAd.responseInfo?.adNetworkClassName ?? "not found")")
        onOpen?()
    }
    
    func rewardedAdDidDismiss(_ rewardedAd: GADRewardedAd) {
        onClose?()
        // Load the next ad so its ready for displaying
        load()
    }

    func rewardedAd(_ rewardedAd: GADRewardedAd, userDidEarn reward: GADAdReward) {
        let rewardAmount = Int(truncating: reward.amount)
        onReward?(rewardAmount)
    }
    
    func rewardedAd(_ rewardedAd: GADRewardedAd, didFailToPresentWithError error: Error) {
        onError?(error)
        // Do not reload here as it might cause endless loading loops if no/slow internet
    }
}
