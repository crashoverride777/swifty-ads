//
//  SwiftyAd+Banner.swift
//  SwiftyAdExample
//
//  Created by Dominik Ringler on 23/05/2019.
//  Copyright © 2019 Dominik. All rights reserved.
//

import GoogleMobileAds

// MARK: - Load

extension SwiftyAd {
    
    func loadBannerAd(from viewController: UIViewController) {
        guard !isRemoved, hasConsent else { return }
        
        // Remove old banners
        removeBanner()
        
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
        let request = makeRequest()
        bannerAdView.load(request)
    }
}

// MARK: - GADBannerViewDelegate

extension SwiftyAd: GADBannerViewDelegate {
    
    public func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        print("AdMob banner did receive ad from: \(bannerView.adNetworkClassName ?? "")")
        animateBannerToOnScreenPosition(bannerView, from: bannerView.rootViewController)
    }
    
    public func adViewWillPresentScreen(_ bannerView: GADBannerView) {
        delegate?.swiftyAdDidOpen(self)
    }
    
    public func adViewWillLeaveApplication(_ bannerView: GADBannerView) {
        delegate?.swiftyAdDidOpen(self)
    }
    
    public func adViewWillDismissScreen(_ bannerView: GADBannerView) {
        
    }
    
    public func adViewDidDismissScreen(_ bannerView: GADBannerView) {
        delegate?.swiftyAdDidClose(self)
    }
    
    public func adView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: GADRequestError) {
        print(error.localizedDescription)
        animateBannerToOffScreenPosition(bannerView, from: bannerView.rootViewController)
    }
}

// MARK: - Private

private extension SwiftyAd {
    
    func animateBannerToOnScreenPosition(_ bannerAd: GADBannerView, from viewController: UIViewController?) {
        bannerAd.isHidden = false
        bannerViewConstraint?.constant = 0
        
        UIView.animate(withDuration: bannerAnimationDuration) {
            viewController?.view.layoutIfNeeded()
        }
    }
    
    func animateBannerToOffScreenPosition(_ bannerAd: GADBannerView, from viewController: UIViewController?, withAnimation: Bool = true) {
        bannerViewConstraint?.constant = 0 + (bannerAd.frame.height * 3) // *3 due to iPhoneX safe area
        
        guard withAnimation else {
            bannerAd.isHidden = true
            return
        }
        
        UIView.animate(withDuration: bannerAnimationDuration, animations: {
            viewController?.view.layoutIfNeeded()
        }, completion: { isSuccess in
            bannerAd.isHidden = true
        })
    }
}
