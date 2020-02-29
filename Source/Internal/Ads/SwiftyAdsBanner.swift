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

import GoogleMobileAds

enum SwiftyAdsBannerPositition {
    case top
    case bottom
}

protocol SwiftyAdsBannerType: AnyObject {
    func show(from viewController: UIViewController,
              at position: SwiftyAdsBannerPositition,
              animationDuration: TimeInterval,
              onOpen: @escaping () -> Void,
              onClose: @escaping () -> Void,
              onError: @escaping (Error) -> Void)
    func remove()
}

final class SwiftyAdsBanner: NSObject {
    
    // MARK: - Properties
    
    private let adUnitId: String
    private let isLandscape: () -> Bool
    private let request: () -> GADRequest
    private var onOpen: (() -> Void)?
    private var onClose: (() -> Void)?
    private var onError: ((Error) -> Void)?
    
    private var bannerView: GADBannerView?
    private var position: SwiftyAdsBannerPositition = .bottom
    private var animationDuration: TimeInterval = 1.4
    private var bannerViewConstraint: NSLayoutConstraint?
    private var animator: UIViewPropertyAnimator?
    
    // MARK: - Init
    
    init(adUnitId: String,
         notificationCenter: NotificationCenter,
         isLandscape: @escaping () -> Bool,
         request: @escaping () -> GADRequest) {
        self.adUnitId = adUnitId
        self.isLandscape = isLandscape
        self.request = request
        super.init()
        
        notificationCenter.addObserver(
            self,
            selector: #selector(updateSize),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
    }
}
 
// MARK: - SwiftyAdBannerType

extension SwiftyAdsBanner: SwiftyAdsBannerType {
    
    func show(from viewController: UIViewController,
              at position: SwiftyAdsBannerPositition,
              animationDuration: TimeInterval,
              onOpen: @escaping () -> Void,
              onClose: @escaping () -> Void,
              onError: @escaping (Error) -> Void) {
        self.position = position
        self.animationDuration = animationDuration
        self.onOpen = onOpen
        self.onClose = onClose
        self.onError = onError
        
        // Remove old banners
        remove()
        
        // Create ad
        bannerView = GADBannerView()
        updateSize() // to set banner size
        
        guard let bannerAdView = bannerView else {
            return
        }
        
        bannerAdView.adUnitID = adUnitId
        bannerAdView.delegate = self
        bannerAdView.rootViewController = viewController
        viewController.view.addSubview(bannerAdView)
        
        // Add constraints
        let layoutGuide = viewController.view.safeAreaLayoutGuide
        bannerAdView.translatesAutoresizingMaskIntoConstraints = false
        
        switch position {
        case .top:
            bannerViewConstraint = bannerAdView.topAnchor.constraint(equalTo: layoutGuide.topAnchor)
        case .bottom:
            bannerViewConstraint = bannerAdView.bottomAnchor.constraint(equalTo: layoutGuide.bottomAnchor)
        }
        
        NSLayoutConstraint.activate([
            bannerAdView.leftAnchor.constraint(equalTo: layoutGuide.leftAnchor),
            bannerAdView.rightAnchor.constraint(equalTo: layoutGuide.rightAnchor),
            bannerViewConstraint!
        ])
       
        // Move off screen
        animateToOffScreenPosition(bannerAdView, from: viewController, position: position, animated: false)
        
        // Request ad
        bannerAdView.load(request())
    }
    
    func remove() {
        guard bannerView != nil else {
            return
        }
        
        bannerView?.delegate = nil
        bannerView?.removeFromSuperview()
        bannerView = nil
        bannerViewConstraint = nil
        onClose?()
    }
}

// MARK: - GADBannerViewDelegate

extension SwiftyAdsBanner: GADBannerViewDelegate {
    
    func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        print("SwiftyAdsBanner did receive ad from: \(bannerView.responseInfo?.adNetworkClassName ?? "")")
        animateToOnScreenPosition(bannerView, from: bannerView.rootViewController)
    }
    
    func adViewWillPresentScreen(_ bannerView: GADBannerView) {
        // not firing as expected
    }
    
    func adViewWillLeaveApplication(_ bannerView: GADBannerView) {
   
    }
    
    func adViewWillDismissScreen(_ bannerView: GADBannerView) {
        
    }
    
    func adViewDidDismissScreen(_ bannerView: GADBannerView) {
        // not firing as expected
    }
    
    func adView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: GADRequestError) {
        print("SwiftyAdsBanner didFailToReceiveAdWithError \(error)")
        animateToOffScreenPosition(bannerView, from: bannerView.rootViewController, position: position)
        onError?(error)
    }
}

// MARK: - Private Methods

private extension SwiftyAdsBanner {
    
    @objc func updateSize() {
        bannerView?.adSize = isLandscape() ? kGADAdSizeSmartBannerLandscape : kGADAdSizeSmartBannerPortrait
    }
    
    func animateToOnScreenPosition(_ bannerAd: GADBannerView,
                                   from viewController: UIViewController?,
                                   completion: (() -> Void)? = nil) {
        guard let viewController = viewController else {
            return
        }
        
        guard let bannerViewConstraint = bannerViewConstraint, bannerViewConstraint.constant > 0 else {
            return
        }
        
        bannerAd.isHidden = false
        bannerViewConstraint.constant = 0
        
        stopCurrentAnimatorAnimations()
        animator = UIViewPropertyAnimator(duration: animationDuration, curve: .easeOut) {
            viewController.view.layoutIfNeeded()
        }
        
        animator?.addCompletion { [weak self] _ in
            guard let self = self else { return }
            self.onOpen?()
            completion?()
        }

        animator?.startAnimation()
    }
    
    func animateToOffScreenPosition(_ bannerAd: GADBannerView,
                                    from viewController: UIViewController?,
                                    position: SwiftyAdsBannerPositition,
                                    animated: Bool = true,
                                    completion: (() -> Void)? = nil) {
        guard let viewController = viewController else {
            return
        }
        
        let newConstant: CGFloat
        
        switch position {
        case .top:
            newConstant = 0 - (bannerAd.frame.height * 3) // *3 due to iPhoneX safe area
        case .bottom:
            newConstant = 0 + (bannerAd.frame.height * 3) // *3 due to iPhoneX safe area
        }
        
        guard let bannerViewConstraint = bannerViewConstraint, bannerViewConstraint.constant != newConstant else {
            return
        }
             
        guard animated else {
            bannerAd.isHidden = true
            bannerViewConstraint.constant = newConstant
            return
        }
        
        bannerViewConstraint.constant = newConstant
        stopCurrentAnimatorAnimations()
        animator = UIViewPropertyAnimator(duration: animationDuration, curve: .easeOut) {
            viewController.view.layoutIfNeeded()
        }
        
        animator?.addCompletion { [weak self] _ in
            guard let self = self else { return }
            bannerAd.isHidden = true
            self.onClose?()
            completion?()
        }
        
        animator?.startAnimation()
    }

    func stopCurrentAnimatorAnimations() {
        animator?.stopAnimation(false)
        animator?.finishAnimation(at: .current)
    }
}
