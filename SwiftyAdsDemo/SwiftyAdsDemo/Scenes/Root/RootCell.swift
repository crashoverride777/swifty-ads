//
//  RootViewControllerCell.swift
//  SwiftyAdsDemo
//
//  Created by Dominik Ringler on 19/10/2020.
//  Copyright © 2020 Dominik Ringler. All rights reserved.
//

import UIKit

final class RootCell: UITableViewCell {
    
    func configure(title: String) {
        textLabel?.text = title
    }
}
