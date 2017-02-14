//
//  GameScene.swift
//  SwiftyAds
//
//  Created by Dominik on 04/09/2015.


import SpriteKit

extension GameScene: SwiftyAdsDelegate {
    
    func adDidOpen() {
        print("Ad did open")
    }
    
    func adDidClose() {
        print("Ad did close")
    }
    
    func adDidRewardUser(withAmount rewardAmount: Int) {
        // e.g self.coins += rewardAmount
        
        // Will not work with this sample project, adMob just shows a black banner in test mode
        // It only works with 3rd party mediation partners you set up through your adMob account
    }
}

class GameScene: SKScene {
    
    lazy var label: SKLabelNode? = self.childNode(withName: "textLabel") as? SKLabelNode
    
    var touchCounter = 15 {
        didSet {
            if touchCounter >= 0 {
                label?.text = "Remove ads in \(touchCounter) clicks"
            }
            if touchCounter == 0 {
                SwiftyAds.shared.isRemoved = true
            }
        }
    }
    
    override func didMove(to view: SKView) {
        label?.text = "Remove ads in \(touchCounter) clicks"
    
        SwiftyAds.shared.delegate = self
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        SwiftyAds.shared.showInterstitial(withInterval: 2, from: view?.window?.rootViewController)
        
        touchCounter -= 1
    }
}
