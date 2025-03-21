import SpriteKit
import SwiftyAds

final class GameScene: SKScene {
    
    // MARK: - Properties
    
    private let swiftyAds: SwiftyAdsType = SwiftyAds.shared
    
    private lazy var interstitialLabel = childNode(withName: "interstitialLabel") as! SKLabelNode
    private lazy var rewardedLabel = childNode(withName: "rewardedLabel") as! SKLabelNode
    private lazy var rewardedInterstitialLabel = childNode(withName: "rewardedInterstitialLabel") as! SKLabelNode
    private lazy var disableLabel = childNode(withName: "disableLabel") as! SKLabelNode

    // MARK: - Life Cycle

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let gameViewController = view?.window?.rootViewController as? GameViewController else { return }
        for touch in touches {
            let location = touch.location(in: self)
            let node = atPoint(location)
            switch node {
            case interstitialLabel:
                showInterstitialAd(from: gameViewController)
            case rewardedLabel:
                showRewardedAd(from: gameViewController)
            case rewardedInterstitialLabel:
                showRewardedInterstitialAd(from: gameViewController)
            case disableLabel:
                gameViewController.disableAds()
            default:
                break
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {}
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {}
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {}
}

// MARK: - Private Methods

private extension GameScene {
    func showInterstitialAd(from viewController: UIViewController) {
        Task { [weak self] in
            try await self?.swiftyAds.showInterstitialAd(
                from: viewController,
                onOpen: {
                    print("SwiftyAds interstitial ad did open")
                },
                onClose: {
                    print("SwiftyAds interstitial ad did close")
                },
                onError: { error in
                    print("SwiftyAds interstitial ad error \(error)")
                }
            )
        }
    }
    
    func showRewardedAd(from viewController: UIViewController) {
        Task { [weak self] in
            do {
                try await self?.swiftyAds.showRewardedAd(
                    from: viewController,
                    onOpen: {
                        print("SwiftyAds rewarded ad did open")
                    },
                    onClose: {
                        print("SwiftyAds rewarded ad did close")
                    },
                    onError: { error in
                        print("SwiftyAds rewarded ad error \(error)")
                    },
                    onReward: { rewardAmount in
                        print("SwiftyAds rewarded ad did reward user with \(rewardAmount)")
                    }
                )
            } catch SwiftyAdsError.rewardedAdNotLoaded {
                let alertController = UIAlertController(
                    title: "Sorry",
                    message: "No video available to watch at the moment.",
                    preferredStyle: .alert
                )
                alertController.addAction(UIAlertAction(title: "Ok", style: .cancel))
                DispatchQueue.main.async {
                    viewController.present(alertController, animated: true)
                }
            }
        }
    }
    
    func showRewardedInterstitialAd(from viewController: UIViewController) {
        Task { [weak self] in
            try await self?.swiftyAds.showRewardedInterstitialAd(
                from: viewController,
                onOpen: {
                    print("SwiftyAds rewarded interstitial ad did open")
                },
                onClose: {
                    print("SwiftyAds rewarded interstitial ad did close")
                },
                onError: { error in
                    print("SwiftyAds rewarded interstitial ad error \(error)")
                },
                onReward: { rewardAmount in
                    print("SwiftyAds rewarded interstitial ad did reward user with \(rewardAmount)")
                }
            )
        }
    }
}
