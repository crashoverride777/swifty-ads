//
//  GADRequestBuilder.swift
//  SwiftyAd
//
//  Created by Dominik Ringler on 20/02/2020.
//  Copyright © 2020 Dominik. All rights reserved.
//

import Foundation
import GoogleMobileAds

protocol GADRequestBuilderType: AnyObject {
    func build() -> GADRequest
}

final class GADRequestBuilder {
    private let consentManager: SwiftyAdConsent
    private let testDevices: [String]?
    
    init(consentManager: SwiftyAdConsent, testDevices: [String]?) {
        self.consentManager = consentManager
        self.testDevices = testDevices
    }
}

extension GADRequestBuilder: GADRequestBuilderType {
  
    func build() -> GADRequest {
        let request = GADRequest()
        
        // Set debug settings
        #if DEBUG
        request.testDevices = testDevices
        #endif
        
        // Add extras if in EU (GDPR)
        if consentManager.isInEEA {
            
            // Create additional parameters with under age of consent
            var additionalParameters: [String: Any] = ["tag_for_under_age_of_consent": consentManager.isTaggedForUnderAgeOfConsent]
          
            // Update for consent status
            switch consentManager.status {
            case .nonPersonalized:
                additionalParameters["npa"] = "1" // only allow non-personalized ads
            default:
                break
            }
            
            // Create extras
            let extras = GADExtras()
            extras.additionalParameters = additionalParameters
            request.register(extras)
        }
        
        // Return the request
        return request
    }
}
