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
                #if os(iOS)
                    SwiftyAdsAdMob.shared.isRemoved = true
                #endif
                #if os(tvOS)
                    SwiftyAdsAppLovin.shared.isRemoved = true
                #endif
            }
        }
    }
    
    override func didMove(to view: SKView) {
        label?.text = "Remove ads in \(touchCounter) clicks"
    
        #if os(iOS)
            SwiftyAdsAdMob.shared.delegate = self
            SwiftyAdsAdMob.shared.showBanner()
        #endif
        #if os(tvOS)
            SwiftyAdsAppLovin.shared.delegate = self
        #endif
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        #if os(iOS)
            SwiftyAdsAdMob.shared.showInterstitial(withInterval: 2)
        #endif
        #if os(tvOS)
            SwiftyAdsAppLovin.shared.showInterstitial(withInterval: 2)
        #endif
        
        touchCounter -= 1
    }
}
