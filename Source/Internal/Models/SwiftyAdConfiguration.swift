//
//  SwiftyAdConfiguration.swift
//  SwiftyAd
//
//  Created by Dominik Ringler on 21/05/2019.
//  Copyright © 2019 Dominik. All rights reserved.
//

import Foundation

struct SwiftyAdConfiguration: Codable {
    let bannerAdUnitId: String
    let interstitialAdUnitId: String
    let rewardedVideoAdUnitId: String
    let gdpr: SwiftyAdConsentConfiguration

    var ids: [String] {
        return [bannerAdUnitId, interstitialAdUnitId, rewardedVideoAdUnitId].filter { !$0.isEmpty }
    }
}

extension SwiftyAdConfiguration {
    
    static var propertyList: SwiftyAdConfiguration {
        guard let configurationURL = Bundle.main.url(forResource: "SwiftyAd", withExtension: "plist") else {
            print("SwiftyAd must have a valid property list")
            fatalError("SwiftyAd must have a valid property list")
        }
        do {
            let data = try Data(contentsOf: configurationURL)
            let decoder = PropertyListDecoder()
            return try decoder.decode(SwiftyAdConfiguration.self, from: data)
        } catch {
            print("SwiftyAd must have a valid property list \(error)")
            fatalError("SwiftyAd must have a valid property list")
        }
    }
    
    static var debug: SwiftyAdConfiguration {
        return SwiftyAdConfiguration(
            bannerAdUnitId: "ca-app-pub-3940256099942544/2934735716",
            interstitialAdUnitId: "ca-app-pub-3940256099942544/4411468910",
            rewardedVideoAdUnitId: "ca-app-pub-3940256099942544/1712485313",
            gdpr: SwiftyAdConsentConfiguration(
                privacyPolicyURL: "https://developers.google.com/admob/ios/eu-consent",
                shouldOfferAdFree: false,
                mediationNetworks: [],
                isTaggedForUnderAgeOfConsent: false,
                isCustomForm: true
            )
        )
    }
}
