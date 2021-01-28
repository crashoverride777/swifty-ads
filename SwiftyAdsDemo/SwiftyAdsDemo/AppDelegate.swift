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
    private let notificationCenter: NotificationCenter = .default

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let rootViewController = RootViewController(swiftyAds: swiftyAds)
        let navigationController = UINavigationController(rootViewController: rootViewController)
        navigationController.navigationBar.barTintColor = .white

        window = UIWindow(frame: UIScreen.main.bounds)
        window?.backgroundColor = .white
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
        
        setupSwiftyAds(from: navigationController)
        return true
    }
}

// MARK: - Private Methods

private extension AppDelegate {
    
    func setupSwiftyAds(from rootViewController: UIViewController) {
        #if DEBUG
        let environment: SwiftyAdsEnvironment = .debug(testDeviceIdentifiers: [])
        #else
        let environment: SwiftyAdsEnvironment = .production
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
            environment: environment,
            consentStyle: .custom(content: customConsentContent),
            consentStatusDidChange: ({ [weak self] consentStatus in
                guard let self = self else { return }
                print("SwiftyAds did change consent status to \(consentStatus)")
                self.notificationCenter.post(name: .adConsentStatusDidChange, object: nil)
                // update mediation networks if required or preload ads
            }),
            completion: ({ consentStatus in
                print("SwiftyAds did finish setup with consent status \(consentStatus)")
            })
        )
    }
}
