//
//  SwiftyAdConsentConfiguration.swift
//  SwiftyAd
//
//  Created by Dominik Ringler on 21/05/2019.
//  Copyright © 2019 Dominik. All rights reserved.
//

import Foundation

struct SwiftyAdConsentConfiguration: Codable {
    let privacyPolicyURL: String
    let shouldOfferAdFree: Bool
    let mediationNetworks: [String]
    let isTaggedForUnderAgeOfConsent: Bool
    let isCustomForm: Bool
    
    var mediationNetworksString: String {
        return mediationNetworks.map({ $0 }).joined(separator: ", ")
    }
}
