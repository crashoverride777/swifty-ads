//    The MIT License (MIT)
//
//    Copyright (c) 2015-2020 Dominik Ringler
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

enum SwiftyAdLocalizedString {
    static let sorry = localized("Sorry", comment: "Sorry")
    static let ok = localized("Ok", comment: "Ok")
    static let noVideo = localized("NoVideo", comment: "No video available to watch at the moment.")
    
    // Consent
    static let consentTitle = localized("ConsentTitle", comment: "Permission to use data")
    static let consentMessage = localized("ConsentMessage", comment: "We care about your privacy and data security. We keep this app free by showing ads. You can change your choice anytime in the app settings. Our partners will collect data and use a unique identifier on your device to show you ads.")
    static let weShowAdsFrom = localized("WeShowAdsFrom", comment: "We show ads from: ")
    static let weUseAdProviders = localized("WeUseAdProviders", comment: "We use the following ad technology providers: ")
    static let adFree = localized("AdFree", comment: "Buy ad free app") // ?
    static let allowPersonalized = localized("AllowPersonalized", comment: "Allow personalized ads")
    static let allowNonPersonalized = localized("AllowNonPersonalized", comment: "Allow non-personalized ads")
}

// MARK: - Get Localized String

private extension SwiftyAdLocalizedString {
    
    static func localized(_ text: String, comment: String, argument: CVarArg? = nil, argument2: CVarArg? = nil) -> String {
        return NSLocalizedString(text, tableName: nil, bundle: Bundle(for: SwiftyAds.self), value: "", comment: comment)
    }
}
