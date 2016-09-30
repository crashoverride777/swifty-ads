//
//  GameScene.swift
//  AppLovin Helper
//
//  Created by Dominik on 18/05/2016.
//  Copyright (c) 2016 Dominik Ringler. All rights reserved.
//

import SpriteKit

extension GameScene: AdsDelegate {
    
    func adDidOpen() {
        print("Ad did open")
    }
    
    func adDidClose() {
        print("Ad did close")
    }
    
    func adDidRewardUser(withAmount rewardAmount: Int) {
        // e.g self.coins += rewardAmount
        
    }
}

class GameScene: SKScene {
    
    var myLabel: SKLabelNode!
    var touchCounter = 25 {
        didSet {
            guard touchCounter >= 0 else {return }
            myLabel.text = "Remove ads in \(touchCounter) clicks"
        }
    }
    
    override func didMove(to view: SKView) {
        myLabel = SKLabelNode(fontNamed:"Chalkduster")
        myLabel.text = "Remove ads in \(touchCounter) clicks"
        myLabel.fontSize = 25;
        myLabel.position = CGPoint(x: frame.midX, y: frame.midY)
        self.addChild(myLabel)
        
        
        AdsManager.shared.delegate = self
        
        loadCustomAdControls()
    }
    
    private func loadCustomAdControls() {
        let tapMain = UITapGestureRecognizer(target: self, action: #selector(pressedMainButtonTVRemote))
        tapMain.allowedPressTypes = [NSNumber(value: UIPressType.select.rawValue)]
        view?.addGestureRecognizer(tapMain)
        
        let tapMenu = UITapGestureRecognizer(target: self, action: #selector(pressedMenuButtonTVRemote))
        tapMenu.allowedPressTypes = [NSNumber(value: UIPressType.menu.rawValue)]
        view?.addGestureRecognizer(tapMenu)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        /* Called when a touch begins */
        
        // Show inter
        AdsManager.shared.showInterstitial(withInterval: 2)
        
        // Remove ads after 3 clicks
        touchCounter -= 1
        if touchCounter == 0 {
            AdsManager.shared.removeAll()
        }
    }
   
    @objc private func pressedMainButtonTVRemote() {
        CustomAd.shared.download()
    }
    
    @objc private func pressedMenuButtonTVRemote() {
        CustomAd.shared.dismiss()
    }
}
