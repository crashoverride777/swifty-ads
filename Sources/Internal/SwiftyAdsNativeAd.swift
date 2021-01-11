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
              count: Int?,
              onReceive: @escaping (GADUnifiedNativeAd) -> Void,
              onError: @escaping (GADRequestError) -> Void)
}

final class SwiftyAdsNativeAd: NSObject {

    // MARK: - Properties

    private let adUnitId: String
    private let request: () -> GADRequest

    private var adLoader: GADAdLoader?

    private var onReceive: ((GADUnifiedNativeAd) -> Void)?
    private var onError: ((GADRequestError) -> Void)?

    private var isLoading = false

    // MARK: - Initialization

    init(adUnitId: String, request: @escaping () -> GADRequest) {
        self.adUnitId = adUnitId
        self.request = request
    }
}

// MARK: - SwiftyAdsNativeAdType

extension SwiftyAdsNativeAd: SwiftyAdsNativeAdType {

    func load(from viewController: UIViewController,
              count: Int?,
              onReceive: @escaping (GADUnifiedNativeAd) -> Void,
              onError: @escaping (GADRequestError) -> Void) {
        guard !isLoading else { return }
        self.onReceive = onReceive
        self.onError = onError
        isLoading = true

        // Create multiple ad options
        var multipleAdsOptions: [GADMultipleAdsAdLoaderOptions]?
        if let count = count {
            let loaderOptions = GADMultipleAdsAdLoaderOptions()
            loaderOptions.numberOfAds = count
            multipleAdsOptions = [loaderOptions]
        }

        // Create GADAdLoader
        adLoader = GADAdLoader(
            adUnitID: adUnitId,
            rootViewController: viewController,
            adTypes: [.unifiedNative],
            options: multipleAdsOptions
        )

        // Set the GADAdLoader delegate
        adLoader?.delegate = self

        // Load ad with request
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
        isLoading = false
        onError?(error)
    }
}
