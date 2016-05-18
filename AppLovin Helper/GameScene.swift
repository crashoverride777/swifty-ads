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
    override func didMoveToView(view: SKView) {
        /* Setup your scene here */
        let myLabel = SKLabelNode(fontNamed:"Chalkduster")
        myLabel.text = "Hello, World!"
        myLabel.fontSize = 65
        myLabel.position = CGPoint(x:CGRectGetMidX(self.frame), y:CGRectGetMidY(self.frame))
        
        self.addChild(myLabel)
        
        
        AppLovinInter.sharedInstance.delegate = self
        AppLovinReward.sharedInstance.delegate = self
        
        AppLovinInter.sharedInstance.showRandomly(randomness: 3)
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        /* Called when a touch begins */
        
        for touch in touches {
            let location = touch.locationInNode(self)
            
            let sprite = SKSpriteNode(imageNamed:"Spaceship")
            
            sprite.xScale = 0.5
            sprite.yScale = 0.5
            sprite.position = location
            
            let action = SKAction.rotateByAngle(CGFloat(M_PI), duration:1)
            
            sprite.runAction(SKAction.repeatActionForever(action))
            
            self.addChild(sprite)
        }
    }
   
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
    }
}
