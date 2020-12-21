//
//  SwiftyAdsNativeAd.swift
//  SwiftyAds
//
//  Created by Dominik Ringler on 20/12/2020.
//  Copyright © 2020 Dominik. All rights reserved.
//

import GoogleMobileAds

protocol SwiftyAdsNativeAdType: AnyObject {
    func load(from viewController: UIViewController,
              onReceive: @escaping (GADUnifiedNativeAd) -> Void,
              onError: @escaping (Error) -> Void)
}

final class SwiftyAdsNativeAd: NSObject {

    // MARK: - Properties

    private let adUnitId: String
    private let options: [GADMultipleAdsAdLoaderOptions]?
    private let request: () -> GADRequest
    private var adLoader: GADAdLoader?

    private var onReceive: ((GADUnifiedNativeAd) -> Void)?
    private var onError: ((Error) -> Void)?

    private var isLoading = false

    // MARK: - Init

    init(adUnitId: String,
         options: [GADMultipleAdsAdLoaderOptions]?,
         request: @escaping () -> GADRequest) {
        self.adUnitId = adUnitId
        self.options = options
        self.request = request
    }
}

// MARK: - SwiftyAdsNativeAdType

extension SwiftyAdsNativeAd: SwiftyAdsNativeAdType {

    func load(from viewController: UIViewController,
              onReceive: @escaping (GADUnifiedNativeAd) -> Void,
              onError: @escaping (Error) -> Void) {
        // When reusing a GADAdLoader, make sure you wait for each request to complete
        // before calling loadRequest: again.
        guard !isLoading else { return }
        self.onReceive = onReceive
        self.onError = onError

        isLoading = true

        adLoader = GADAdLoader(
            adUnitID: adUnitId,
            rootViewController: viewController,
            adTypes: [.unifiedNative],
            options: options
        )
        adLoader?.delegate = self

        // Requests for multiple native ads don't currently work for AdMob ad unit IDs
        // that have been configured for mediation. Publishers using mediation should avoid
        // using the GADMultipleAdsAdLoaderOptions class when making requests.
        adLoader?.load(request())
    }
}

// MARK: - GADUnifiedNativeAdLoaderDelegate

extension SwiftyAdsNativeAd: GADUnifiedNativeAdLoaderDelegate {

    func adLoader(_ adLoader: GADAdLoader, didReceive nativeAd: GADUnifiedNativeAd) {
        onReceive?(nativeAd)
    }

    func adLoaderDidFinishLoading(_ adLoader: GADAdLoader) {
        // The adLoader has finished loading ads, and a new request can be sent.
        isLoading = false
    }

    func adLoader(_ adLoader: GADAdLoader, didFailToReceiveAdWithError error: GADRequestError) {
        // The adLoader has finished with an error.
        isLoading = false
        onError?(error)
    }
}
