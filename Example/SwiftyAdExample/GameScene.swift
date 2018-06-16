//
//  GameScene.swift
//  SwiftyAds
//
//  Created by Dominik on 04/09/2015.


import SpriteKit

class GameScene: SKScene {
    
    // MARK: - Properties

    var coins = 0
    
    private lazy var textLabel: SKLabelNode = self.childNode(withName: "textLabel") as! SKLabelNode
    private lazy var consentDefaultLabel: SKLabelNode = self.childNode(withName: "consentDefaultLabel") as! SKLabelNode
    private lazy var consentCustomLabel: SKLabelNode = self.childNode(withName: "consentCustomLabel") as! SKLabelNode
    
    private let swiftyAd: SwiftyAd = .shared
    
    private var touchCounter = 15 {
        didSet {
            guard touchCounter > 0 else {
                swiftyAd.isRemoved = true
                textLabel.text = "Removed all ads"
                return
            }
            
            textLabel.text = "Remove ads in \(touchCounter) clicks"
        }
    }
    
    // MARK: - Life Cycle
    
    override func didMove(to view: SKView) {
        textLabel.text = "Remove ads in \(touchCounter) clicks"
        consentDefaultLabel.isHidden = !swiftyAd.isRequiredToAskForConsent
        consentCustomLabel.isHidden = !swiftyAd.isRequiredToAskForConsent
    }
    
    // MARK: - Touches
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            let node = atPoint(location)
            
            guard let viewController = view?.window?.rootViewController else { return }
            
            if node == consentDefaultLabel {
                let gameVC = view?.window?.rootViewController as! GameViewController
                gameVC.setupSwiftyAd(formType: .google) // just for this demo to show both alerts
                swiftyAd.askForConsent(from: viewController)
            }
            
            if node == consentCustomLabel {
                let gameVC = view?.window?.rootViewController as! GameViewController
                gameVC.setupSwiftyAd(formType: .custom) // just for this demo to show both alerts
                swiftyAd.askForConsent(from: viewController)
            }
            
            defer {
                touchCounter -= 1
            }
            
            swiftyAd.showInterstitial(from: viewController, withInterval: 2)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
    }
}
