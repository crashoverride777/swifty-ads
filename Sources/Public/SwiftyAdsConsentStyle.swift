//    The MIT License (MIT)
//
//    Copyright (c) 2015-2021 Dominik Ringler
//
//    Permission is hereby granted, free of charge, to any person obtaining a copy
//    of this software and associated documentation files (the "Software"), to deal
//    in the Software without restriction, including without limitation the rights
//    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//    copies of the Software, and to permit persons to whom the Software is
//    furnished to do so, subject to the following conditions:
//
//    The above copyright notice and this permission notice shall be included in all
//    copies or substantial portions of the Software.
//
//    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//    SOFTWARE.

import Foundation

public enum SwiftyAdsConsentStyle {
    case adMob(shouldOfferAdFree: Bool)
    case custom(content: SwiftyAdsCustomConsentAlertContent)
}

public struct SwiftyAdsCustomConsentAlertContent {
    public let title: String
    public let message: String
    public let actionAllowPersonalized: String
    public let actionAllowNonPersonalized: String
    public let actionAdFree: String?
    
    public init(title: String,
                message: String,
                actionAllowPersonalized: String,
                actionAllowNonPersonalized: String,
                actionAdFree: String?) {
        self.title = title
        self.message = message
        self.actionAllowPersonalized = actionAllowPersonalized
        self.actionAllowNonPersonalized = actionAllowNonPersonalized
        self.actionAdFree = actionAdFree
    }
}
