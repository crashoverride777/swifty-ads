//
//  NativeAdCell.swift
//  SwiftyAdsDemo
//
//  Created by Dominik Ringler on 21/12/2020.
//  Copyright © 2020 Dominik Ringler. All rights reserved.
//

import UIKit

final class NativeAdCell: UICollectionViewCell {

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.backgroundColor = .green
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
