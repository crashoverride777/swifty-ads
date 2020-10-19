//
//  TabBarController.swift
//  SwiftyAdsDemo
//
//  Created by Dominik Ringler on 19/10/2020.
//  Copyright © 2020 Dominik Ringler. All rights reserved.
//

import UIKit

final class TabBarController: UITabBarController {
    
    // MARK: - Properties
    
    private let swiftyAds: SwiftyAdsType = SwiftyAds.shared
    
    // MARK: - Init
    
    init() {
        super.init(nibName: nil, bundle: nil)
        
        // Create tab view controllers
        let firstVC = UIViewController()
        firstVC.view.backgroundColor = .white
        firstVC.tabBarItem = UITabBarItem(tabBarSystemItem: .downloads, tag: 0)
        
        let secondVC = UIViewController()
        secondVC.view.backgroundColor = .white
        secondVC.tabBarItem = UITabBarItem(tabBarSystemItem: .favorites, tag: 1)
        
        // Set view controllers
        viewControllers = [firstVC, secondVC]
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        AdPresenter.showBanner(from: self)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { _ in
            self.swiftyAds.updateBannerForOrientationChange(isLandscape: size.width > size.height)
        })
    }
}
