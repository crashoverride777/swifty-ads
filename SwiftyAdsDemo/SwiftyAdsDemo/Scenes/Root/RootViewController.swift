import UIKit

final class RootViewController: UITableViewController {
    
    // MARK: - Types

    enum Section: CaseIterable {
        case main
        case consent

        var rows: [Row] {
            switch self {
            case .main:
                return [
                    .viewController,
                    .viewControllerInsideTabBar,
                    .tabBarController,
                    .spriteKitScene,
                    .nativeAd,
                ]
            case .consent:
                return [.updateConsent]
            }
        }
    }
    
    enum Row {
        case viewController
        case viewControllerInsideTabBar
        case tabBarController
        case spriteKitScene
        case nativeAd
        case updateConsent
        
        var title: String {
            switch self {
            case .viewController:
                return "UIViewController"
            case .viewControllerInsideTabBar:
                return "UIViewController inside UITabBarController"
            case .tabBarController:
                return "UITabBarController"
            case .spriteKitScene:
                return "SKScene"
            case .nativeAd:
                return "Native Ad"
            case .updateConsent:
                return "Update Consent Status"
            }
        }
    }
    
    // MARK: - Properties

    private let swiftyAds: SwiftyAdsType
    private let sections = Section.allCases
    
    // MARK: - Initialization
    
    init(swiftyAds: SwiftyAdsType) {
        self.swiftyAds = swiftyAds
        if #available(iOS 13.0, *) {
            super.init(style: .insetGrouped)
        } else {
            super.init(style: .grouped)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Swifty Ads Demo"
        tableView.register(RootCell.self, forCellReuseIdentifier: String(describing: RootCell.self))
        
    }
    
    // MARK: - UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].rows.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = sections[indexPath.section].rows[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: RootCell.self), for: indexPath) as! RootCell
        cell.configure(title: row.title)
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = sections[indexPath.section].rows[indexPath.row]
        let viewController: UIViewController?
        
        switch row {
        case .viewController:
            let storyboard = UIStoryboard(name: "PlainViewController", bundle: .main)
            let plainViewController = storyboard.instantiateInitialViewController() as! PlainViewController
            plainViewController.configure(swiftyAds: swiftyAds)
            viewController = plainViewController

        case .viewControllerInsideTabBar:
            viewController = TabBarControllerNoAd(swiftyAds: swiftyAds)
        
        case .tabBarController:
            viewController = TabBarControllerAd(swiftyAds: swiftyAds)
        
        case .spriteKitScene:
            let storyboard = UIStoryboard(name: "GameViewController", bundle: .main)
            let gameViewController = storyboard.instantiateInitialViewController() as! GameViewController
            gameViewController.configure(swiftyAds: swiftyAds)
            viewController = gameViewController

        case .nativeAd:
            viewController = NativeAdViewController(swityAds: swiftyAds)

        case .updateConsent:
            tableView.deselectRow(at: indexPath, animated: true)
            
            swiftyAds.askForConsent(from: self) { result in
                switch result {
                case .success(let status):
                    print("SwiftyAds did change consent status to \(status)")
                case .failure(let error):
                    print("SwiftyAds consent status change error \(error)")
                }
            }
            return
        }
        
        guard let validViewController = viewController else { return }
        validViewController.navigationItem.title = row.title
        navigationController?.pushViewController(validViewController, animated: true)
    }
}

