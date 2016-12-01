//
//  GameViewController.swift
//  SwiftyAds
//
//  Created by Dominik on 18/05/2016.
//  Copyright (c) 2016 Dominik Ringler. All rights reserved.
//

import UIKit
import SpriteKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        SwiftyAdsCustom.shared.ads = [
            SwiftyAdsCustom.Ad(imageName: "AdVertigus", appID: "1051292772", color: .green),
            SwiftyAdsCustom.Ad(imageName: "AdAngryFlappies", appID: "991933749", color: .blue)
        ]
     
        _ = SwiftyAdsAppLovin.shared

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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
}
