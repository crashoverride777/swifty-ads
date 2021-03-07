import UIKit
import SpriteKit

class GameViewController: UIViewController {

    // MARK: - Properties

    private var swiftyAds: SwiftyAdsType!
    private var bannerAd: SwiftyAdsBannerType?
    private let notificationCenter: NotificationCenter = .default

    override var shouldAutorotate: Bool {
        true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .all
    }

    override var prefersStatusBarHidden: Bool {
        true
    }

    // MARK: - Initialization

    func configure(swiftyAds: SwiftyAdsType) {
        self.swiftyAds = swiftyAds
    }

    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        notificationCenter.addObserver(self, selector: #selector(adsConfigureCompletion), name: .adsConfigureCompletion, object: nil)
        loadGameScene()
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

    func disableAds() {
        swiftyAds.disable()
        bannerAd?.remove()
        bannerAd = nil
    }
}

// MARK: - Private Methods

private extension GameViewController {

    func loadGameScene() {
        guard let scene = GameScene(fileNamed: "GameScene") else { return }
        scene.configure(swiftyAds: swiftyAds)

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

    @objc func adsConfigureCompletion() {
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
        bannerAd?.show(isLandscape: view.frame.width > view.frame.height)
    }
}
