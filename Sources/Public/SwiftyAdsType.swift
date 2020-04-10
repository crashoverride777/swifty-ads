//
//  SwiftyAdsType.swift
//  SwiftyAdsDemo
//
//  Created by Dominik Ringler on 29/02/2020.
//  Copyright © 2020 Dominik Ringler. All rights reserved.
//

import UIKit

public protocol SwiftyAdsType: AnyObject {
    var hasConsent: Bool { get }
    var isRequiredToAskForConsent: Bool { get }
    var isInterstitialReady: Bool { get }
    var isRewardedVideoReady: Bool { get }
    func setup(with viewController: UIViewController,
               mode: SwiftyAdsMode,
               consentStyle: SwiftyAdsConsentStyle,
               consentStatusDidChange: @escaping (SwiftyAdsConsentStatus) -> Void,
               completion: @escaping (SwiftyAdsConsentStatus) -> Void)
    func askForConsent(from viewController: UIViewController)
    func showBanner(from viewController: UIViewController,
                    atTop isAtTop: Bool,
                    ignoresSafeArea: Bool,
                    animationDuration: TimeInterval,
                    onOpen: (() -> Void)?,
                    onClose: (() -> Void)?,
                    onError: ((Error) -> Void)?)
    func updateBannerForOrientationChange(isLandscape: Bool)
    func removeBanner()
    func showInterstitial(from viewController: UIViewController,
                          withInterval interval: Int?,
                          onOpen: (() -> Void)?,
                          onClose: (() -> Void)?,
                          onError: ((Error) -> Void)?)
    func showRewardedVideo(from viewController: UIViewController,
                           onOpen: (() -> Void)?,
                           onClose: (() -> Void)?,
                           onError: ((Error) -> Void)?,
                           onNotReady: (() -> Void)?,
                           onReward: @escaping (Int) -> Void)
    func disable()
}
