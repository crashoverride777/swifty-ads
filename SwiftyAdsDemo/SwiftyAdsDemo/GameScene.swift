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
    
    var swiftyAds: SwiftyAdsType!
    var coins = 0
    
    private lazy var interstitialLabel: SKLabelNode = self.childNode(withName: "interstitialLabel") as! SKLabelNode
    private lazy var rewardedLabel: SKLabelNode = self.childNode(withName: "rewardedLabel") as! SKLabelNode
    private lazy var removeLabel: SKLabelNode = self.childNode(withName: "removeLabel") as! SKLabelNode
    private lazy var consentLabel: SKLabelNode = self.childNode(withName: "consentLabel") as! SKLabelNode
    
    // MARK: - Life Cycle
    
    override func didMove(to view: SKView) {
        backgroundColor = .gray
        consentLabel.isHidden = !swiftyAds.isRequiredToAskForConsent
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            let node = atPoint(location)
            
            guard let viewController = view?.window?.rootViewController as? GameViewController else {
                return
            }
            
            switch node {
            case interstitialLabel:
                swiftyAds.showInterstitial(from: viewController, withInterval: 2)
            case rewardedLabel:
                swiftyAds.showRewardedVideo(from: viewController) { success in
                    if !success {
                        let alertController = UIAlertController(
                            title: "Sorry",
                            message: "No video available to watch at the moment.",
                            preferredStyle: .alert
                        )
                        alertController.addAction(UIAlertAction(title: "Ok", style: .cancel))
                        viewController.present(alertController, animated: true)
                    }
                }
            case removeLabel:
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
