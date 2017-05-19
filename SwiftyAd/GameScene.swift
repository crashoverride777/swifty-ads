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
    
    /// Labels
    private lazy var label: SKLabelNode = self.childNode(withName: "textLabel") as! SKLabelNode
    
    /// Touch counter
    private var touchCounter = 15 {
        didSet {
            guard touchCounter > 0 else {
                SwiftyAd.shared.isRemoved = true
                label.text = "Removed all ads"
                return
            }
            
            label.text = "Remove ads in \(touchCounter) clicks"
        }
    }
    
    /// Coins
    fileprivate var coins = 0
    
    // MARK: - Did Move To View
    
    /// Did move to view
    override func didMove(to view: SKView) {
        
        SwiftyAd.shared.delegate = self
        
        label.text = "Remove ads in \(touchCounter) clicks"
    }
    
    // MARK: - Touches
    
    /// Touches began
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        defer {
            touchCounter -= 1
        }
        
        guard let viewController = view?.window?.rootViewController else { return }
        SwiftyAd.shared.showInterstitial(from: viewController, withInterval: 2)
    }
    
    /// Touches moved
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    }
    
    /// Touches ended
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    }
    
    /// Touches cancelled
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
    }
}
