//
//  GADRequestBuilder.swift
//  SwiftyAd
//
//  Created by Dominik Ringler on 20/02/2020.
//  Copyright © 2020 Dominik. All rights reserved.
//

import Foundation
import GoogleMobileAds

protocol RequestBuilderType: AnyObject {
    func build() -> GADRequest
}

final class RequestBuilder {
    private let mobileAds: GADMobileAds
    private let consentManager: SwiftyAdConsentManagerType
    private let testDevices: [String]?
    
    init(mobileAds: GADMobileAds, consentManager: SwiftyAdConsentManagerType, testDevices: [String]?) {
        self.mobileAds = mobileAds
        self.consentManager = consentManager
        self.testDevices = testDevices
    }
}

extension RequestBuilder: RequestBuilderType {
  
    func build() -> GADRequest {
        let request = GADRequest()
        
        // Set debug settings
        #if DEBUG
        //request.testDevices = testDevices
        mobileAds.requestConfiguration.testDeviceIdentifiers = testDevices
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
