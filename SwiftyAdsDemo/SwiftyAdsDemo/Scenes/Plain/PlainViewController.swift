import UIKit

final class PlainViewController: UIViewController {

    // MARK: - Properties

    private let swiftyAds: SwiftyAdsType

    private lazy var interstitialAdButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Show Interstitial ad (2 interval)", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(showInterstitialAdButtonPressed), for: .touchUpInside)
        return button
    }()

    private lazy var rewardedAdButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Show rewarded ad", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(showRewardedAdButtonPressed), for: .touchUpInside)
        return button
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [interstitialAdButton, rewardedAdButton])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 32
        return stackView
    }()

    // MARK: - Init

    init(swiftyAds: SwiftyAdsType) {
        self.swiftyAds = swiftyAds
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .blue
        addSubviews()

        swiftyAds.prepareBannerAd(
            in: self,
            adUnitIdType: .plist,
            position: .bottom(isUsingSafeArea: true),
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
        swiftyAds.showBannerAd(isLandscape: view.frame.width > view.frame.height)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { [weak self] _ in
            self?.swiftyAds.showBannerAd(isLandscape: size.width > size.height)
        })
    }
}

// MARK: - Private Methods

private extension PlainViewController {

    func addSubviews() {
        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    @objc func showInterstitialAdButtonPressed() {
        swiftyAds.showInterstitialAd(
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
    
    @objc func showRewardedAdButtonPressed() {
        swiftyAds.showRewardedAd(
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
