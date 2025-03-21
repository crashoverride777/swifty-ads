import UIKit
import SwiftyAds

final class PlainViewController: UIViewController {

    // MARK: - Properties

    private let swiftyAds: SwiftyAdsType
    private var bannerAd: SwiftyAdsBannerAd?
    
    private lazy var interstitialAdButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Show Interstitial ad", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.addTarget(self, action: #selector(showInterstitialAdButtonPressed), for: .touchUpInside)
        return button
    }()

    private lazy var rewardedAdButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Show rewarded ad", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.addTarget(self, action: #selector(showRewardedAdButtonPressed), for: .touchUpInside)
        return button
    }()

    private lazy var rewardedInterstitialAdButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Show rewarded interstitial ad", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.addTarget(self, action: #selector(showRewardedInterstitialAdButtonPressed), for: .touchUpInside)
        return button
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [interstitialAdButton, rewardedAdButton, rewardedInterstitialAdButton])
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

    // MARK: - De-Initialization

    deinit {
        print("Deinit PlainViewController")
    }
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        addSubviews()

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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        bannerAd?.show(isLandscape: view.frame.width > view.frame.height)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { [weak self] _ in
            self?.bannerAd?.show(isLandscape: size.width > size.height)
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
        Task { [weak self] in
            guard let self else { return }
            try await self.swiftyAds.showInterstitialAd(
                from: self,
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
    
    @objc func showRewardedAdButtonPressed() {
        Task { [weak self] in
            guard let self else { return }
            do {
                try await self.swiftyAds.showRewardedAd(
                    from: self,
                    onOpen: {
                        print("SwiftyAds rewarded ad did open")
                    },
                    onClose: {
                        print("SwiftyAds rewarded ad did close")
                    },
                    onError: { error in
                        print("SwiftyAds rewarded ad error \(error)")
                    },
                    onReward: ({ rewardAmount in
                        print("SwiftyAds rewarded ad did reward user with \(rewardAmount)")
                    })
                )
            } catch SwiftyAdsError.rewardedAdNotLoaded {
                let alertController = UIAlertController(
                    title: "Sorry",
                    message: "No video available to watch at the moment.",
                    preferredStyle: .alert
                )
                alertController.addAction(UIAlertAction(title: "Ok", style: .cancel))
                DispatchQueue.main.async { self.present(alertController, animated: true) }
            }
        }
    }

    @objc func showRewardedInterstitialAdButtonPressed() {
        Task { [weak self] in
            guard let self else { return }
            try await self.swiftyAds.showRewardedInterstitialAd(
                from: self,
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
