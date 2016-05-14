//
//  GameScene.swift
//  iAds and AdMob Helper
//
//  Created by Dominik on 04/09/2015.


import SpriteKit

extension GameScene: AdsDelegate {
    
    func adClicked() {
        print("Ads clicked")
    }
    
    func adClosed() {
        print("Ads closed")
    }
    
    func adDidRewardUserWithAmount(rewardAmount: Int) {
        // e.g self.coins += rewardAmount
        
        // Will not work with this sample project, adMob just shows a black banner in test mode
        // It only works with 3rd party mediation partners you set up through your adMob account
    }
}

class GameScene: SKScene {
    
    var myLabel: SKLabelNode!
    var touchCounter = 10 {
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
        
        
        
        /// Set ads helper delegate
        AdsManager.sharedInstance.delegate = self
        
        // Show banner ad
        AdsManager.sharedInstance.showBanner()
    } 
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        /* Called when a touch begins */
        
        // Show inter ad
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
