//    The MIT License (MIT)
//
//    Copyright (c) 2015-2024 Dominik Ringler
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

import Foundation

struct SwiftyAdsConfiguration: Decodable, Equatable {
    let bannerAdUnitId: String?
    let interstitialAdUnitId: String?
    let rewardedAdUnitId: String?
    let rewardedInterstitialAdUnitId: String?
    let nativeAdUnitId: String?
    let isTaggedForChildDirectedTreatment: Bool? /// COPPA
    let isTaggedForUnderAgeOfConsent: Bool? /// GDPR
}

extension SwiftyAdsConfiguration {
    static func production(bundle: Bundle) -> Self {
        guard let configuration = decodePlist(type: Self.self, fileName: "SwiftyAds", bundle: bundle) else {
            fatalError("SwiftyAds could not find SwiftyAds.plist in the the main bundle.")
        }
        return configuration
    }
    
    // https://developers.google.com/admob/ios/test-ads
    static func debug(for developmentSettings: SwiftyAdsEnvironment.DevelopmentSettings) -> Self {
        Self(
            bannerAdUnitId: "ca-app-pub-3940256099942544/2934735716",
            interstitialAdUnitId: "ca-app-pub-3940256099942544/4411468910",
            rewardedAdUnitId: "ca-app-pub-3940256099942544/1712485313",
            rewardedInterstitialAdUnitId: "ca-app-pub-3940256099942544/6978759866",
            nativeAdUnitId: "ca-app-pub-3940256099942544/3986624511",
            isTaggedForChildDirectedTreatment: developmentSettings.isTaggedForChildDirectedTreatment,
            isTaggedForUnderAgeOfConsent: developmentSettings.isTaggedForUnderAgeOfConsent
        )
    }
}

// MARK: - Decoding

private func decodePlist<T: Decodable>( type: T.Type, fileName: String, bundle: Bundle) -> T? {
    guard let url = bundle.url(forResource: fileName, withExtension: "plist") else { return nil }
    do {
        let data = try Data(contentsOf: url)
        let decoder = PropertyListDecoder()
        return try decoder.decode(T.self, from: data)
    } catch {
        fatalError("SwiftyAds decoding \(fileName).plist error: \(error).")
    }
}
