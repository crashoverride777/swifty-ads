import UIKit

final class TabBarControllerNoAd: UITabBarController {

    // MARK: - Properties

    private let swiftyAds: SwiftyAdsType

    // MARK: - Initialization

    init(swiftyAds: SwiftyAdsType) {
        self.swiftyAds = swiftyAds
        super.init(nibName: nil, bundle: nil)
        tabBar.barTintColor = .white
        
        // Create tab view controllers
        let plainViewController = PlainViewController(swiftyAds: swiftyAds)
        plainViewController.tabBarItem = UITabBarItem(tabBarSystemItem: .downloads, tag: 0)
        
        let secondViewController = UIViewController()
        secondViewController.tabBarItem = UITabBarItem(tabBarSystemItem: .favorites, tag: 1)
        
        // Set view controllers
        viewControllers = [plainViewController, secondViewController]
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - De-Initialization

    deinit {
        print("Deinit TabBarControllerNoAd")
    }
}
