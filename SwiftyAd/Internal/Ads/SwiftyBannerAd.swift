//
//  SwiftyAd+Banner.swift
//  SwiftyAdExample
//
//  Created by Dominik Ringler on 23/05/2019.
//  Copyright © 2019 Dominik. All rights reserved.
//

import GoogleMobileAds
#warning("use closures?")
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
    
    private let adUnitId: String
    private let request: () -> GADRequest
    private unowned let delegate: SwiftyBannerAdDelegate
    private var animationDuration: TimeInterval
    
    private var bannerView: GADBannerView?
    private var bannerViewConstraint: NSLayoutConstraint?
    
    // MARK: - Init
    
    init(adUnitId: String,
         request: @escaping () -> GADRequest,
         delegate: SwiftyBannerAdDelegate,
         bannerAnimationDuration: TimeInterval,
         notificationCenter: NotificationCenter) {
        self.adUnitId = adUnitId
        self.request = request
        self.delegate = delegate
        self.animationDuration = bannerAnimationDuration
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
    
    func show(from viewController: UIViewController) {
        // Remove old banners
        remove()
        
        // Create ad
        bannerView = GADBannerView()
        deviceRotated() // to set banner size
        
        guard let bannerAdView = bannerView else { return }
        
        bannerAdView.adUnitID = adUnitId
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
        bannerAdView.load(request())
    }
    
    func remove() {
        bannerView?.delegate = nil
        bannerView?.removeFromSuperview()
        bannerView = nil
        bannerViewConstraint = nil
    }
    
    func updateAnimationDuration(to duration: TimeInterval) {
        self.animationDuration = duration
    }
}

// MARK: - GADBannerViewDelegate

extension SwiftyBannerAd: GADBannerViewDelegate {
    
    func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        print("AdMob banner did receive ad from: \(bannerView.responseInfo?.adNetworkClassName ?? "")")
        animateBannerToOnScreenPosition(bannerView, from: bannerView.rootViewController)
    }
    
    func adViewWillPresentScreen(_ bannerView: GADBannerView) {
        delegate.swiftyBannerAdDidOpen(self)
    }
    
    func adViewWillLeaveApplication(_ bannerView: GADBannerView) {
        delegate.swiftyBannerAdDidOpen(self)
    }
    
    func adViewWillDismissScreen(_ bannerView: GADBannerView) {
        
    }
    
    func adViewDidDismissScreen(_ bannerView: GADBannerView) {
        delegate.swiftyBannerAdDidClose(self)
    }
    
    func adView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: GADRequestError) {
        print(error.localizedDescription)
        animateBannerToOffScreenPosition(bannerView, from: bannerView.rootViewController)
    }
}

// MARK: - Private Methods

private extension SwiftyBannerAd {
    
    @objc func deviceRotated() {
        bannerView?.adSize = UIDevice.current.orientation.isLandscape ? kGADAdSizeSmartBannerLandscape : kGADAdSizeSmartBannerPortrait
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
