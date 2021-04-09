import UIKit
import SpriteKit
import AppTrackingTransparency
import GoogleMobileAds

extension Notification.Name {
    static let adsConfigureCompletion = Notification.Name("AdsConfigureCompletion")
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    private let swiftyAds: SwiftyAdsType = SwiftyAds.shared
    private let notificationCenter: NotificationCenter = .default

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let navigationController = UINavigationController()
        let consentSelectionViewController = ConsentSelectionViewController(swiftyAds: swiftyAds) { geography in
            let consentConfiguration: SwiftyAdsEnvironment.ConsentConfiguration = geography == .disabled ?
                .disabled :
                .resetOnLaunch(geography: geography)
            let demoSelectionViewController = DemoSelectionViewController(swiftyAds: self.swiftyAds, consentConfiguration: consentConfiguration)
            navigationController.setViewControllers([demoSelectionViewController], animated: true)

            if geography == .disabled {
                self.requestTrackingAuthorization {
                    self.configureSwiftyAds(from: navigationController, consentConfiguration: consentConfiguration)
                }
            } else {
                self.configureSwiftyAds(from: navigationController, consentConfiguration: consentConfiguration)
            }
        }

        navigationController.setViewControllers([consentSelectionViewController], animated: false)

        window = UIWindow(frame: UIScreen.main.bounds)
        window?.backgroundColor = .white
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
        return true
    }
}

// MARK: - Private Methods

private extension AppDelegate {
    
    func configureSwiftyAds(from viewController: UIViewController, consentConfiguration: SwiftyAdsEnvironment.ConsentConfiguration) {
        #if DEBUG
        let environment: SwiftyAdsEnvironment = .development(testDeviceIdentifiers: [], consentConfiguration: consentConfiguration)
        #else
        let environment: SwiftyAdsEnvironment = .production
        #endif
        swiftyAds.configure(
            from: viewController,
            for: environment,
            requestBuilder: SwiftyAdsRequestBuilder(),
            mediationConfigurator: SwiftyAdsMediationConfigurator(),
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


    func requestTrackingAuthorization(completion: @escaping () -> Void) {
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { _ in
                DispatchQueue.main.async {
                    completion()
                }
            }
        } else {
            completion()
        }
    }
}

// MARK: - SwiftyAdsRequestBuilder

private final class SwiftyAdsRequestBuilder: SwiftyAdsRequestBuilderType {
    func build() -> GADRequest {
        GADRequest()
    }
}

// MARK: - SwiftyAdsMediationConfiguratorType

private final class SwiftyAdsMediationConfigurator: SwiftyAdsMediationConfiguratorType {
    func updateCOPPA(isTaggedForChildDirectedTreatment: Bool) {
        print("SwiftyAdsMediationConfigurator update COPPA", isTaggedForChildDirectedTreatment)
    }
    
    func updateGDPR(for consentStatus: SwiftyAdsConsentStatus, isTaggedForUnderAgeOfConsent: Bool) {
        print("SwiftyAdsMediationConfigurator update GDPR")
    }
}
