import UIKit

final class TabBarControllerAd: UITabBarController {
    
    // MARK: - Properties
    
    private let swiftyAds: SwiftyAdsType
    
    // MARK: - Initialization
    
    init(swiftyAds: SwiftyAdsType) {
        self.swiftyAds = swiftyAds
        super.init(nibName: nil, bundle: nil)
        tabBar.barTintColor = .white

        // Create tab view controllers
        let firstVC = UIViewController()
        firstVC.view.backgroundColor = .blue
        firstVC.tabBarItem = UITabBarItem(tabBarSystemItem: .downloads, tag: 0)
        
        let secondVC = UIViewController()
        secondVC.view.backgroundColor = .red
        secondVC.tabBarItem = UITabBarItem(tabBarSystemItem: .favorites, tag: 1)
        
        // Set view controllers
        viewControllers = [firstVC, secondVC]
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        AdPresenter.prepareBanner(in: self, swiftyAds: swiftyAds)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AdPresenter.showBanner(isLandscape: view.frame.width > view.frame.height, swiftyAds: swiftyAds)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { [weak self] _ in
            guard let self = self else { return }
            AdPresenter.showBanner(isLandscape: size.width > size.height, swiftyAds: self.swiftyAds)
        })
    }
}
