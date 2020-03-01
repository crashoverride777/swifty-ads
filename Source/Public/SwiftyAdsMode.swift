//
//  SwiftyAdsMode.swift
//  SwiftyAdsDemo
//
//  Created by Dominik Ringler on 01/03/2020.
//  Copyright © 2020 Dominik Ringler. All rights reserved.
//

import Foundation

public enum SwiftyAdsMode {
    case production
    case debug(testDeviceIdentifiers: [String])
}
