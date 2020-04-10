//
//  GameViewController.swift
//  Example
//
//  Created by Dominik Ringler on 23/05/2019.
//  Copyright © 2019 Dominik. All rights reserved.
//

import UIKit
import SpriteKit

class GameViewController: UIViewController {
    
    private let swiftyAds: SwiftyAdsType = SwiftyAds.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSwiftyAds()
        
        if let scene = GameScene(fileNamed: "GameScene") {
            scene.configure(swiftyAds: swiftyAds)
            
            // Configure the view.
            let skView = self.view as! SKView
            skView.showsFPS = true
            skView.showsNodeCount = true
            
            /* Sprite Kit applies additional optimizations to improve rendering performance */
            skView.ignoresSiblingOrder = true
            
            /* Set the scale mode to scale to fit the window */
            scene.scaleMode = .aspectFill
            
            skView.presentScene(scene)
        }
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { _ in
            self.swiftyAds.updateBannerForOrientationChange(isLandscape: size.width > size.height)
        })
    }
}

// MARK: - Private Methods

private extension GameViewController {
    
    func setupSwiftyAds() {
        #if DEBUG
        let mode: SwiftyAdsMode = .debug(testDeviceIdentifiers: [])
        #else
        let mode: SwiftyAdsMode = .production
        #endif
        let customConsentContent = SwiftyAdsCustomConsentAlertContent(
            title: "Permission to use data",
            message: "We care about your privacy and data security. We keep this app free by showing ads. You can change your choice anytime in the app settings. Our partners will collect data and use a unique identifier on your device to show you ads.",
            actionAllowPersonalized: "Allow personalized",
            actionAllowNonPersonalized: "Allow non personalized",
            actionAdFree: nil
        )
        
        swiftyAds.setup(
            with: self,
            mode: mode,
            consentStyle: .custom(content: customConsentContent),
            consentStatusDidChange: ({ consentStatus in
                print("SwiftyAds did change consent status to \(consentStatus)")
                let skView = self.view as? SKView
                (skView?.scene as? GameScene)?.refresh()
                
                if consentStatus != .notRequired {
                    // update mediation networks if required
                }
            }),
            completion: ({ status in
                guard status.hasConsent else { return }
                DispatchQueue.main.async {
                    self.showBanner()
                }
            })
        )
    }
    
    func showBanner() {
        swiftyAds.showBanner(
            from: self,
            atTop: false,
            ignoresSafeArea: false,
            animationDuration: 1.5,
            onOpen: ({
                print("SwiftyAds banner ad did open")
            }),
            onClose: ({
                print("SwiftyAds banner ad did close")
            }),
            onError: ({ error in
                print("SwiftyAds banner ad error \(error)")
            })
        )
    }
}
