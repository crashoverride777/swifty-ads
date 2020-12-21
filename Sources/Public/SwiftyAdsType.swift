//    The MIT License (MIT)
//
//    Copyright (c) 2015-2020 Dominik Ringler
//
//    Permission is hereby granted, free of charge, to any person obtaining a copy
//    of this software and associated documentation files (the "Software"), to deal
//    in the Software without restriction, including without limitation the rights
//    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//    copies of the Software, and to permit persons to whom the Software is
//    furnished to do so, subject to the following conditions:
//
//    The above copyright notice and this permission notice shall be included in all
//    copies or substantial portions of the Software.
//
//    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//    SOFTWARE.

import UIKit
import GoogleMobileAds

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
    func loadNativeAd(from viewController: UIViewController,
                      count: Int?,
                      onReceive: @escaping (GADUnifiedNativeAd) -> Void,
                      onError: @escaping (Error) -> Void)
    func disable()
}
