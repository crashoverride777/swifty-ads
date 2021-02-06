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
        let environment: SwiftyAdsEnvironment = .debug(testDeviceIdentifiers: [], geography: .notEEA, resetConsentInfo: true)
        #else
        let environment: SwiftyAdsEnvironment = .production
        #endif
        swiftyAds.setup(
            from: rootViewController,
            for: environment,
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
                        print("SwiftyAds did finish setup with consent status: unknown")
                    }
                case .failure(let error):
                    print("SwiftyAds did finish setup with error: \(error)")
                }

                self.notificationCenter.post(name: .adConsentStatusDidChange, object: nil)
            })
        )
    }
}
