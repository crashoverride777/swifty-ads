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

import Foundation

struct SwiftyAdsConfiguration: Codable {
    let bannerAdUnitId: String
    let interstitialAdUnitId: String
    let rewardedVideoAdUnitId: String
    let gdpr: SwiftyAdsConsentConfiguration

    var ids: [String] {
        return [bannerAdUnitId, interstitialAdUnitId, rewardedVideoAdUnitId].filter { !$0.isEmpty }
    }
}

extension SwiftyAdsConfiguration {
    
    static var propertyList: SwiftyAdsConfiguration {
        guard let configurationURL = Bundle.main.url(forResource: "SwiftyAds", withExtension: "plist") else {
            fatalError("SwiftyAdsConfiguration could not find SwiftyAds.plist in the main bundle")
        }
        do {
            let data = try Data(contentsOf: configurationURL)
            let decoder = PropertyListDecoder()
            return try decoder.decode(SwiftyAdsConfiguration.self, from: data)
        } catch {
            fatalError("SwiftyAdsConfiguration could not decode property list, please ensure all fields are correct")
        }
    }
    
    static var debug: SwiftyAdsConfiguration {
        return SwiftyAdsConfiguration(
            bannerAdUnitId: "ca-app-pub-3940256099942544/2934735716",
            interstitialAdUnitId: "ca-app-pub-3940256099942544/4411468910",
            rewardedVideoAdUnitId: "ca-app-pub-3940256099942544/1712485313",
            gdpr: SwiftyAdsConsentConfiguration(
                privacyPolicyURL: "https://developers.google.com/admob/ios/eu-consent",
                shouldOfferAdFree: false,
                mediationNetworks: [],
                isTaggedForUnderAgeOfConsent: false,
                isCustomForm: true
            )
        )
    }
}
