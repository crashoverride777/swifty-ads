import UIKit
import SpriteKit

extension Notification.Name {
    static let adsConfigureCompletion = Notification.Name("AdsConfigureCompletion")
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    private let swiftyAds: SwiftyAdsType = SwiftyAds.shared
    private let notificationCenter: NotificationCenter = .default

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        if let gameViewController = window?.rootViewController as? GameViewController {
            gameViewController.configure(swiftyAds: swiftyAds)
            configureSwiftyAds(from: gameViewController)
        }
        return true
    }
}

// MARK: - Private Methods

private extension AppDelegate {
    
    func configureSwiftyAds(from viewController: UIViewController) {
        #if DEBUG
        let environment: SwiftyAdsEnvironment = .development(
            testDeviceIdentifiers: [],
            consentConfiguration: .resetOnLaunch(geography: .EEA)
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

                // Ads are now ready to be displayed
                self.notificationCenter.post(name: .adsConfigureCompletion, object: nil)
            })
        )
    }
}
