import UIKit

final class RootViewController: UITableViewController {
    
    // MARK: - Types

    enum Section: CaseIterable {
        case main
        case secondary

        var rows: [Row] {
            switch self {
            case .main:
                return [
                    .viewController,
                    .viewControllerInsideTabBar,
                    .tabBarController,
                    .spriteKitScene,
                    .nativeAd
                ]
            case .secondary:
                return [
                    .updateConsent,
                    .disable
                ]
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
        case disable

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
            case .disable:
                return "Disable Ads"
            }
        }

        var shouldDeselect: Bool {
            switch self {
            case .updateConsent, .disable:
                return true
            default:
                return false
            }
        }
    }
    
    // MARK: - Properties

    private let swiftyAds: SwiftyAdsType
    private let sections = Section.allCases
    private let notificationCenter: NotificationCenter = .default

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

        notificationCenter.addObserver(self, selector: #selector(consentDidChange), name: .adConsentStatusDidChange, object: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard swiftyAds.hasConsent else { return } // for demo purposes to make sure it does not get called before consent did change notification
        swiftyAds.showBanner(isLandscape: view.frame.width > view.frame.height)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { [weak self] _ in
            self?.swiftyAds.showBanner(isLandscape: size.width > size.height)
        })
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
        var viewController: UIViewController?

        if row.shouldDeselect {
            tableView.deselectRow(at: indexPath, animated: true)
        }
        
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
            swiftyAds.askForConsent(from: self) { result in
                switch result {
                case .success(let status):
                    print("SwiftyAds did change consent status to \(status)")
                case .failure(let error):
                    print("SwiftyAds consent status change error \(error)")
                }
            }

        case .disable:
            swiftyAds.disable()
        }
        
        guard let validViewController = viewController else { return }
        validViewController.navigationItem.title = row.title
        navigationController?.pushViewController(validViewController, animated: true)
    }
}

// MARK: - Private Methods

private extension RootViewController {

    @objc func consentDidChange() {
        swiftyAds.showBanner(isLandscape: view.frame.width > view.frame.height)
    }
}
