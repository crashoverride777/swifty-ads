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
    
    var myLabel: SKLabelNode!
    var customAdCounter = 0
    var touchCounter = 15 {
        didSet {
            if touchCounter >= 0 {
                myLabel.text = "Remove ads in \(touchCounter) clicks"
            }
            if touchCounter == 0 {
                SwiftyAdsCustom.shared.remove()
                SwiftyAdsAdMob.shared.remove()
            }
        }
    }
    
    override func didMove(to view: SKView) {
        myLabel = SKLabelNode(fontNamed:"Chalkduster")
        myLabel.text = "Remove ads in \(touchCounter) clicks"
        myLabel.fontSize = 25;
        myLabel.position = CGPoint(x: frame.midX, y: frame.midY)
        self.addChild(myLabel)
        
        /// Set ads helper delegate
        SwiftyAdsCustom.shared.delegate = self
        SwiftyAdsAdMob.shared.delegate = self
        
        // Show banner ad
        SwiftyAdsAdMob.shared.showBanner()
        
        /// Custom ads tv controls
        #if os(tvOS)
            let tapMain = UITapGestureRecognizer(target: self, action: #selector(didPressSelectButtonTV))
            tapMain.allowedPressTypes = [NSNumber (value: UIPressType.select.rawValue)]
            view.addGestureRecognizer(tapMain)
            
            let tapPlayPauseMenu = UITapGestureRecognizer(target: self, action: #selector(didPressPlayOrMenuButtonTV))
            tapPlayPauseMenu.allowedPressTypes = [NSNumber(value: UIPressType.playPause.rawValue), NSNumber(value: UIPressType.menu.rawValue)]
            view.addGestureRecognizer(tapPlayPauseMenu)
        #endif
        
        
    }
    
    /// Menu controls menu/play button pressed
    @objc private func didPressPlayOrMenuButtonTV() {
        
        guard !SwiftyAdsCustom.shared.isShowing else {
            SwiftyAdsCustom.shared.dismiss()
            return
        }
        
        // other coded if needed e.g menu navigation
    }
    
    /// Pressed select button
    @objc private func didPressSelectButtonTV() {
        
        guard !SwiftyAdsCustom.shared.isShowing else {
            SwiftyAdsCustom.shared.download()
            return
        }
        
        // other code/rest of code e.g menu navigation
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if customAdCounter == 0 {
            customAdCounter += 1
            SwiftyAdsAdMob.shared.showInterstitial(withInterval: 2)
        } else {
            customAdCounter = 0
            SwiftyAdsCustom.shared.show()
        }
    
        touchCounter -= 1
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    }
   
    override func update(_ currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
    }
}
