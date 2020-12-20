//
//  SwiftyAdsNativeAd.swift
//  SwiftyAds
//
//  Created by Dominik Ringler on 20/12/2020.
//  Copyright © 2020 Dominik. All rights reserved.
//

import GoogleMobileAds

protocol SwiftyAdsNativeAdType: AnyObject {
    var isReady: Bool { get }
    func load()
    func show(
        onDidRecordImpression: (() -> Void)?,
        onWillPresentScreen: (() -> Void)?,
        onWillDismissScreen: (() -> Void)?,
        onDidDismissScreen: (() -> Void)?,
        onWillLeaveApplication: (() -> Void)?,
        onClick: (() -> Void)?,
        onError: ((Error) -> Void)?
    ) -> GADUnifiedNativeAd?
}

final class SwiftyAdsNativeAd: NSObject {

    // MARK: - Properties

    private let adUnitId: String
    private let options: [GADMultipleAdsAdLoaderOptions]
    private let request: () -> GADRequest
    private var adLoader: GADAdLoader?
    private var nativeAd: GADUnifiedNativeAd?

    private var onDidRecordImpression: (() -> Void)?
    private var onWillPresentScreen: (() -> Void)?
    private var onWillDismissScreen: (() -> Void)?
    private var onDidDismissScreen: (() -> Void)?
    private var onWillLeaveApplication: (() -> Void)?
    private var onClick: (() -> Void)?
    private var onError: ((Error) -> Void)?

    private var isLoading = false

    // MARK: - Init

    init(adUnitId: String,
         options: [GADMultipleAdsAdLoaderOptions],
         request: @escaping () -> GADRequest) {
        self.adUnitId = adUnitId
        self.options = options
        self.request = request
    }
}

// MARK: - SwiftyAdsNativeAdType

extension SwiftyAdsNativeAd: SwiftyAdsNativeAdType {

    var isReady: Bool {
        nativeAd?.isReady ?? false
    }

    // While prefetching ads is a great technique, it's important that you don't keep old ads around forever
    // without displaying them. Any native ad objects that have been held without display for longer than an hour
    // should be discarded and replaced with new ads from a new request.
    func load(from viewController: UIViewController) {
        // When reusing a GADAdLoader, make sure you wait for each request to complete
        // before calling loadRequest: again.
        guard !isLoading else { return }
        isLoading = true

        adLoader = GADAdLoader(
            adUnitID: adUnitId,
            rootViewController: viewController,
            adTypes: [kGADAdLoaderAdTypeUnifiedNative],
            options: options
        )
        adLoader.delegate = self

        // Requests for multiple native ads don't currently work for AdMob ad unit IDs
        // that have been configured for mediation. Publishers using mediation should avoid
        // using the GADMultipleAdsAdLoaderOptions class when making requests.
        adLoader.load(request())
    }

    func show(
        onDidRecordImpression: (() -> Void)?,
        onWillPresentScreen: (() -> Void)?,
        onWillDismissScreen: (() -> Void)?,
        onDidDismissScreen: (() -> Void)?,
        onWillLeaveApplication: (() -> Void)?,
        onClick: (() -> Void)?,
        onError: ((Error) -> Void)?
    ) -> GADUnifiedNativeAd? {
        self.onDidRecordImpression = onDidRecordImpression
        self.onWillPresentScreen = onWillPresentScreen
        self.onWillDismissScreen = onWillDismissScreen
        self.onDidDismissScreen = onDidDismissScreen
        self.onWillLeaveApplication = onWillLeaveApplication
        self.onClick = onClick
        self.onError = onError

        // Return native ad or load a new one if none is ready
        if let nativeAd = nativeAd {
            return nativeAd
        } else {
            load()
            return nil
        }
    }
}

// MARK: - GADUnifiedNativeAdLoaderDelegate

extension SwiftyAdsNativeAd: GADUnifiedNativeAdLoaderDelegate {

    func adLoader(_ adLoader: GADAdLoader, didReceive nativeAd: GADUnifiedNativeAd) {
        // Keep reference to received native ad so we can use it later on
        self.nativeAd = nativeAd

        // Set the delegate of the received native ad
        nativeAd.delegate = self
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

// MARK: - GADUnifiedNativeAdDelegate

extension SwiftyAdsNativeAd: GADUnifiedNativeAdDelegate {

    func nativeAdDidRecordImpression(_ nativeAd: GADUnifiedNativeAd) {
        // The native ad was shown.
        onDidRecordImpression?()
    }

    func nativeAdDidRecordClick(_ nativeAd: GADUnifiedNativeAd) {
        // The native ad was clicked on.
        onClick?()
    }

    func nativeAdWillPresentScreen(_ nativeAd: GADUnifiedNativeAd) {
        // The native ad will present a full screen view.
        onWillPresentScreen?()
    }

    func nativeAdWillDismissScreen(_ nativeAd: GADUnifiedNativeAd) {
        // The native ad will dismiss a full screen view.
        onWillDismissScreen?()
    }

    func nativeAdDidDismissScreen(_ nativeAd: GADUnifiedNativeAd) {
        // The native ad did dismiss a full screen view.
        onDidDismissScreen?()
    }

    func nativeAdWillLeaveApplication(_ nativeAd: GADUnifiedNativeAd) {
        // The native ad will cause the application to become inactive and
        // open a new application.
        onWillLeaveApplication?()
    }
}
