//
//  GameScene.swift
//  AppLovin Helper
//
//  Created by Dominik on 18/05/2016.
//  Copyright (c) 2016 Dominik Ringler. All rights reserved.
//

import SpriteKit

extension GameScene: AppLovinDelegate {
    
    func appLovinAdClicked() {
        print("Ads clicked")
    }
    
    func appLovinAdClosed() {
        print("Ads closed")
    }
    
    func appLovinAdDidRewardUser(rewardAmount rewardAmount: Int) {
        // e.g self.coins += rewardAmount
        
    }
}

class GameScene: SKScene {
    
    var myLabel: SKLabelNode!
    var touchCounter = 25 {
        didSet {
            guard touchCounter >= 0 else {return }
            myLabel.text = "Remove ads in \(touchCounter) clicks"
        }
    }
    
    override func didMoveToView(view: SKView) {
        myLabel = SKLabelNode(fontNamed:"Chalkduster")
        myLabel.text = "Remove ads in \(touchCounter) clicks"
        myLabel.fontSize = 25;
        myLabel.position = CGPoint(x:CGRectGetMidX(self.frame), y:CGRectGetMidY(self.frame));
        
        self.addChild(myLabel)
        
        
        AppLovinInter.sharedInstance.delegate = self
        AppLovinReward.sharedInstance.delegate = self
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        /* Called when a touch begins */
        
        // Show inter
        AdsManager.sharedInstance.showInterstitialRandomly(randomness: 3)
        
        // Remove ads after 3 clicks
        touchCounter -= 1
        if touchCounter == 0 {
            AdsManager.sharedInstance.removeAll()
        }
    }
   
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
    }
}
