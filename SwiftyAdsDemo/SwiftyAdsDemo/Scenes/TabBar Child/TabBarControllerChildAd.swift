//
//  TabBarControllerNoAd.swift
//  SwiftyAdsDemo
//
//  Created by Dominik Ringler on 15/11/2020.
//  Copyright © 2020 Dominik Ringler. All rights reserved.
//

import UIKit

final class TabBarControllerNoAd: UITabBarController {
    init() {
        super.init(nibName: nil, bundle: nil)
        
        // Create tab view controllers
        let storyboard = UIStoryboard(name: "PlainViewController", bundle: .main)
        let firstVC = storyboard.instantiateInitialViewController()!
        firstVC.view.backgroundColor = .blue
        firstVC.tabBarItem = UITabBarItem(tabBarSystemItem: .downloads, tag: 0)
        
        let secondVC = UIViewController()
        secondVC.view.backgroundColor = .red
        secondVC.tabBarItem = UITabBarItem(tabBarSystemItem: .favorites, tag: 1)
        
        // Set view controllers
        viewControllers = [firstVC, secondVC]
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
