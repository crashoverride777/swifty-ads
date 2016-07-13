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
        
        // Set up helpers
        let bannerID = "Enter your real ID"
        let interstitialID = "Enter your real ID"
        let rewardVideoID = "Enter your real ID"
        AdMob.sharedInstance.setUp(viewController: self, bannerID: bannerID, interID: interstitialID, rewardVideoID: rewardVideoID)
        
        
        let customAdsInventory = [
            CustomAdInventory(imageName: "AdImageVertigus", storeURL: getAppStoreURL(forAppID: "991933749")),
            CustomAdInventory(imageName:"AdImageAngryFlappies", storeURL: getAppStoreURL(forAppID: "1051292772"))
        ]
        
        CustomAd.sharedInstance.setup(viewController: self, inventory: customAdsInventory)
        
        AdsManager.sharedInstance.setup(viewController: self, customAdsInterval: 3, maxCustomAdsPerSession: 3)
        
        if let scene = GameScene(fileNamed: "GameScene") {
            // Configure the view.
            let skView = self.view as! SKView
            skView.showsFPS = true
            skView.showsNodeCount = true
            
            /* Sprite Kit applies additional optimizations to improve rendering performance */
            skView.ignoresSiblingOrder = true
            
            /* Set the scale mode to scale to fit the window */
            scene.scaleMode = .AspectFill
            
            skView.presentScene(scene)
        }
    }
   
    // Check for device orientation changes
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        
        coordinator.animateAlongsideTransition({ (UIViewControllerTransitionCoordinatorContext) -> Void in
            
            AdsManager.sharedInstance.orientationChanged()
            
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

    override func shouldAutorotate() -> Bool {
        return true
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            return UIInterfaceOrientationMask.AllButUpsideDown
        } else {
            return UIInterfaceOrientationMask.All
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}
