//
//  GameScene.swift
//  SwiftyAds
//
//  Created by Dominik on 04/09/2015.


import SpriteKit

extension GameScene: SwiftyAdDelegate {
    
    func swiftyAdDidOpen(_ swiftyAd: SwiftyAd) {
        print("SwiftyAd did open")
    }
    
    func swiftyAdDidClose(_ swiftyAd: SwiftyAd) {
        print("SwiftyAd did close")
    }
    
    func swiftyAd(_ swiftyAd: SwiftyAd, didRewardUserWithAmount rewardAmount: Int) {
        print("SwiftyAd did reward user")
        
        coins += rewardAmount
        // Will actually not work with this sample project, adMob just shows a black ad in test mode
        // It only works with 3rd party mediation partners you set up through your adMob account
    }
}

class GameScene: SKScene {
    
    // MARK: - Properties
    
    private let swiftyAd: SwiftyAd = .shared
    private var coins = 0
    private lazy var textLabel: SKLabelNode = self.childNode(withName: "textLabel") as! SKLabelNode
    private lazy var consentLabel: SKLabelNode = self.childNode(withName: "consentLabel") as! SKLabelNode
    
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
    
    // MARK: - Did Move To View
    
    /// Did move to view
    override func didMove(to view: SKView) {
        
        swiftyAd.delegate = self
    
        textLabel.text = "Remove ads in \(touchCounter) clicks"
    }
    
    // MARK: - Touches
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            let node = atPoint(location)
            
            guard let viewController = view?.window?.rootViewController else { return }
            
            if node == consentLabel {
                swiftyAd.consentManager.ask(from: viewController) { consentyType in
                    print(consentyType)
                }
                return
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
