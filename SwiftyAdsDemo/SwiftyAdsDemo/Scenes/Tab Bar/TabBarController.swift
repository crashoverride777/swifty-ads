//
//  TabBarController.swift
//  SwiftyAdsDemo
//
//  Created by Dominik Ringler on 19/10/2020.
//  Copyright © 2020 Dominik Ringler. All rights reserved.
//

import UIKit

final class TabBarController: UITabBarController {
    
    init() {
        super.init(nibName: nil, bundle: nil)
        let firstVC = UIViewController()
        firstVC.tabBarItem = UITabBarItem(tabBarSystemItem: .featured, tag: 0)
        firstVC.view.backgroundColor = .green
        viewControllers = [firstVC]
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
