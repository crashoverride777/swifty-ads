//
//  GameScene.swift
//  Example
//
//  Created by Dominik Ringler on 23/05/2019.
//  Copyright © 2019 Dominik. All rights reserved.
//

import SpriteKit

class GameScene: SKScene {
    
    // MARK: - Properties
    
    private var swiftyAds: SwiftyAdsType = SwiftyAds.shared
    
    private lazy var interstitialLabel: SKLabelNode = self.childNode(withName: "interstitialLabel") as! SKLabelNode
    private lazy var rewardedLabel: SKLabelNode = self.childNode(withName: "rewardedLabel") as! SKLabelNode
    private lazy var disableLabel: SKLabelNode = self.childNode(withName: "disableLabel") as! SKLabelNode
    private lazy var consentLabel: SKLabelNode = self.childNode(withName: "consentLabel") as! SKLabelNode
    
    // MARK: - Life Cycle
    
    override func didMove(to view: SKView) {
        backgroundColor = .gray
        refresh()
        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: .adConsentStatusDidChange, object: nil)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            let node = atPoint(location)
            
            guard let viewController = view?.window?.rootViewController else {
                return
            }
            
            switch node {
            case interstitialLabel:
                AdPresenter.showInterstitialAd(from: viewController)
            case rewardedLabel:
                AdPresenter.showRewardedAd(from: viewController, onReward: { rewardAmount in
                    // update coins, diamonds etc
                })
            case disableLabel:
                swiftyAds.disable()
            case consentLabel:
                swiftyAds.askForConsent(from: viewController)
            default:
                break
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
    }
}
 
// MARK: - Private
 
private extension GameScene {
    
    @objc func refresh() {
        consentLabel.isHidden = !swiftyAds.isRequiredToAskForConsent
    }
}
