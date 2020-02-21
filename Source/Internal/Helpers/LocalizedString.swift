//
//  LocalizedString.swift
//  SwiftyAd
//
//  Created by Dominik Ringler on 21/05/2019.
//  Copyright © 2019 Dominik. All rights reserved.
//

import Foundation

enum LocalizedString {
    static let sorry = localized("Sorry", comment: "Sorry")
    static let ok = localized("Ok", comment: "Ok")
    static let noVideo = localized("NoVideo", comment: "No video available to watch at the moment.")
    
    // Consent
    static let consentTitle = localized("ConsentTitle", comment: "Permission to use data")
    static let consentMessage = localized("ConsentMessage", comment: "We care about your privacy and data security. We keep this app free by showing ads. You can change your choice anytime in the app settings. Our partners will collect data and use a unique identifier on your device to show you ads.")
    static let weShowAdsFrom = localized("WeShowAdsFrom", comment: "We show ads from: ")
    static let weUseAdProviders = localized("WeUseAdProviders", comment: "We use the following ad technology providers: ")
    static let adFree = localized("AdFree", comment: "Buy ad free app") // ?
    static let allowPersonalized = localized("AllowPersonalized", comment: "Allow personalized ads")
    static let allowNonPersonalized = localized("AllowNonPersonalized", comment: "Allow non-personalized ads")
}

// MARK: - Get Localized String

private extension LocalizedString {
    
    static func localized(_ text: String, comment: String, argument: CVarArg? = nil, argument2: CVarArg? = nil) -> String {
        return NSLocalizedString(text, tableName: nil, bundle: Bundle(for: SwiftyAd.self), value: "", comment: comment)
    }
}
