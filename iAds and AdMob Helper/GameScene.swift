//
//  GameScene.swift
//  iAds and AdMob Helper
//
//  Created by Dominik on 04/09/2015.


import SpriteKit

class GameScene: SKScene {
    
    var myLabel: SKLabelNode!
    var touchCounter = 5 {
        didSet {
           guard touchCounter >= 0 else {return }
           myLabel.text = "Remove ads in \(touchCounter) clicks"
        }
    }
    
    override func didMoveToView(view: SKView) {
        /* Setup your scene here */
        myLabel = SKLabelNode(fontNamed:"Chalkduster")
        myLabel.text = "Remove ads in \(touchCounter) clicks"
        myLabel.fontSize = 25;
        myLabel.position = CGPoint(x:CGRectGetMidX(self.frame), y:CGRectGetMidY(self.frame));
        
        self.addChild(myLabel)
        
        // Show banner ad
        AdsManager.sharedInstance.showBanner()
    } 
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        /* Called when a touch begins */
        
        // Show inter ad
        AdsManager.sharedInstance.showInterRandomly(randomness: 3)
        
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
