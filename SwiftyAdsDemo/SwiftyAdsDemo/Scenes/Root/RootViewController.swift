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
        case plain
        case tabBar
        case game
        
        var title: String {
            switch self {
            case .plain:
                return "Plain View Controller"
            case .tabBar:
                return "TabBar View Controller"
            case .game:
                return "SpriteKit Game Scene"
            }
        }
    }
    
    // MARK: - Properties
    
    private let rows = Row.allCases
    
    // MARK: - Init
    
    init() {
        super.init(style: .grouped)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup table view
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
        case .plain:
            viewController = PlainViewController()
        case .tabBar:
            viewController = TabBarController()
        case .game:
            let storyboard = UIStoryboard(name: "GameViewController", bundle: .main)
            viewController = storyboard.instantiateInitialViewController()
        }
        
        guard let validViewController = viewController else { return }
        validViewController.navigationItem.title = row.title
        navigationController?.pushViewController(validViewController, animated: true)
    }
}
