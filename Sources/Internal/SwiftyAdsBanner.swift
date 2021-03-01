//    The MIT License (MIT)
//
//    Copyright (c) 2015-2021 Dominik Ringler
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

final class SwiftyAdsBanner: NSObject {

    // MARK: - Types

    private enum Configuration {
        static let visibleConstant: CGFloat = 0
        static let hiddenConstant: CGFloat = 400
    }
    
    // MARK: - Properties

    private let environment: SwiftyAdsEnvironment
    private let isDisabled: () -> Bool
    private let hasConsent: () -> Bool
    private let request: () -> GADRequest

    private var onOpen: (() -> Void)?
    private var onClose: (() -> Void)?
    private var onError: ((Error) -> Void)?
    private var onWillPresentScreen: (() -> Void)?
    private var onWillDismissScreen: (() -> Void)?
    private var onDidDismissScreen: (() -> Void)?

    private var bannerView: GADBannerView?
    private var position: SwiftyAdsBannerAdPosition = .bottom(isUsingSafeArea: true)
    private var animation: SwiftyAdsBannerAdAnimation = .none
    private var bannerViewConstraint: NSLayoutConstraint?
    private var animator: UIViewPropertyAnimator?
    
    // MARK: - Initialization
    
    init(environment: SwiftyAdsEnvironment,
         isDisabled: @escaping () -> Bool,
         hasConsent: @escaping () -> Bool,
         request: @escaping () -> GADRequest) {
        self.environment = environment
        self.isDisabled = isDisabled
        self.hasConsent = hasConsent
        self.request = request
        super.init()
    }

    // MARK: - Methods
    
    func prepare(withAdUnitId adUnitId: String,
                 in viewController: UIViewController,
                 position: SwiftyAdsBannerAdPosition,
                 animation: SwiftyAdsBannerAdAnimation,
                 onOpen: (() -> Void)?,
                 onClose: (() -> Void)?,
                 onError: ((Error) -> Void)?,
                 onWillPresentScreen: (() -> Void)?,
                 onWillDismissScreen: (() -> Void)?,
                 onDidDismissScreen: (() -> Void)?) {
        self.position = position
        self.animation = animation
        self.onOpen = onOpen
        self.onClose = onClose
        self.onError = onError
        self.onWillPresentScreen = onWillPresentScreen
        self.onWillDismissScreen = onWillDismissScreen
        self.onDidDismissScreen = onDidDismissScreen
        
        // Create banner view
        let bannerView = GADBannerView()
        
        // Keep reference to created banner view
        self.bannerView = bannerView

        // Set ad unit id
        bannerView.adUnitID = adUnitId

        // Set the root view controller that will display the banner view
        bannerView.rootViewController = viewController

        // Set the banner view delegate
        bannerView.delegate = self

        // Add banner view to view controller
        add(bannerView, to: viewController)

        // Hide banner without animation
        hide(bannerView, from: viewController, skipAnimation: true)
    }
}

// MARK: - SwiftyAdsBannerType

extension SwiftyAdsBanner: SwiftyAdsBannerType {

    func show(isLandscape: Bool) {
        guard !isDisabled() else { return }
        guard hasConsent() else { return }
        guard let bannerView = bannerView else { return }
        guard let currentView = bannerView.rootViewController?.view else { return }

        // Determine the view width to use for the ad width.
        let frame = { () -> CGRect in
            switch position {
            case .top(let isUsingSafeArea), .bottom(let isUsingSafeArea):
                if isUsingSafeArea {
                    return currentView.frame.inset(by: currentView.safeAreaInsets)
                } else {
                    return currentView.frame
                }
            }
        }()

        // Get Adaptive GADAdSize and set the ad view.
        if isLandscape {
            bannerView.adSize = GADLandscapeAnchoredAdaptiveBannerAdSizeWithWidth(frame.size.width)
        } else {
            bannerView.adSize = GADPortraitAnchoredAdaptiveBannerAdSizeWithWidth(frame.size.width)
        }

        // Create an ad request and load the adaptive banner ad.
        bannerView.load(request())
    }

    func hide() {
        guard let bannerView = bannerView else { return }
        guard let rootViewController = bannerView.rootViewController else { return }
        hide(bannerView, from: rootViewController)
    }
    
    func remove() {
        guard bannerView != nil else { return }
        
        bannerView?.delegate = nil
        bannerView?.removeFromSuperview()
        bannerView = nil
        bannerViewConstraint = nil
        onClose?()
    }
}

// MARK: - GADBannerViewDelegate

extension SwiftyAdsBanner: GADBannerViewDelegate {

    // Request lifecycle events
    func bannerViewDidRecordImpression(_ bannerView: GADBannerView) {
        if case .debug = environment {
            print("SwiftyAdsBanner did record impression for banner ad")
        }
    }
    
