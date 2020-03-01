//
//  SwiftyAdsConsentStyle.swift
//  SwiftyAdsDemo
//
//  Created by Dominik Ringler on 01/03/2020.
//  Copyright © 2020 Dominik Ringler. All rights reserved.
//

import Foundation

public enum SwiftyAdsConsentStyle {
    case adMob(shouldOfferAdFree: Bool)
    case custom(content: SwiftyAdsCustomConsentAlertContent)
}

public struct SwiftyAdsCustomConsentAlertContent {
    public let title: String
    public let message: String
    public let actionAdFree: String?
    public let actionAllowPersonalized: String
    public let actionAllowNonPersonalized: String
    
    public init(
        title: String,
        message: String,
        actionAdFree: String?,
        actionAllowPersonalized: String,
        actionAllowNonPersonalized: String) {
        self.title = title
        self.message = message
        self.actionAdFree = actionAdFree
        self.actionAllowPersonalized = actionAllowPersonalized
        self.actionAllowNonPersonalized = actionAllowNonPersonalized
    }
}
