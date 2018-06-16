//
//  GameViewController.swift
//  SwiftyAds
//
//  Created by Dominik on 04/09/2015.


import UIKit
import SpriteKit

class GameViewController: UIViewController {

    private let swiftyAd: SwiftyAd = .shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
     
        setupSwiftyAd(formType: .custom)
    
        if let scene = GameScene(fileNamed: "GameScene") {
            // Configure the view.
            let skView = self.view as! SKView
            skView.showsFPS = true
            skView.showsNodeCount = true
            
            /* Sprite Kit applies additional optimizations to improve rendering performance */
            skView.ignoresSiblingOrder = true
            
            /* Set the scale mode to scale to fit the window */
            scene.scaleMode = .aspectFill
            
            skView.presentScene(scene)
        }
    }

    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

// MARK: - SwiftyAdDelegate

extension GameViewController: SwiftyAdDelegate {
    
    func swiftyAdDidOpen(_ swiftyAd: SwiftyAd) {
        print("SwiftyAd did open")
    }
    
    func swiftyAdDidClose(_ swiftyAd: SwiftyAd) {
        print("SwiftyAd did close")
    }
    
    func swiftyAd(_ swiftyAd: SwiftyAd, didChange consentStatus: SwiftyAd.ConsentStatus) {
        print("SwiftyAd did change consent status to \(consentStatus)")
        // e.g update mediation networks
    }
    
    func swiftyAd(_ swiftyAd: SwiftyAd, didRewardUserWithAmount rewardAmount: Int) {
        print("SwiftyAd did reward user with \(rewardAmount)")
        
        if let scene = (view as? SKView)?.scene as? GameScene {
            scene.coins += rewardAmount
        }
        
        // Will actually not work with this sample project, adMob just shows a black ad in test mode
        // It only works with 3rd party mediation partners you set up through your adMob account
    }
}

// MARK: - Setup Swifty Ad

extension GameViewController {
    
    func setupSwiftyAd(formType: SwiftyAd.FormType) {
        let config = SwiftyAd.Configuration(
            bannerAdUnitId:        "",
            interstitialAdUnitId:  "",
            rewardedVideoAdUnitId: "",
            bannerAnimationDuration: 1.8
        )
        
        let consentConfig = SwiftyAd.ConsentConfiguration(
            privacyPolicyURL: "https://developers.google.com/admob/ios/eu-consent", // enter real
            shouldOfferAdFree: false,
            mediationNetworks: ["Chartboost", "AppLovin", "Vungle"],
            isTaggedForUnderAgeOfConsent: false,
            formType: formType
            
        )
        
        swiftyAd.delegate = self
        swiftyAd.setup(with: config, consentConfiguration: consentConfig, viewController: self) { hasConsent in
            guard hasConsent else { return }
            DispatchQueue.main.async {
                self.swiftyAd.showBanner(from: self)
            }
        }
    }
}
