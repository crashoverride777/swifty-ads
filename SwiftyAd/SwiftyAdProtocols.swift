//
//  SwiftyAdProtocols.swift
//  SwiftyAd
//
//  Created by Dominik Ringler on 24/05/2019.
//  Copyright © 2019 Dominik. All rights reserved.
//

import UIKit

/// SwiftyAdDelegate
public protocol SwiftyAdDelegate: class {
    /// SwiftyAd did open
    func swiftyAdDidOpen(_ swiftyAd: SwiftyAd)
    /// SwiftyAd did close
    func swiftyAdDidClose(_ swiftyAd: SwiftyAd)
    /// Did change consent status
    func swiftyAd(_ swiftyAd: SwiftyAd, didChange consentStatus: SwiftyAdConsentStatus)
    /// SwiftyAd did reward user
    func swiftyAd(_ swiftyAd: SwiftyAd, didRewardUserWithAmount rewardAmount: Int)
}

/// A tracker protocol to show ads at certain interval
public protocol SwiftyAdIntervalTrackerInput: class {
    func canShow(forInterval interval: Int?) -> Bool
}

/// A protocol for mediation implementations
public protocol SwiftyAdMediation: class {
    func update(for consentType: SwiftyAdConsentStatus)
}

/// A protocol for consent management in EEA
public protocol SwiftyAdConsent: class {
    var status: SwiftyAdConsentStatus { get }
    var isInEEA: Bool { get }
    var isRequiredToAskForConsent: Bool { get }
    var hasConsent: Bool { get }
    var isTaggedForUnderAgeOfConsent: Bool { get }
    func ask(from viewController: UIViewController,
             skipIfAlreadyAuthorized: Bool,
             handler: @escaping (SwiftyAdConsentStatus) -> Void)
}
