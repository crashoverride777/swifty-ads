//
//  GameViewController.swift
//  iAds and AdMob Helper
//
//  Created by Dominik on 04/09/2015.


import UIKit
import SpriteKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
     
        // Custom ad inventory
        SwiftyAdsCustom.Inventory.all = [
            SwiftyAdsCustom.Ad(imageName: "AdAngryFlappies", appID: "991933749", isNewGame: false),
            SwiftyAdsCustom.Ad(imageName: "AdVertigus", appID: "1051292772", isNewGame: true)
        ]
        
        // Set up ad Mob
        let bannerID = "Enter your real ID"
        let interstitialID = "Enter your real ID"
        let rewardedVideoID = "Enter your real ID"
        SwiftyAdsAdMob.shared.setup(viewController: self, bannerID: bannerID, interID: interstitialID, rewardedVideoID: rewardedVideoID)
        
        // Set up adsManager
        SwiftyAdsManager.shared.setup(customAdsInterval: 3, maxCustomAdsPerSession: 3)
        
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
   
    // Check for device orientation changes
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { (UIViewControllerTransitionCoordinatorContext) in
            
            SwiftyAdsManager.shared.adjustForOrientation()
            
//            let orientation = UIApplication.sharedApplication().statusBarOrientation
//            switch orientation {
//            case .Portrait:
//                print("Portrait")
//                // Do something
//            default:
//                print("Anything But Portrait")
//                // Do something else
//            }
            
            }, completion: { (UIViewControllerTransitionCoordinatorContext) -> Void in
                print("Device rotation completed")
        })
    }

    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return UIInterfaceOrientationMask.allButUpsideDown
        } else {
            return UIInterfaceOrientationMask.all
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
