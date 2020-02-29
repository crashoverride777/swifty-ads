//
//  SwiftyAdsType.swift
//  SwiftyAdsDemo
//
//  Created by Dominik Ringler on 29/02/2020.
//  Copyright © 2020 Dominik Ringler. All rights reserved.
//

import UIKit

// MARK: - Consent

public enum SwiftyAdsConsentStyle {
    case adMob(shouldOfferAdFree: Bool)
    case custom(SwiftyAdsCustomConsentAlertContent)
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

// MARK: - Mode

public enum SwiftyAdsMode {
    case production
    case test(devices: [String])
}

// MARK: - Type

public protocol SwiftyAdsType: AnyObject {
    var hasConsent: Bool { get }
    var isRequiredToAskForConsent: Bool { get }
    var isInterstitialReady: Bool { get }
    var isRewardedVideoReady: Bool { get }
    func setup(with viewController: UIViewController,
               mode: SwiftyAdsMode,
               consentStyle: SwiftyAdsConsentStyle,
               consentStatusDidChange: @escaping (SwiftyAdsConsentStatus) -> Void,
               handler: @escaping (SwiftyAdsConsentStatus) -> Void)
    func askForConsent(from viewController: UIViewController)
    func showBanner(from viewController: UIViewController,
                    atTop isAtTop: Bool,
                    animationDuration: TimeInterval,
                    onOpen: (() -> Void)?,
                    onClose: (() -> Void)?,
                    onError: ((Error) -> Void)?)
    func showInterstitial(from viewController: UIViewController,
                          withInterval interval: Int?,
                          onOpen: (() -> Void)?,
                          onClose: (() -> Void)?,
                          onError: ((Error) -> Void)?)
    func showRewardedVideo(from viewController: UIViewController,
                           onOpen: (() -> Void)?,
                           onClose: (() -> Void)?,
                           onReward: ((Int) -> Void)?,
                           onError: ((Error) -> Void)?,
                           wasReady: (Bool) -> Void)
    func removeBanner()
    func disable()
}
