import UIKit
import SpriteKit

class GameViewController: UIViewController {
    
    private var swiftyAds: SwiftyAdsType!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        swiftyAds.prepareBanner(
            in: self,
            atTop: false,
            isUsingSafeArea: true,
            animationDuration: 1.5,
            onOpen: ({
                print("SwiftyAds banner ad did open")
            }),
            onClose: ({
                print("SwiftyAds banner ad did close")
            }),
            onError: ({ error in
                print("SwiftyAds banner ad error \(error)")
            })
        )
        
        if let scene = GameScene(fileNamed: "GameScene") {
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
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        swiftyAds.showBanner(isLandscape: view.frame.size.width > view.frame.size.height)
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { [weak self] _ in
            self?.swiftyAds.showBanner(isLandscape: size.width > size.height)
        })
    }

    func configure(swiftyAds: SwiftyAdsType) {
        self.swiftyAds = swiftyAds
    }
}
