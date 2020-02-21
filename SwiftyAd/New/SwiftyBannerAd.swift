//
//  SwiftyAd+Banner.swift
//  SwiftyAdExample
//
//  Created by Dominik Ringler on 23/05/2019.
//  Copyright © 2019 Dominik. All rights reserved.
//

import GoogleMobileAds

protocol SwiftyBannerAdDelegate: AnyObject {
    func swiftyBannerAdDidOpen(_ bannerAd: SwiftyBannerAd)
    func swiftyBannerAdDidClose(_ bannerAd: SwiftyBannerAd)
}

protocol SwiftyBannerAdType: AnyObject {
    func show(from viewController: UIViewController)
    func remove()
    func updateAnimationDuration(to duration: TimeInterval)
}

final class SwiftyBannerAd: NSObject {
    
    // MARK: - Properties
    
    private let configuration: AdConfiguration
    private let requestBuilder: GADRequestBuilderType
    private unowned let delegate: SwiftyBannerAdDelegate
    private var animationDuration: TimeInterval
    
    private let isRemoved: () -> Bool
    private let hasConsent: () -> Bool
    
    private var bannerAdView: GADBannerView?
    private var bannerViewConstraint: NSLayoutConstraint?
    
    // MARK: - Init
    
    init(configuration: AdConfiguration,
         requestBuilder: GADRequestBuilderType,
         delegate: SwiftyBannerAdDelegate,
         bannerAnimationDuration: TimeInterval,
         notificationCenter: NotificationCenter,
         isRemoved: @escaping () -> Bool,
         hasConsent: @escaping () -> Bool) {
        self.configuration = configuration
        self.requestBuilder = requestBuilder
        self.delegate = delegate
        self.animationDuration = bannerAnimationDuration
        self.isRemoved = isRemoved
        self.hasConsent = hasConsent
        super.init()
        
        notificationCenter.addObserver(
            self,
            selector: #selector(deviceRotated),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
    }
}
 
// MARK: - SwiftyBannerAdType

extension SwiftyBannerAd: SwiftyBannerAdType {
    
    /// Show banner ad
    ///
    /// - parameter viewController: The view controller that will present the ad.
    func show(from viewController: UIViewController) {
        guard !isRemoved(), hasConsent() else { return }
        
        // Remove old banners
        remove()
        
        // Create ad
        bannerAdView = GADBannerView()
        deviceRotated() // to set banner size
        
        guard let bannerAdView = bannerAdView else { return }
        
        bannerAdView.adUnitID = configuration.bannerAdUnitId
        bannerAdView.delegate = self
        bannerAdView.rootViewController = viewController
        viewController.view.addSubview(bannerAdView)
        
        // Add constraints
        let layoutGuide: UILayoutGuide
        if #available(iOS 11, *) {
            layoutGuide = viewController.view.safeAreaLayoutGuide
        } else {
            layoutGuide = viewController.view.layoutMarginsGuide
        }
        
        bannerAdView.translatesAutoresizingMaskIntoConstraints = false
        bannerViewConstraint = bannerAdView.bottomAnchor.constraint(equalTo: layoutGuide.bottomAnchor)
        NSLayoutConstraint.activate([
            bannerAdView.leftAnchor.constraint(equalTo: layoutGuide.leftAnchor),
            bannerAdView.rightAnchor.constraint(equalTo: layoutGuide.rightAnchor),
            bannerViewConstraint!
        ])
       
        // Move off screen
        animateBannerToOffScreenPosition(bannerAdView, from: viewController, withAnimation: false)
        
        // Request ad
        let request = requestBuilder.build()
        bannerAdView.load(request)
    }
    
    /// Remove banner ads
    public func remove() {
        bannerAdView?.delegate = nil
        bannerAdView?.removeFromSuperview()
        bannerAdView = nil
        bannerViewConstraint = nil
    }
    
    /// Update banner animation duration
    func updateAnimationDuration(to duration: TimeInterval) {
        self.animationDuration = duration
    }
}

// MARK: - GADBannerViewDelegate

extension SwiftyBannerAd: GADBannerViewDelegate {
    
    public func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        print("AdMob banner did receive ad from: \(bannerView.adNetworkClassName ?? "")")
        animateBannerToOnScreenPosition(bannerView, from: bannerView.rootViewController)
    }
    
    public func adViewWillPresentScreen(_ bannerView: GADBannerView) {
        delegate.swiftyBannerAdDidOpen(self)
    }
    
    public func adViewWillLeaveApplication(_ bannerView: GADBannerView) {
        delegate.swiftyBannerAdDidOpen(self)
    }
    
    public func adViewWillDismissScreen(_ bannerView: GADBannerView) {
        
    }
    
    public func adViewDidDismissScreen(_ bannerView: GADBannerView) {
        delegate.swiftyBannerAdDidClose(self)
    }
    
    public func adView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: GADRequestError) {
        print(error.localizedDescription)
        animateBannerToOffScreenPosition(bannerView, from: bannerView.rootViewController)
    }
}

// MARK: - Private Methods

private extension SwiftyBannerAd {
    
    @objc func deviceRotated() {
        bannerAdView?.adSize = UIDevice.current.orientation.isLandscape ? kGADAdSizeSmartBannerLandscape : kGADAdSizeSmartBannerPortrait
    }
    
    func animateBannerToOnScreenPosition(_ bannerAd: GADBannerView, from viewController: UIViewController?) {
        bannerAd.isHidden = false
        bannerViewConstraint?.constant = 0
        
        UIView.animate(withDuration: animationDuration) {
            viewController?.view.layoutIfNeeded()
        }
    }
    
    func animateBannerToOffScreenPosition(_ bannerAd: GADBannerView, from viewController: UIViewController?, withAnimation: Bool = true) {
        bannerViewConstraint?.constant = 0 + (bannerAd.frame.height * 3) // *3 due to iPhoneX safe area
        
        guard withAnimation else {
            bannerAd.isHidden = true
            return
        }
        
        UIView.animate(withDuration: animationDuration, animations: {
            viewController?.view.layoutIfNeeded()
        }, completion: { isSuccess in
            bannerAd.isHidden = true
        })
    }
}
