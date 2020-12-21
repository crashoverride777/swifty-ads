//
//  AppDelegate.swift
//  Example
//
//  Created by Dominik Ringler on 21/02/2020.
//  Copyright © 2020 Dominik Ringler. All rights reserved.
//

import UIKit
import SpriteKit

extension Notification.Name {
    static let adConsentStatusDidChange = Notification.Name("adConsentStatusDidChange")
}

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
                NotificationCenter.default.post(name: .adConsentStatusDidChange, object: nil)
                if consentStatus != .notRequired {
                    // update mediation networks if required or preload ads
                }
            }),
            completion: ({ consentStatus in
                print("SwiftyAds did finish setup with consent status \(consentStatus)")
            })
        )
    }
}
