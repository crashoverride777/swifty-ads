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

import UIKit
import PersonalizedAdConsent

protocol SwiftyAdsConsentManagerType: class {
    var status: SwiftyAdsConsentStatus { get }
    func requestUpdate(handler: @escaping (SwiftyAdsConsentStatus) -> Void)
    func showForm(from viewController: UIViewController, handler: ((SwiftyAdsConsentStatus) -> Void)?)
}

final class SwiftyAdsConsentManager {

    // MARK: - Properties

    private let consentInformation: PACConsentInformation
    private let configuration: SwiftyAdsConfiguration
    private let consentStyle: SwiftyAdsConsentStyle
    private let statusDidChange: (SwiftyAdsConsentStatus) -> Void
    
    // MARK: - Init
    
    init(consentInformation: PACConsentInformation,
         configuration: SwiftyAdsConfiguration,
         consentStyle: SwiftyAdsConsentStyle,
         statusDidChange: @escaping (SwiftyAdsConsentStatus) -> Void) {
        self.consentInformation = consentInformation
        self.consentStyle = consentStyle
        self.configuration = configuration
        self.statusDidChange = statusDidChange
    }
}

// MARK: - SwiftyAdsConsentManagerType

extension SwiftyAdsConsentManager: SwiftyAdsConsentManagerType {

    var status: SwiftyAdsConsentStatus {
        guard consentInformation.isRequestLocationInEEAOrUnknown else {
            return .notRequired
        }
        
        guard !configuration.isTaggedForUnderAgeOfConsent else {
            return .underAge
        }
        
        switch consentInformation.consentStatus {
        case .personalized:
            return .personalized
        case .nonPersonalized:
            return .nonPersonalized
        case .unknown:
            return .unknown
        @unknown default:
            return .unknown
        }
    }
    
    func requestUpdate(handler: @escaping (SwiftyAdsConsentStatus) -> Void) {
        consentInformation.requestConsentInfoUpdate(forPublisherIdentifiers: configuration.ids) { [weak self] (_ error) in
            guard let self = self else { return }
            
            if self.configuration.isTaggedForUnderAgeOfConsent {
                self.consentInformation.isTaggedForUnderAgeOfConsent = true
            }
            
            if let error = error {
                print("SwiftyAdsConsentManager error requesting consent info update: \(error)")
                handler(self.status)
                return
            }
            
            handler(self.status)
        }
    }

    func showForm(from viewController: UIViewController, handler: ((SwiftyAdsConsentStatus) -> Void)?) {
        switch consentStyle {
        case .adMob(let shouldOfferAdFree):
            showDefaultConsentForm(from: viewController, shouldOfferAdFree: shouldOfferAdFree) { [weak self] status in
                guard let self = self else { return }
                handler?(status)
                self.statusDidChange(status)
            }
        case .custom(let content):
            showCustomConsentForm(from: viewController, content: content) { [weak self] status in
                guard let self = self else { return }
                handler?(status)
                self.statusDidChange(status)
            }
        }
    }
}

// MARK: - Private Methods

private extension SwiftyAdsConsentManager {
    
    func showDefaultConsentForm(from viewController: UIViewController,
                                shouldOfferAdFree: Bool,
                                handler: @escaping (SwiftyAdsConsentStatus) -> Void) {
        // Make sure we have a valid privacy policy url
        guard let url = URL(string: configuration.privacyPolicyURL) else {
            print("SwiftyAdsConsentManager invalid privacy policy URL")
            handler(status)
            return
        }
        
        // Make sure we have a valid consent form
        guard let form = PACConsentForm(applicationPrivacyPolicyURL: url) else {
            print("SwiftyAdsConsentManager PACConsentForm nil")
            handler(status)
            return
        }
        
        // Set form properties
        form.shouldOfferPersonalizedAds = true
        form.shouldOfferNonPersonalizedAds = true
        form.shouldOfferAdFree = shouldOfferAdFree
        
        // Load form
        form.load { (_ error) in
            if let error = error {
                print("SwiftyAdsConsentManager error loading consent form: \(error)")
                handler(self.status)
                return
            }
            
            // Loaded successfully, present it
            form.present(from: viewController) { (error, prefersAdFree) in
                if let error = error {
                    print("SwiftyAdsConsentManager error presenting consent form: \(error)")
                    handler(self.status)
                    return
                }
                
                // Check if user prefers to use a paid version of the app (shouldOfferAdFree button)
                guard !prefersAdFree else {
                    self.consentInformation.consentStatus = .unknown
                    handler(.adFree)
                    return
                }
                
                // Consent info update succeeded. The shared PACConsentInformation instance has been updated
                handler(self.status)
            }
        }
    }

    func showCustomConsentForm(from viewController: UIViewController,
                               content: SwiftyAdsCustomConsentAlertContent,
                               handler: @escaping (SwiftyAdsConsentStatus) -> Void) {
        // Create alert message with all ad providers
        let message =
            content.message +
            "\n\n" + configuration.adNetworks +
            "\n\n" + configuration.privacyPolicyURL
        
        // Create alert controller
        let alertController = UIAlertController(title: content.title, message: message, preferredStyle: .alert)
        
        // Personalized action
        let personalizedAction = UIAlertAction(title: content.actionAllowPersonalized, style: .default) { action in
            self.consentInformation.consentStatus = .personalized
            handler(.personalized)
        }
        alertController.addAction(personalizedAction)
        
        // Non-Personalized action
        let nonPersonalizedAction = UIAlertAction(title: content.actionAllowNonPersonalized, style: .default) { action in
            self.consentInformation.consentStatus = .nonPersonalized
            handler(.nonPersonalized)
        }
        alertController.addAction(nonPersonalizedAction)
        
        // Ad free action
        if let actionAdFree = content.actionAdFree {
            let adFreeAction = UIAlertAction(title: actionAdFree, style: .default) { action in
                self.consentInformation.consentStatus = .unknown
                handler(.adFree)
            }
            alertController.addAction(adFreeAction)
        }
        
        // Present alert
        DispatchQueue.main.async {
            viewController.present(alertController, animated: true)
        }
    }
}
