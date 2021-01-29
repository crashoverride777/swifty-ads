//
//  RootViewController.swift
//  SwiftyAdsDemo
//
//  Created by Dominik Ringler on 19/10/2020.
//  Copyright © 2020 Dominik Ringler. All rights reserved.
//

import UIKit

final class RootViewController: UITableViewController {
    
    // MARK: - Types
    
    enum Row: CaseIterable {
        case viewController
        case viewControllerInsideTabBar
        case tabBarController
        case spriteKitScene
        case nativeAd
        case updateConsent
        
        var title: String {
            switch self {
            case .viewController:
                return "View Controller"
            case .viewControllerInsideTabBar:
                return "View Controller inside UITabBarController"
            case .tabBarController:
                return "Tab Bar Controller"
            case .spriteKitScene:
                return "SpriteKit Game Scene"
            case .nativeAd:
                return "Native Ad"
            case .updateConsent:
                return "Update Consent Status"
            }
        }
    }
    
    // MARK: - Properties

    private let swiftyAds: SwiftyAdsType
    private let rows = Row.allCases
    
    // MARK: - Initialization
    
    init(swiftyAds: SwiftyAdsType) {
        self.swiftyAds = swiftyAds
        super.init(style: .grouped)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup navigation item
        navigationItem.title = "Swifty Ads Demo"
        
        // Setup table view
        tableView.backgroundColor = .white
        tableView.register(RootCell.self, forCellReuseIdentifier: String(describing: RootCell.self))
        
    }
    
    // MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        rows.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = rows[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: RootCell.self), for: indexPath) as! RootCell
        cell.configure(title: row.title)
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = rows[indexPath.row]
        let viewController: UIViewController?
        
        switch row {
        case .viewController:
            let storyboard = UIStoryboard(name: "PlainViewController", bundle: .main)
            let plainViewController = storyboard.instantiateInitialViewController() as! PlainViewController
            plainViewController.configure(swiftyAds: swiftyAds)
            viewController = plainViewController

        case .viewControllerInsideTabBar:
            viewController = TabBarControllerNoAd(swiftyAds: swiftyAds)
        
        case .tabBarController:
            viewController = TabBarControllerAd(swiftyAds: swiftyAds)
        
        case .spriteKitScene:
            let storyboard = UIStoryboard(name: "GameViewController", bundle: .main)
            let gameViewController = storyboard.instantiateInitialViewController() as! GameViewController
            gameViewController.configure(swiftyAds: swiftyAds)
            viewController = gameViewController

        case .nativeAd:
            viewController = NativeAdViewController(swityAds: swiftyAds)

        case .updateConsent:
            tableView.deselectRow(at: indexPath, animated: true)
            
            swiftyAds.askForConsent(from: self) { result in
                switch result {
                case .success(let status):
                    print("SwiftyAds did change consent status to \(status)")
                case .failure(let error):
                    print("SwiftyAds consent status change error \(error)")
                }
            }
            return
        }
        
        guard let validViewController = viewController else { return }
        validViewController.navigationItem.title = row.title
        navigationController?.pushViewController(validViewController, animated: true)
    }
}

