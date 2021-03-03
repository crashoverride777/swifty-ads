import UIKit
import SpriteKit

extension Notification.Name {
    static let adConsentStatusDidChange = Notification.Name("adConsentStatusDidChange")
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    private let swiftyAds: SwiftyAdsType = SwiftyAds.shared
    private let notificationCenter: NotificationCenter = .default

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let navigationController = UINavigationController()
        let geographySelectionViewController = GeographySelectionViewController(swiftyAds: swiftyAds) { geography in
            let demoSelectionViewController = DemoSelectionViewController(swiftyAds: self.swiftyAds, geography: geography)
            navigationController.setViewControllers([demoSelectionViewController], animated: true)
            self.setupSwiftyAds(from: navigationController, geography: geography)
        }

        navigationController.setViewControllers([geographySelectionViewController], animated: false)

        window = UIWindow(frame: UIScreen.main.bounds)
        window?.backgroundColor = .white
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
        return true
    }
}

// MARK: - Private Methods

private extension AppDelegate {
    
    func setupSwiftyAds(from viewController: UIViewController, geography: SwiftyAdsDebugGeography) {
        #if DEBUG
        let environment: SwiftyAdsEnvironment = .development(
            testDeviceIdentifiers: [],
            consentConfiguration: geography == .disabled ? .disabled : .resetOnLaunch(geography: .EEA, isTaggedForUnderAgeOfConsent: false)
        )
        #else
        let environment: SwiftyAdsEnvironment = .production
        #endif
        swiftyAds.configure(
            from: viewController,
            for: environment,
            consentStatusDidChange: { status in
                switch status {
                case .notRequired:
                    print("SwiftyAds did change consent status: notRequired")
                case .required:
                    print("SwiftyAds did change consent status: required")
                case .obtained:
                    print("SwiftyAds did change consent status: obtained")
                case .unknown:
                    print("SwiftyAds did change consent status: unknown")
                @unknown default:
                    print("SwiftyAds did change consent status: unknown default")
                }
            },
            completion: ({ [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let consentStatus):
                    switch consentStatus {
                    case .notRequired:
                        print("SwiftyAds did finish setup with consent status: notRequired")
                    case .required:
                        print("SwiftyAds did finish setup with consent status: required")
                    case .obtained:
                        print("SwiftyAds did finish setup with consent status: obtained")
                    case .unknown:
                        print("SwiftyAds did finish setup with consent status: unknown")
                    @unknown default:
                        print("SwiftyAds did finish setup with consent status: unknown default")
                    }
                case .failure(let error):
                    print("SwiftyAds did finish setup with error: \(error)")
                }

                self.notificationCenter.post(name: .adConsentStatusDidChange, object: nil)
            })
        )
    }
}