    func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
        show(bannerView, from: bannerView.rootViewController)
        if case .debug = environment {
            print("SwiftyAdsBanner did receive ad from: \(bannerView.responseInfo?.adNetworkClassName ?? "not found")")
        }
    }

    func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
        hide(bannerView, from: bannerView.rootViewController)
        onError?(error)
    }

    // Click-Time lifecycle events
    func bannerViewWillPresentScreen(_ bannerView: GADBannerView) {
        onWillPresentScreen?()
    }

    func bannerViewWillDismissScreen(_ bannerView: GADBannerView) {
        onWillDismissScreen?()
    }

    func bannerViewDidDismissScreen(_ bannerView: GADBannerView) {
        onDidDismissScreen?()
    }
}

// MARK: - Private Methods

private extension SwiftyAdsBanner {

    func add(_ bannerView: GADBannerView, to viewController: UIViewController) {
        // Add banner view to view controller
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        viewController.view.addSubview(bannerView)

        // Add constraints
        // We don't give the banner a width or height constraint, as the provided ad size will give the banner
        // an intrinsic content size
        switch position {
        case .top(let isUsingSafeArea):
            if isUsingSafeArea {
                bannerViewConstraint = bannerView.topAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.topAnchor)
            } else {
                bannerViewConstraint = bannerView.topAnchor.constraint(equalTo: viewController.view.topAnchor)
            }

        case .bottom(let isUsingSafeArea):
            if let tabBarController = viewController as? UITabBarController {
                bannerViewConstraint = bannerView.bottomAnchor.constraint(equalTo: tabBarController.tabBar.topAnchor)
            } else {
                if isUsingSafeArea {
                    bannerViewConstraint = bannerView.bottomAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.bottomAnchor)
                } else {
                    bannerViewConstraint = bannerView.bottomAnchor.constraint(equalTo: viewController.view.bottomAnchor)
                }
            }
        }

        // Activate constraints
        NSLayoutConstraint.activate([
            bannerView.centerXAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.centerXAnchor),
            bannerViewConstraint
        ].compactMap { $0 })
    }

    func show(_ bannerAd: GADBannerView, from viewController: UIViewController?) {
        // Stop current animations
        stopCurrentAnimatorAnimations()

        // Show banner incase it was hidden
        bannerAd.isHidden = false

        // Animate if needed
        switch animation {
        case .none:
            animator = nil
        case .fade(let duration):
            animator = UIViewPropertyAnimator(duration: duration, curve: .easeOut) { [weak bannerView] in
                bannerView?.alpha = 1
            }
        case .slide(let duration):
            /// We can only animate the banner to its on-screen position with a valid view controller
            guard let viewController = viewController else { return }

            /// We can only animate the banner to its on-screen position if it has a constraint
            guard let bannerViewConstraint = bannerViewConstraint else { return }

            /// We can only animate the banner to its on-screen position if its not already visible
            guard bannerViewConstraint.constant != Configuration.visibleConstant else { return }

            /// Set banner constraint
            bannerViewConstraint.constant = Configuration.visibleConstant

            /// Animate constraint changes
            animator = UIViewPropertyAnimator(duration: duration, curve: .easeOut) {
                viewController.view.layoutIfNeeded()
            }
        }

        // Add animation completion if needed
        animator?.addCompletion { [weak self] _ in
            self?.onOpen?()
        }

        // Start animation if needed
        animator?.startAnimation()
    }
    
    func hide(_ bannerAd: GADBannerView, from viewController: UIViewController?, skipAnimation: Bool = false) {
        // Stop current animations
        stopCurrentAnimatorAnimations()

        // Animate if needed
        switch animation {
        case .none:
            animator = nil
            bannerAd.isHidden = true
        case .fade(let duration):
            if skipAnimation {
                bannerView?.alpha = 0
            } else {
                animator = UIViewPropertyAnimator(duration: duration, curve: .easeOut) { [weak bannerView] in
                    bannerView?.alpha = 0
                }
            }
        case .slide(let duration):
            /// We can only animate the banner to its off-screen position with a valid view controller
            guard let viewController = viewController else { return }

            /// We can only animate the banner to its off-screen position if it has a constraint
            guard let bannerViewConstraint = bannerViewConstraint else { return }

            /// We can only animate the banner to its off-screen position if its already visible
            guard bannerViewConstraint.constant == Configuration.visibleConstant else { return }

            /// Get banner off-screen constant
            var newConstant: CGFloat {
                switch position {
                case .top:
                    return -Configuration.hiddenConstant
                case .bottom:
                    return Configuration.hiddenConstant
                }
            }

            /// Set banner constraint
            bannerViewConstraint.constant = newConstant

            /// Animate constraint changes
            if !skipAnimation {
                animator = UIViewPropertyAnimator(duration: duration, curve: .easeOut) {
                    viewController.view.layoutIfNeeded()
                }
            }
        }

        // Add animation completion if needed
        animator?.addCompletion { [weak self, weak bannerAd] _ in
            bannerAd?.isHidden = true
            self?.onClose?()
        }

        // Start animation if needed
        animator?.startAnimation()
    }

    func stopCurrentAnimatorAnimations() {
        animator?.stopAnimation(false)
        animator?.finishAnimation(at: .current)
    }
}

// MARK: - Deprecated

extension SwiftyAdsBanner {

    @available(*, deprecated, message: "Please use new hide method without animated parameter")
    func hide(animated: Bool) {
        hide()
    }
}
