//    The MIT License (MIT)
//
//    Copyright (c) 2015-2020 Dominik Ringler
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
    func show(from viewController: UIViewController)
}

final class SwiftyAdsRewarded: NSObject {
    
    // MARK: - Properties
    
    private let adUnitId: String
    private let request: () -> GADRequest
    private let didOpen: () -> Void
    private let didClose: () -> Void
    private let didReward: (Int) -> Void
    
    private var rewardedAd: GADRewardedAd?
    
    // MARK: - Init
    
    init(adUnitId: String,
         request: @escaping () -> GADRequest,
         didOpen: @escaping () -> Void,
         didClose: @escaping () -> Void,
         didReward: @escaping (Int) -> Void) {
        self.adUnitId = adUnitId
        self.request = request
        self.didOpen = didOpen
        self.didClose = didClose
        self.didReward = didReward
    }
}

// MARK: - SwiftyAdRewardedType

extension SwiftyAdsRewarded: SwiftyAdsRewardedType {
    
    var isReady: Bool {
        guard rewardedAd?.isReady == true else {
            print("SwiftyRewardedAd reward video is not ready, reloading...")
            load()
            return false
        }
        return true
    }
    
    func load() {
        rewardedAd = GADRewardedAd(adUnitID: adUnitId)
        rewardedAd?.load(request()) { error in
            if let error = error {
                print(error.localizedDescription)
                return
            }
        }
    }
 
    func show(from viewController: UIViewController) {
        if isReady {
            rewardedAd?.present(fromRootViewController: viewController, delegate: self)
        } else {
            let alertController = UIAlertController(
                title: SwiftyAdsLocalizedString.sorry,
                message: SwiftyAdsLocalizedString.noVideo,
                preferredStyle: .alert
            )
            alertController.addAction(UIAlertAction(title: SwiftyAdsLocalizedString.ok, style: .cancel))
            viewController.present(alertController, animated: true)
        }
    }
}

// MARK: - GADRewardedAdDelegate

extension SwiftyAdsRewarded: GADRewardedAdDelegate {
    
    func rewardedAdDidPresent(_ rewardedAd: GADRewardedAd) {
        print("AdMob reward based video did present ad from: \(rewardedAd.responseInfo?.adNetworkClassName ?? "")")
        didOpen()
    }
    
    func rewardedAdDidDismiss(_ rewardedAd: GADRewardedAd) {
        didClose()
        load()
    }
    
    func rewardedAd(_ rewardedAd: GADRewardedAd, didFailToPresentWithError error: Error) {
        print(error.localizedDescription)
        // Do not reload here as it might cause endless loading loops if no/slow internet
    }
    
    func rewardedAd(_ rewardedAd: GADRewardedAd, userDidEarn reward: GADAdReward) {
        print("AdMob reward based video ad did reward user with \(reward)")
        let rewardAmount = Int(truncating: reward.amount)
        didReward(rewardAmount)
    }
}
