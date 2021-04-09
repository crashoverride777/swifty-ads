//
//  SwiftyAdsMediationConfigurator.swift
//  SwiftyAdsDemo
//
//  Created by Dominik Ringler on 09/04/2021.
//  Copyright © 2021 Dominik Ringler. All rights reserved.
//

import Foundation

public protocol SwiftyAdsMediationConfiguratorType: AnyObject {
    func enableCOPPA()
    func updateGDPR(for consentStatus: SwiftyAdsConsentStatus, isTaggedForUnderAgeOfConsent: Bool)
}
