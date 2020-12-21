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
              types: [GADAdLoaderAdType],
              count: Int?,
              onReceiveUnified: @escaping (GADUnifiedNativeAd) -> Void,
              onReceiveCustomTemplate: @escaping (GADNativeCustomTemplateAd) -> Void,
              onReceiveBannerView: @escaping (DFPBannerView) -> Void,
              onError: @escaping (GADRequestError) -> Void)
}

final class SwiftyAdsNativeAd: NSObject {

    // MARK: - Properties

    private let adUnitId: String
    private let nativeCustomTemplateIDs: [String]
    private let validBannerSizes: [NSValue]
    private let request: () -> GADRequest
    private var adLoader: GADAdLoader?

    private var onReceiveUnified: ((GADUnifiedNativeAd) -> Void)?
    private var onReceiveCustomTemplate: ((GADNativeCustomTemplateAd) -> Void)?
    private var onReceiveBannerView: ((DFPBannerView) -> Void)?
    private var onError: ((GADRequestError) -> Void)?

    private var isLoading = false

    // MARK: - Init

    init(adUnitId: String,
         nativeCustomTemplateIDs: [String],
         validBannerSizes: [NSValue],
         request: @escaping () -> GADRequest) {
        self.adUnitId = adUnitId
        self.nativeCustomTemplateIDs = nativeCustomTemplateIDs
        self.validBannerSizes = validBannerSizes
        self.request = request
    }
}

// MARK: - SwiftyAdsNativeAdType

extension SwiftyAdsNativeAd: SwiftyAdsNativeAdType {

    func load(from viewController: UIViewController,
              types: [GADAdLoaderAdType],
              count: Int?,
              onReceiveUnified: @escaping (GADUnifiedNativeAd) -> Void,
              onReceiveCustomTemplate: @escaping (GADNativeCustomTemplateAd) -> Void,
              onReceiveBannerView: @escaping (DFPBannerView) -> Void,
              onError: @escaping (GADRequestError) -> Void) {
        // When reusing a GADAdLoader, make sure you wait for each request to complete
        // before calling loadRequest: again.
        guard !isLoading else { return }
        self.onReceiveUnified = onReceiveUnified
        self.onReceiveCustomTemplate = onReceiveCustomTemplate
        self.onReceiveBannerView = onReceiveBannerView
        self.onError = onError

        isLoading = true

        // Create multiple ad options
        var multipleAdsOptions: [GADMultipleAdsAdLoaderOptions]?
        if let count = count {
            let loaderOptions = GADMultipleAdsAdLoaderOptions()
            loaderOptions.numberOfAds = count
            multipleAdsOptions = [loaderOptions]
        }

        // Create ad loader
        adLoader = GADAdLoader(
            adUnitID: adUnitId,
            rootViewController: viewController,
            adTypes: types,
            options: multipleAdsOptions
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
        onReceiveUnified?(nativeAd)
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

// MARK: - GADNativeCustomTemplateAdLoaderDelegate

extension SwiftyAdsNativeAd: GADNativeCustomTemplateAdLoaderDelegate {

    func nativeCustomTemplateIDs(for adLoader: GADAdLoader) -> [String] {
        nativeCustomTemplateIDs
    }

    func adLoader(_ adLoader: GADAdLoader, didReceive nativeCustomTemplateAd: GADNativeCustomTemplateAd) {
        onReceiveCustomTemplate?(nativeCustomTemplateAd)
    }
}

// MARK: - DFPBannerAdLoaderDelegate

extension SwiftyAdsNativeAd: DFPBannerAdLoaderDelegate {

    func validBannerSizes(for adLoader: GADAdLoader) -> [NSValue] {
        validBannerSizes
    }

    func adLoader(_ adLoader: GADAdLoader, didReceive bannerView: DFPBannerView) {
        onReceiveBannerView?(bannerView)
    }
}
