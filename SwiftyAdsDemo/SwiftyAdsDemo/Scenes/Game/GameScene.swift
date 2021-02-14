import SpriteKit

class GameScene: SKScene {
    
    // MARK: - Properties
    
    private var swiftyAds: SwiftyAdsType!
    
    private lazy var interstitialLabel: SKLabelNode = childNode(withName: "interstitialLabel") as! SKLabelNode
    private lazy var rewardedLabel: SKLabelNode = childNode(withName: "rewardedLabel") as! SKLabelNode

    // MARK: - Configure
    
    func configure(swiftyAds: SwiftyAdsType) {
        self.swiftyAds = swiftyAds
    }

    // MARK: - Life Cycle
    
    override func didMove(to view: SKView) {
        backgroundColor = .gray
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
                swiftyAds.showInterstitialAd(
                    from: viewController,
                    afterInterval: 2,
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

            case rewardedLabel:
                swiftyAds.showRewardedAd(
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
                        DispatchQueue.main.async {
                            viewController.present(alertController, animated: true)
                        }
                    }),
                    onReward: ({ rewardAmount in
                        print("SwiftyAds rewarded video ad did reward user with \(rewardAmount)")
                    })
                )

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
