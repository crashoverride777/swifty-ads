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
        
        // Setup swifty ad
        setupSwiftyAds()
        
        // Load game scene
        if let scene = GameScene(fileNamed: "GameScene") {
            scene.swiftyAds = swiftyAds
            
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
}

// MARK: - Private Methods

private extension GameViewController {
    
    func setupSwiftyAds() {
        #if DEBUG
        let mode: SwiftyAdsMode = .test(devices: [])
        #else
        let mode: SwiftyAdsMode = .production
        #endif
        let customConsentContent = SwiftyAdsCustomConsentAlertContent(
            title: "Permission to use data",
            message: "We care about your privacy and data security. We keep this app free by showing ads. You can change your choice anytime in the app settings. Our partners will collect data and use a unique identifier on your device to show you ads.",
            actionAdFree: nil,
            actionAllowPersonalized: "Allow personalized",
            actionAllowNonPersonalized: "Allow non personalized"
        )
        
        swiftyAds.setup(
            with: self,
            mode: mode,
            consentStyle: .custom(customConsentContent),
            consentStatusDidChange: ({ consentStatus in
                print("SwiftyAds did change consent status to \(consentStatus)")
                // e.g update mediation networks
            }),
            handler: ({ status in
                guard status.hasConsent else { return }
                DispatchQueue.main.async {
                    self.swiftyAds.showBanner(
                        from: self,
                        atTop: false,
                        animationDuration: 1.5,
                        onOpen: nil,
                        onClose: nil,
                        onError: nil
                    )
                }
            })
        )
    }
}
