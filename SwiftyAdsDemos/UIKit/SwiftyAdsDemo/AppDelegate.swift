import UIKit
import SpriteKit
import AppTrackingTransparency
import SwiftyAds
import GoogleMobileAds
import UserMessagingPlatform

extension Notification.Name {
    static let adsConfigureCompletion = Notification.Name("AdsConfigureCompletion")
}

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    private let swiftyAds: SwiftyAdsType = SwiftyAds.shared
    private let notificationCenter: NotificationCenter = .default

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let navigationController = UINavigationController()
        let consentSelectionViewController = ConsentSelectionViewController(selection: { row in
            self.selected(row, navigationController: navigationController)
        })
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
    func selected(_ row: ConsentSelectionViewController.Row, navigationController: UINavigationController) {
        let geography = row.umpDebugGeography
        let demoSelectionViewController = DemoSelectionViewController(swiftyAds: self.swiftyAds, geography: geography)
        navigationController.setViewControllers([demoSelectionViewController], animated: true)
        if geography == .disabled {
            ATTrackingManager.requestTrackingAuthorization { _ in
                DispatchQueue.main.async {
                    self.configureSwiftyAds(from: navigationController, geography: geography)
                }
            }
        } else {
            self.configureSwiftyAds(from: navigationController, geography: geography)
        }
    }
    
    func configureSwiftyAds(from viewController: UIViewController, geography: UMPDebugGeography) {
        #if DEBUG
        swiftyAds.enableDebug(
            testDeviceIdentifiers: [],
            geography: geography,
            resetsConsentOnLaunch: true,
            isTaggedForChildDirectedTreatment: nil,
            isTaggedForUnderAgeOfConsent: false
        )
        #endif
        swiftyAds.configure(requestBuilder: AdsRequestBuilder(), mediationConfigurator: AdsMediationConfigurator())
        Task {
            do {
                try await swiftyAds.initializeIfNeeded(from: viewController)
                notificationCenter.post(name: .adsConfigureCompletion, object: nil)
            } catch {
                print(error)
            }
        }
    }
}

private extension ConsentSelectionViewController.Row {
    var umpDebugGeography: UMPDebugGeography {
        switch self {
        case .EEA:
            return .EEA
        case .other:
            return .other
        case .disabled:
            return .disabled
        }
    }
}
