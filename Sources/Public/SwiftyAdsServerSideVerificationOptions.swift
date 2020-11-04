//
//  SwiftyAdsServerSideVerificationOptions.swift
//  SwiftyAdsDemo
//
//  Created by Majd Sabah on 11/4/20.
//  Copyright © 2020 Dominik Ringler. All rights reserved.
//

import Foundation

public final class SwiftyAdsServerSideVerificationOptions {
	
	public let uid: String?
	public let customString: String?
	
	public init(uid: String? = nil, customString: String? = nil) {
		
		self.uid = uid
		self.customString = customString
	}
}
