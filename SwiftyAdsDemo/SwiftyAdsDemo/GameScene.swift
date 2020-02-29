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
    
    private var swiftyAds: SwiftyAdsType!
    private var coins = 0
    
    private lazy var interstitialLabel: SKLabelNode = self.childNode(withName: "interstitialLabel") as! SKLabelNode
    private lazy var rewardedLabel: SKLabelNode = self.childNode(withName: "rewardedLabel") as! SKLabelNode
    private lazy var disableLabel: SKLabelNode = self.childNode(withName: "disableLabel") as! SKLabelNode
    private lazy var consentLabel: SKLabelNode = self.childNode(withName: "consentLabel") as! SKLabelNode
    
    // MARK: - Init
    
    func configure(swiftyAds: SwiftyAdsType) {
        self.swiftyAds = swiftyAds
    }
    
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
                showInterstitialAd(from: viewController)
            case rewardedLabel:
                showRewardedAd(from: viewController)
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

// MARK: - Private Methods

private extension GameScene {
    
    func showInterstitialAd(from viewController: UIViewController) {
        swiftyAds.showInterstitial(
            from: viewController,
            withInterval: 2,
            onOpen: ({
                print("SwiftyAds interstitial ad did open")
            }),
            onClose: ({
                print("SwiftyAds interstitial ad did close")
            }),
            onError: ({ error in
                print("SwiftyAds interstitial ad error \(error)")
            })
        )
    }
    
    func showRewardedAd(from viewController: UIViewController) {
        swiftyAds.showRewardedVideo(
            from: viewController,
            onOpen: ({
                print("SwiftyAds rewarded video ad did open")
            }),
            onClose: ({
                print("SwiftyAds rewarded video ad did close")
            }),
            onError: ({ error in
                print("SwiftyAds rewarded video ad error \(error)")
            }),
            onNotReady: ({
                let alertController = UIAlertController(
                    title: "Sorry",
                    message: "No video available to watch at the moment.",
                    preferredStyle: .alert
                )
                alertController.addAction(UIAlertAction(title: "Ok", style: .cancel))
                viewController.present(alertController, animated: true)
            }),
            onReward: ({ [weak self] rewardAmount in
                print("SwiftyAds rewarded video ad did reward user with \(rewardAmount)")
                self?.coins += rewardAmount
            })
        )
    }
}
