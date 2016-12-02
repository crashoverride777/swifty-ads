//
//  GameScene.swift
//  SwiftyAds
//
//  Created by Dominik on 04/09/2015.


import SpriteKit

func setupAds() {
    SwiftyAdsCustom.shared.inventory = [
        SwiftyAdsCustom.Ad(imageName: "AdVertigus", appID: "1051292772", color: .green),
        SwiftyAdsCustom.Ad(imageName: "AdAngryFlappies", appID: "991933749", color: .blue)
    ]
}

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
    
    var customAdCounter = 0
    
    var touchCounter = 15 {
        didSet {
            if touchCounter >= 0 {
                label?.text = "Remove ads in \(touchCounter) clicks"
            }
            if touchCounter == 0 {
                SwiftyAdsCustom.shared.isRemoved = true
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
        
        /// Set ads helper delegate
        SwiftyAdsCustom.shared.delegate = self
        #if os(iOS)
            SwiftyAdsAdMob.shared.delegate = self
        #endif
        #if os(tvOS)
            SwiftyAdsAppLovin.shared.delegate = self
            loadTVControls()
        #endif
        
        // Show banner ad
        #if os(iOS)
            SwiftyAdsAdMob.shared.showBanner()
        #endif
        
    
    }
    
    #if os(tvOS)
    private func loadTVControls() {
        let tapMain = UITapGestureRecognizer(target: self, action: #selector(download))
        tapMain.allowedPressTypes = [NSNumber(value: UIPressType.select.rawValue)]
        view?.addGestureRecognizer(tapMain)
    
        let tapMenu = UITapGestureRecognizer(target: self, action: #selector(remove))
        tapMenu.allowedPressTypes = [NSNumber(value: UIPressType.menu.rawValue)]
        view?.addGestureRecognizer(tapMenu)
    }
    
    func download() {
        guard !SwiftyAdsCustom.shared.isShowing else {
            SwiftyAdsCustom.shared.download()
            return
        }
        
        // rest of code
    }
    
    func remove() {
        guard !SwiftyAdsCustom.shared.isShowing else {
            SwiftyAdsCustom.shared.dismiss()
            return
        }
        
        // rest of code
    }
    #endif
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if customAdCounter == 0 {
            customAdCounter += 1
            #if os(iOS)
                SwiftyAdsAdMob.shared.showInterstitial(withInterval: 2)
            #endif
            #if os(tvOS)
                SwiftyAdsAppLovin.shared.showInterstitial(withInterval: 2)
            #endif
        } else {
            customAdCounter = 0
            SwiftyAdsCustom.shared.show()
        }
    
        touchCounter -= 1
    }
}
