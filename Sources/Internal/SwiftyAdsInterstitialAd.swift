//    The MIT License (MIT)
//
//    Copyright (c) 2015-2025 Dominik Ringler
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

protocol SwiftyAdsInterstitialAd: Sendable {
    var isReady: Bool { get }
    func load() async throws
    func stopLoading()
    @MainActor
    func show(from viewController: UIViewController,
              onOpen: (() -> Void)?,
              onClose: (() -> Void)?,
              onError: ((Error) -> Void)?) async throws
}

final class GADSwiftyAdsInterstitialAd: NSObject, @unchecked Sendable {

    // MARK: - Properties

    private let adUnitId: String
    private let environment: SwiftyAdsEnvironment
    private let request: () -> Request
    
    private var onOpen: (() -> Void)?
    private var onClose: (() -> Void)?
    private var onError: ((Error) -> Void)?
    
    private var interstitialAd: InterstitialAd?
    
    // MARK: - Initialization
    
    init(adUnitId: String, environment: SwiftyAdsEnvironment, request: @escaping () -> Request) {
        self.adUnitId = adUnitId
        self.environment = environment
        self.request = request
    }
}

// MARK: - SwiftyAdsInterstitialAd

extension GADSwiftyAdsInterstitialAd: SwiftyAdsInterstitialAd {
    var isReady: Bool {
        interstitialAd != nil
    }
    
    func load() async throws {
        interstitialAd = try await InterstitialAd.load(with: adUnitId, request: request())
        interstitialAd?.fullScreenContentDelegate = self
    }

    func stopLoading() {
        interstitialAd?.fullScreenContentDelegate = nil
        interstitialAd = nil
    }
    
    @MainActor
    func show(from viewController: UIViewController,
              onOpen: (() -> Void)?,
              onClose: (() -> Void)?,
              onError: ((Error) -> Void)?) async throws {
        self.onOpen = onOpen
        self.onClose = onClose
        self.onError = onError
        
        guard let interstitialAd = interstitialAd else {
            reload()
            throw SwiftyAdsError.interstitialAdNotLoaded
        }

        do {
            try interstitialAd.canPresent(from: viewController)
            interstitialAd.present(from: viewController)
        } catch {
            reload()
            throw error
        }
    }
}

// MARK: - GADFullScreenContentDelegate

extension GADSwiftyAdsInterstitialAd: FullScreenContentDelegate {
    func adDidRecordImpression(_ ad: FullScreenPresentingAd) {
        if case .development = environment {
            print("SwiftyAdsInterstitial did record impression for ad: \(ad)")
        }
    }

    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        onOpen?()
    }
    
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        // Nil out reference
        interstitialAd = nil
        // Send callback
        onClose?()
        // Load the next ad so its ready for displaying
        reload()
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        onError?(error)
    }
}

// MARK: - Private Methods

private extension GADSwiftyAdsInterstitialAd {
    func reload() {
        Task { [weak self] in
            try await self?.load()
        }
    }
}
