import UIKit
import SpriteKit
import GoogleMobileAds

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    private let swiftyAds: SwiftyAdsType = SwiftyAds.shared

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        if let gameViewController = window?.rootViewController as? GameViewController {
            configureSwiftyAds(from: gameViewController)
        }
        return true
    }
}

// MARK: - Private Methods

private extension AppDelegate {
    
    func configureSwiftyAds(from gameViewController: GameViewController) {
        #if DEBUG
        let environment: SwiftyAdsEnvironment = .development(
            testDeviceIdentifiers: [],
            consentConfiguration: .resetOnLaunch(geography: .EEA)
        )
        #else
        let environment: SwiftyAdsEnvironment = .production
        #endif
        swiftyAds.configure(
            from: gameViewController,
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
            completion: ({ result in
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

                    // Ads are now ready to be displayed
                    gameViewController.adsConfigureCompletion()
                    
                case .failure(let error):
                    print("SwiftyAds did finish setup with error: \(error)")
                }
            })
        )
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
