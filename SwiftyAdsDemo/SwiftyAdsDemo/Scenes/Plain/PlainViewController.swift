import UIKit

final class PlainViewController: UIViewController {

    // MARK: - Properties

    private var swiftyAds: SwiftyAdsType!
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .blue

        swiftyAds.prepareBanner(
            in: self,
            adUnitIdType: .plist,
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
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        swiftyAds.showBanner(isLandscape: view.frame.width > view.frame.height)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { [weak self] _ in
            self?.swiftyAds.showBanner(isLandscape: size.width > size.height)
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
        swiftyAds.showInterstitial(
            from: self,
            withInterval: 2,
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
    }
    
    @IBAction func showRewardedAdButtonPressed(_ sender: Any) {
        swiftyAds.showRewardedVideo(
            from: self,
            onOpen: ({
                print("SwiftyAds rewarded video ad did open")
            }),
            onClose: ({
                print("SwiftyAds rewarded video ad did close")
            }),
            onError: ({ error in
                print("SwiftyAds rewarded video ad error \(error)")
            }),
            onNotReady: ({ [weak self] in
                guard let self = self else { return }
                let alertController = UIAlertController(
                    title: "Sorry",
                    message: "No video available to watch at the moment.",
                    preferredStyle: .alert
                )
                alertController.addAction(UIAlertAction(title: "Ok", style: .cancel))
                DispatchQueue.main.async {
                    self.present(alertController, animated: true)
                }
            }),
            onReward: ({ rewardAmount in
                print("SwiftyAds rewarded video ad did reward user with \(rewardAmount)")
            })
        )
    }
}
