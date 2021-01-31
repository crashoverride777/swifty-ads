import UIKit

final class PlainViewController: UIViewController {

    // MARK: - Properties

    private var swiftyAds: SwiftyAdsType!
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .blue
        AdPresenter.prepareBanner(in: self, swiftyAds: swiftyAds)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AdPresenter.showBanner(isLandscape: view.frame.width > view.frame.height, swiftyAds: swiftyAds)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { _ in
            self.swiftyAds.showBanner(isLandscape: size.width > size.height)
        })
    }

    // MARK: - Public Methods

    func configure(swiftyAds: SwiftyAdsType) {
        self.swiftyAds = swiftyAds
    }
}

// MARK: - Private Methods

private extension PlainViewController {
    
    @IBAction func showInterstitialAdButtonPressed(_ sender: Any) {
        AdPresenter.showInterstitialAd(from: self, swiftyAds: swiftyAds)
    }
    
    @IBAction func showRewardedAdButtonPressed(_ sender: Any) {
        AdPresenter.showRewardedAd(from: self, swiftyAds: swiftyAds, onReward: { rewardAmount in
            // update coins, diamonds etc
        })
    }
    
    @IBAction func disableAdsButtonPressed(_ sender: Any) {
        swiftyAds.disable()
    }
}
