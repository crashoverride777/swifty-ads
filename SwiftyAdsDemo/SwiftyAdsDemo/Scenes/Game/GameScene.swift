import SpriteKit

class GameScene: SKScene {
    
    // MARK: - Properties
    
    private var swiftyAds: SwiftyAdsType!
    
    private lazy var interstitialLabel: SKLabelNode = self.childNode(withName: "interstitialLabel") as! SKLabelNode
    private lazy var rewardedLabel: SKLabelNode = self.childNode(withName: "rewardedLabel") as! SKLabelNode
    private lazy var disableLabel: SKLabelNode = self.childNode(withName: "disableLabel") as! SKLabelNode
    
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
                AdPresenter.showInterstitialAd(from: viewController, swiftyAds: swiftyAds)
            case rewardedLabel:
                AdPresenter.showRewardedAd(from: viewController, swiftyAds: swiftyAds, onReward: { rewardAmount in
                    // update coins, diamonds etc
                })
            case disableLabel:
                swiftyAds.disable()
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

    // MARK: - Public Methods

    func configure(swiftyAds: SwiftyAdsType) {
        self.swiftyAds = swiftyAds
    }
}
