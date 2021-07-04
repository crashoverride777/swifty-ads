import UIKit
import SpriteKit

class GameViewController: UIViewController {

    // MARK: - Properties

    private let swiftyAds: SwiftyAdsType = SwiftyAds.shared
    private let notificationCenter: NotificationCenter = .default
    private var bannerAd: SwiftyAdsBannerType?

    override var shouldAutorotate: Bool {
        true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .all
    }

    override var prefersStatusBarHidden: Bool {
        true
    }

    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        makeBanner()

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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        bannerAd?.show(isLandscape: view.frame.size.width > view.frame.size.height)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { [weak self] _ in
            self?.bannerAd?.show(isLandscape: size.width > size.height)
        })
    }

    // MARK: - Public Methods

    func adsConfigureCompletion() {
        if bannerAd == nil {
            makeBanner()
        }
        bannerAd?.show(isLandscape: view.frame.width > view.frame.height)
    }

    func disableAds() {
        swiftyAds.disable(true)
        bannerAd?.remove()
        bannerAd = nil
    }

    func makeBanner() {
        bannerAd = swiftyAds.makeBannerAd(
            in: self,
            adUnitIdType: .plist,
            position: .bottom(isUsingSafeArea: true),
            animation: .slide(duration: 1.5),
            onOpen: {
                print("SwiftyAds banner ad did open")
            },
            onClose: {
                print("SwiftyAds banner ad did close")
            },
            onError: { error in
                print("SwiftyAds banner ad error \(error)")
            },
            onWillPresentScreen: {
                print("SwiftyAds banner ad was tapped and is about to present screen")
            },
            onWillDismissScreen: {
                print("SwiftyAds banner ad screen is about to be dismissed")
            },
            onDidDismissScreen: {
                print("SwiftyAds banner did dismiss screen")
            }
        )
    }
}
