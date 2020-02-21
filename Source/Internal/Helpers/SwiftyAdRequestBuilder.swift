//
//  SwiftyAdRequestBuilder.swift
//  SwiftyAd
//
//  Created by Dominik Ringler on 20/02/2020.
//  Copyright © 2020 Dominik. All rights reserved.
//

import Foundation
import GoogleMobileAds

protocol SwiftyAdRequestBuilderType: AnyObject {
    func build() -> GADRequest
}

final class SwiftyAdRequestBuilder {
    
    // MARK: - Properties
    
    private let mobileAds: GADMobileAds
    private let isGDPRRequired: Bool
    private let isNonPersonalizedOnly: Bool
    private let isTaggedForUnderAgeOfConsent: Bool
    private let testDevices: [String]?
    
    // MARK: - Init
    
    init(mobileAds: GADMobileAds,
         isGDPRRequired: Bool,
         isNonPersonalizedOnly: Bool,
         isTaggedForUnderAgeOfConsent: Bool,
         testDevices: [String]?) {
        self.mobileAds = mobileAds
        self.isGDPRRequired = isGDPRRequired
        self.isNonPersonalizedOnly = isNonPersonalizedOnly
        self.isTaggedForUnderAgeOfConsent = isTaggedForUnderAgeOfConsent
        self.testDevices = testDevices
    }
}

// MARK: - RequestBuilderType

extension SwiftyAdRequestBuilder: SwiftyAdRequestBuilderType {
  
    func build() -> GADRequest {
        let request = GADRequest()
        #if DEBUG
        mobileAds.requestConfiguration.testDeviceIdentifiers = testDevices
        #endif
        addGDPRExtrasIfNeeded(for: request)
        return request
    }
}

// MARK: - Private Methods

private extension SwiftyAdRequestBuilder {
    
    func addGDPRExtrasIfNeeded(for request: GADRequest) {
        guard isGDPRRequired else {
            return
        }
            
        // Create additional parameters with under age of consent
        var additionalParameters: [String: Any] = ["tag_for_under_age_of_consent": isTaggedForUnderAgeOfConsent]
      
        // Update for non personalized if needed
        if isNonPersonalizedOnly {
            additionalParameters["npa"] = "1"
        }
        
        // Create extras
        let extras = GADExtras()
        extras.additionalParameters = additionalParameters
        
        // Register extras in request
        request.register(extras)
    }
}
