import UIKit
import SpriteKit
import GoogleMobileAds
import SwiftyAds

@main
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
    func configureSwiftyAds(from viewController: GameViewController) {
        #if DEBUG
        swiftyAds.enableDebug(
            testDeviceIdentifiers: [],
            geography: .EEA,
            resetsConsentOnLaunch: true,
            isTaggedForChildDirectedTreatment: nil,
            isTaggedForUnderAgeOfConsent: false
        )
        #endif
        swiftyAds.configure(requestBuilder: AdsRequestBuilder(), mediationConfigurator: AdsMediationConfigurator())
        Task {
            do {
                try await swiftyAds.initializeIfNeeded(from: viewController)
                (window?.rootViewController as? GameViewController)?.adsConfigureCompletion()
            } catch {
                print(error)
            }
        }
    }
}
