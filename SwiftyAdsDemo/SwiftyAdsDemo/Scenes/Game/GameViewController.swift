import UIKit
import SpriteKit

class GameViewController: UIViewController {
    
    private var swiftyAds: SwiftyAdsType!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        AdPresenter.prepareBanner(in: self, swiftyAds: swiftyAds)
        
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
        AdPresenter.showBanner(isLandscape: view.frame.size.width > view.frame.size.height, swiftyAds: swiftyAds)
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
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { [weak self] _ in
            guard let self = self else { return }
            AdPresenter.showBanner(isLandscape: size.width > size.height, swiftyAds: self.swiftyAds)
        })
    }

    func configure(swiftyAds: SwiftyAdsType) {
        self.swiftyAds = swiftyAds
    }
}
