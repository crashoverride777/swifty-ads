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

import Foundation

struct SwiftyAdsConfiguration: Decodable {
    let bannerAdUnitId: String?
    let interstitialAdUnitId: String?
    let rewardedVideoAdUnitId: String?
    let nativeAdUnitId: String?
    let privacyPolicyURL: String
    let isTaggedForUnderAgeOfConsent: Bool
    let mediationNetworks: [String]

    var ids: [String] {
        [bannerAdUnitId, interstitialAdUnitId, rewardedVideoAdUnitId, nativeAdUnitId]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
    }
    
    var adNetworks: String {
        let networks: [String] = ["Google AdMob"] + mediationNetworks
        return networks
            .map({ $0 })
            .joined(separator: networks.count > 1 ? ", " : "")
    }
}

// MARK: - Static

extension SwiftyAdsConfiguration {
    
    static var production: SwiftyAdsConfiguration {
        guard let configurationURL = Bundle.main.url(forResource: "SwiftyAds", withExtension: "plist") else {
            fatalError("SwiftyAdsConfiguration could not find SwiftyAds.plist in the main bundle.")
        }
        do {
            let data = try Data(contentsOf: configurationURL)
            let decoder = PropertyListDecoder()
            return try decoder.decode(SwiftyAdsConfiguration.self, from: data)
        } catch {
            fatalError("SwiftyAdsConfiguration decoding SwiftyAds.plist error \(error)")
        }
    }
    
    static var debug: SwiftyAdsConfiguration {
        SwiftyAdsConfiguration(
            bannerAdUnitId: "ca-app-pub-3940256099942544/2934735716",
            interstitialAdUnitId: "ca-app-pub-3940256099942544/4411468910",
            rewardedVideoAdUnitId: "ca-app-pub-3940256099942544/1712485313",
            nativeAdUnitId: "ca-app-pub-3940256099942544/3986624511",
            privacyPolicyURL: "https://example.com/privacyPolicy",
            isTaggedForUnderAgeOfConsent: false,
            mediationNetworks: ["Test Mediation Network 1, Test Mediation Network 2"]
        )
    }
}
