//
//  AppDelegate.swift
//  Example
//
//  Created by Dominik Ringler on 21/02/2020.
//  Copyright © 2020 Dominik Ringler. All rights reserved.
//

import UIKit
import SpriteKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    private let swiftyAds: SwiftyAdsType = SwiftyAds.shared

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let rootViewController = RootViewController()
        let navigationController = UINavigationController(rootViewController: rootViewController)
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
        
        setupSwiftyAds(from: navigationController)
        return true
    }
}

// MARK: - Private

private extension AppDelegate {
    
    func setupSwiftyAds(from rootViewController: UIViewController) {
        #if DEBUG
        let mode: SwiftyAdsMode = .debug(testDeviceIdentifiers: [])
        #else
        let mode: SwiftyAdsMode = .production
        #endif
        let customConsentContent = SwiftyAdsCustomConsentAlertContent(
            title: "Permission to use data",
            message: "We care about your privacy and data security. We keep this app free by showing ads. You can change your choice anytime in the app settings. Our partners will collect data and use a unique identifier on your device to show you ads.",
            actionAllowPersonalized: "Allow personalized",
            actionAllowNonPersonalized: "Allow non personalized",
            actionAdFree: nil // no add free option in this demo
        )
        
        swiftyAds.setup(
            with: rootViewController,
            mode: mode,
            consentStyle: .custom(content: customConsentContent),
            consentStatusDidChange: ({ consentStatus in
                print("SwiftyAds did change consent status to \(consentStatus)")
//                let skView = self.view as? SKView
//                (skView?.scene as? GameScene)?.refresh()
//
//                if consentStatus != .notRequired {
//                    // update mediation networks if required
//                }
            }),
            completion: ({ status in
//                guard status.hasConsent else { return }
//                DispatchQueue.main.async {
//                    self.showBanner()
//                }
            })
        )
    }
    
//    func showBanner() {
//        swiftyAds.showBanner(
//            from: self,
//            atTop: false,
//            ignoresSafeArea: false,
//            animationDuration: 1.5,
//            onOpen: ({
//                print("SwiftyAds banner ad did open")
//            }),
//            onClose: ({
//                print("SwiftyAds banner ad did close")
//            }),
//            onError: ({ error in
//                print("SwiftyAds banner ad error \(error)")
//            })
//        )
//    }
}
