//
//  GameViewController.swift
//  SwiftyAds
//
//  Created by Dominik on 04/09/2015.


import UIKit
import SpriteKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
     
        // Set up ad Mob
        let adUnitId = SwiftyAd.AdUnitId(
            banner:        "ca-app-pub-2427795328331194/7041316660",
            interstitial:  "ca-app-pub-2427795328331194/8518049864",
            rewardedVideo: "ca-app-pub-2427795328331194/9994783069"
        )
        
        let privacyURL = "https://www.overrideinteractive.com/legal/"
        
        SwiftyAd.shared.setup(with: adUnitId, from: self, privacyURL: privacyURL) { consentType in
            guard consentType.hasPermission else { return }
            DispatchQueue.main.async {
                SwiftyAd.shared.showBanner(from: self)
            }
        }
    
        // Load scene
        if let scene = GameScene(fileNamed: "GameScene") {
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
