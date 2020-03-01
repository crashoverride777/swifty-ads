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
              isLandscape: Bool,
              animationDuration: TimeInterval,
              onOpen: (() -> Void)?,
              onClose: (() -> Void)?,
              onError: ((Error) -> Void)?)
    func remove()
    func refresh(isLandscape: Bool)
}

final class SwiftyAdsBanner: NSObject {
    
    // MARK: - Properties
    
    private let adUnitId: String
    private let request: () -> GADRequest
    private var onOpen: (() -> Void)?
    private var onClose: (() -> Void)?
    private var onError: ((Error) -> Void)?
    
    private var bannerView: GADBannerView?
    private var position: SwiftyAdsBannerPositition = .bottom
    private var animationDuration: TimeInterval = 1.4
    private var bannerViewConstraint: NSLayoutConstraint?
    private var animator: UIViewPropertyAnimator?
    private var currentView: UIView?
    
    // MARK: - Computed Properties
    
    private var currentViewWidth: CGFloat {
        guard let currentView = currentView else { return 200 }
        return currentView.frame.inset(by: currentView.safeAreaInsets).size.width
    }
    
    // MARK: - Init
    
    init(adUnitId: String, request: @escaping () -> GADRequest) {
        self.adUnitId = adUnitId
        self.request = request
        super.init()
    }
}
 
// MARK: - SwiftyAdBannerType

extension SwiftyAdsBanner: SwiftyAdsBannerType {
    
    func show(from viewController: UIViewController,
              at position: SwiftyAdsBannerPositition,
              isLandscape: Bool,
              animationDuration: TimeInterval,
              onOpen: (() -> Void)?,
              onClose: (() -> Void)?,
              onError: ((Error) -> Void)?) {
        self.position = position
        self.animationDuration = animationDuration
        self.onOpen = onOpen
        self.onClose = onClose
        self.onError = onError
        
        // Remove old banners if needed
        remove()
        
        // Update current view reference
        currentView = viewController.view
        
        // Create new banner ad
        bannerView = GADBannerView()
        
        guard let bannerView = bannerView else {
            return
        }
         
        bannerView.adUnitID = adUnitId
        bannerView.delegate = self
        bannerView.rootViewController = viewController
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        viewController.view.addSubview(bannerView)
         
        // Add constraints
        // We don't give the banner a width or height constraints, as the provided ad size will give the banner
        // an intrinsic content size to size the view.
        let layoutGuide = viewController.view.safeAreaLayoutGuide
        switch position {
        case .top:
            bannerViewConstraint = bannerView.topAnchor.constraint(equalTo: layoutGuide.topAnchor)
        case .bottom:
            bannerViewConstraint = bannerView.bottomAnchor.constraint(equalTo: layoutGuide.bottomAnchor)
        }
         
        NSLayoutConstraint.activate([
            bannerView.centerXAnchor.constraint(equalTo: layoutGuide.centerXAnchor),
            bannerViewConstraint!
        ])
        
        // Refresh the banner
        refresh(isLandscape: isLandscape)
        
        // Move off screen
        animateToOffScreenPosition(bannerView, from: viewController, position: position, animated: false)
    }
    
    func remove() {
        guard bannerView != nil else {
            return
        }
        
        bannerView?.delegate = nil
        bannerView?.removeFromSuperview()
        bannerView = nil
        bannerViewConstraint = nil
        currentView = nil
        onClose?()
    }
    
    func refresh(isLandscape: Bool) {
        guard let bannerView = bannerView else {
            return
        }

        if isLandscape {
            bannerView.adSize = GADLandscapeAnchoredAdaptiveBannerAdSizeWithWidth(currentViewWidth)
        } else {
            bannerView.adSize = GADPortraitAnchoredAdaptiveBannerAdSizeWithWidth(currentViewWidth)
        }
        
        // Create an ad request and load the adaptive banner ad.
        bannerView.load(request())
    }
}

// MARK: - GADBannerViewDelegate

extension SwiftyAdsBanner: GADBannerViewDelegate {
    
    func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        print("SwiftyAdsBanner did receive ad from: \(bannerView.responseInfo?.adNetworkClassName ?? "")")
        animateToOnScreenPosition(bannerView, from: bannerView.rootViewController)
    }
    
    func adView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: GADRequestError) {
        print("SwiftyAdsBanner didFailToReceiveAdWithError \(error)")
        animateToOffScreenPosition(bannerView, from: bannerView.rootViewController, position: position)
        onError?(error)
    }
}

// MARK: - Private Methods

private extension SwiftyAdsBanner {
    
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
            newConstant = 0 - (bannerAd.adSize.size.height * 3) // *3 due to iPhoneX safe area
        case .bottom:
            newConstant = 0 + (bannerAd.adSize.size.height * 3) // *3 due to iPhoneX safe area
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
