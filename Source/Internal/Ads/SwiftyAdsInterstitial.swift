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

protocol SwiftyAdsInterstitialType: AnyObject {
    var isReady: Bool { get }
    func load()
    func show(from viewController: UIViewController,
              onOpen: @escaping () -> Void,
              onClose: @escaping () -> Void,
              onError: @escaping (Error) -> Void)
    func stopLoading()
}

final class SwiftyAdsInterstitial: NSObject {

    // MARK: - Properties
    
    private let adUnitId: String
    private let request: () -> GADRequest
    private var onOpen: (() -> Void)?
    private var onClose: (() -> Void)?
    private var onError: ((Error) -> Void)?
    
    private var interstitial: GADInterstitial?
    
    // MARK: - Init
    
    init(adUnitId: String, request: @escaping () -> GADRequest) {
        self.adUnitId = adUnitId
        self.request = request
    }
}

// MARK: - SwiftyAdInterstitialType

extension SwiftyAdsInterstitial: SwiftyAdsInterstitialType {

    var isReady: Bool {
        guard let interstitial = interstitial, interstitial.isReady else {
            print("SwiftyAdsInterstitial ad is not ready, reloading...")
            load()
            return false
        }
        return true
    }
    
    func load() {
        interstitial = GADInterstitial(adUnitID: adUnitId)
        interstitial?.delegate = self
        interstitial?.load(request())
    }
    
    func show(from viewController: UIViewController,
              onOpen: @escaping () -> Void,
              onClose: @escaping () -> Void,
              onError: @escaping (Error) -> Void) {
        guard isReady else { return }
        self.onOpen = onOpen
        self.onClose = onClose
        self.onError = onError
        interstitial?.present(fromRootViewController: viewController)
    }
    
    func stopLoading() {
        interstitial?.delegate = nil
        interstitial = nil
    }
}

// MARK: - GADInterstitialDelegate

extension SwiftyAdsInterstitial: GADInterstitialDelegate {
    
    func interstitialDidReceiveAd(_ ad: GADInterstitial) {
        print("SwiftyAdsInterstitial did receive ad from: \(ad.responseInfo?.adNetworkClassName ?? "")")
    }
    
    func interstitialWillPresentScreen(_ ad: GADInterstitial) {
        onOpen?()
    }
    
    func interstitialWillLeaveApplication(_ ad: GADInterstitial) {

    }
    
    func interstitialWillDismissScreen(_ ad: GADInterstitial) {
    
    }
    
    func interstitialDidDismissScreen(_ ad: GADInterstitial) {
        onClose?()
        load()
    }
    
    func interstitialDidFail(toPresentScreen ad: GADInterstitial) {
    
    }
    
    func interstitial(_ ad: GADInterstitial, didFailToReceiveAdWithError error: GADRequestError) {
        onError?(error)
        // Do not reload here as it might cause endless loading loops if no/slow internet
    }
}
