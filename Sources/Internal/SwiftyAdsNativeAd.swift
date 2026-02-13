//    The MIT License (MIT)
//
//    Copyright (c) 2015-2026 Dominik Ringler
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

protocol SwiftyAdsNativeAd {
    @MainActor
    func load(from viewController: UIViewController,
              adUnitIdType: SwiftyAdsAdUnitIdType,
              loaderOptions: SwiftyAdsNativeAdLoaderOptions,
              adTypes: [AdLoaderAdType],
              onFinishLoading: (() -> Void)?,
              onError: ((Error) -> Void)?,
              onReceive: @escaping (NativeAd) -> Void)
    func stopLoading()
}

final class GADSwiftyAdsNativeAd: NSObject {

    // MARK: - Properties

    private let adUnitId: String
    private let environment: SwiftyAdsEnvironment
    private let request: () -> Request
    
    private var onFinishLoading: (() -> Void)?
    private var onError: ((Error) -> Void)?
    private var onReceive: ((NativeAd) -> Void)?
    
    private var adLoader: AdLoader?
    
    // MARK: - Initialization

    init(adUnitId: String, environment: SwiftyAdsEnvironment, request: @escaping () -> Request) {
        self.adUnitId = adUnitId
        self.environment = environment
        self.request = request
    }
}

// MARK: - SwiftyAdsNativeAd

extension GADSwiftyAdsNativeAd: SwiftyAdsNativeAd {
    @MainActor
    func load(from viewController: UIViewController,
              adUnitIdType: SwiftyAdsAdUnitIdType,
              loaderOptions: SwiftyAdsNativeAdLoaderOptions,
              adTypes: [AdLoaderAdType],
              onFinishLoading: (() -> Void)?,
              onError: ((Error) -> Void)?,
              onReceive: @escaping (NativeAd) -> Void) {
        self.onFinishLoading = onFinishLoading
        self.onError = onError
        self.onReceive = onReceive
        
        // If AdLoader is already loading we should not make another request
        if let adLoader = adLoader, adLoader.isLoading { return }

        // Create multiple ads ad loader options
        var multipleAdsAdLoaderOptions: [MultipleAdsAdLoaderOptions]? {
            switch loaderOptions {
            case .single:
                return nil
            case .multiple(let numberOfAds):
                let options = MultipleAdsAdLoaderOptions()
                options.numberOfAds = numberOfAds
                return [options]
            }
        }

        // Set the ad unit id
        var adUnitId: String {
            if case .development = environment {
                return self.adUnitId
            }
            switch adUnitIdType {
            case .plist:
                return self.adUnitId
            case .custom(let id):
                return id
            }
        }

        // Create GADAdLoader
        adLoader = AdLoader(
            adUnitID: adUnitId,
            rootViewController: viewController,
            adTypes: adTypes,
            options: multipleAdsAdLoaderOptions
        )

        // Set the GADAdLoader delegate
        adLoader?.delegate = self

        // Load ad with request
        adLoader?.load(request())
    }

    func stopLoading() {
        adLoader?.delegate = nil
        adLoader = nil
    }
}

// MARK: - GADNativeAdLoaderDelegate

extension GADSwiftyAdsNativeAd: NativeAdLoaderDelegate {
    func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
        onReceive?(nativeAd)
    }

    func adLoaderDidFinishLoading(_ adLoader: AdLoader) {
        onFinishLoading?()
    }

    func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: Error) {
        onError?(error)
    }
}
