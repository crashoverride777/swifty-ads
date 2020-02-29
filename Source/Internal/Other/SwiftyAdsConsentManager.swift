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

public enum SwiftyAdsConsentStatus {
    case personalized
    case nonPersonalized
    case adFree
    case underAge
    case unknown
    
    public var hasConsent: Bool {
        switch self {
        case .personalized, .nonPersonalized:
            return true
        default:
            return false
        }
    }
}

protocol SwiftyAdsConsentManagerType: class {
    var status: SwiftyAdsConsentStatus { get }
    var isInEEA: Bool { get }
    var isRequiredToAskForConsent: Bool { get }
    var hasConsent: Bool { get }
    var isTaggedForUnderAgeOfConsent: Bool { get }
    func ask(from viewController: UIViewController,
             skipAlertIfAlreadyAuthorized: Bool,
             handler: @escaping (SwiftyAdsConsentStatus) -> Void)
    func statusDidChange(handler: @escaping (SwiftyAdsConsentStatus) -> Void)
}

final class SwiftyAdsConsentManager {

    // MARK: - Properties

    private let configuration: SwiftyAdsConfiguration
    private let consentStyle: SwiftyAdsConsentStyle
    private let consentInformation: PACConsentInformation = .sharedInstance
    private var statusDidChange: ((SwiftyAdsConsentStatus) -> Void)?
    
    // MARK: - Init
    
    init(configuration: SwiftyAdsConfiguration, consentStyle: SwiftyAdsConsentStyle) {
        self.consentStyle = consentStyle
        self.configuration = configuration
        consentInformation.isTaggedForUnderAgeOfConsent = configuration.isTaggedForUnderAgeOfConsent
    }
}

// MARK: - SwiftyAdsConsentManagerType

extension SwiftyAdsConsentManager: SwiftyAdsConsentManagerType {

    var status: SwiftyAdsConsentStatus {
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
    
    var isInEEA: Bool {
        consentInformation.isRequestLocationInEEAOrUnknown
    }
    
    var isRequiredToAskForConsent: Bool {
        guard isInEEA else { return false }
        guard !isTaggedForUnderAgeOfConsent else { return false } // must be non personalized only, cannot legally consent
        return true
    }
    
    var hasConsent: Bool {
        guard isInEEA else { return true }
        guard !isTaggedForUnderAgeOfConsent else { return false } // cannot legally consent, so cannot show ad
        return status != .unknown
    }

    var isTaggedForUnderAgeOfConsent: Bool {
        configuration.isTaggedForUnderAgeOfConsent
    }
    
    func ask(from viewController: UIViewController,
             skipAlertIfAlreadyAuthorized: Bool,
             handler: @escaping (SwiftyAdsConsentStatus) -> Void) {
        consentInformation.requestConsentInfoUpdate(forPublisherIdentifiers: configuration.ids) { [weak self] (_ error) in
            guard let self = self else { return }
            
            // Handle error
            if let error = error {
                print("SwiftyAdsConsentManager error requesting consent info update: \(error)")
                handler(self.status)
                self.statusDidChange?(self.status)
                return
            }
            
            // We only need to ask for consent if we are in the EEA
            guard self.isInEEA else {
                print("SwiftyAdsConsentManager not in EEA, no need to handle consent logic")
                self.consentInformation.consentStatus = .personalized
                handler(.personalized)
                self.statusDidChange?(.personalized)
                return
            }
            
            // We also do not need to ask for consent if under age is turned on
            // because than all add requests have to be non-personalized as a minor
            // cannot legally consent
            guard !self.isTaggedForUnderAgeOfConsent else {
                print("SwiftyAdsConsentManager under age, no need to handle consent logic as it must be non-personalized")
                handler(.underAge)
                self.statusDidChange?(.underAge)
                return
            }
            
            // Skip alert if needed
            if skipAlertIfAlreadyAuthorized, self.hasConsent {
                handler(self.status)
                self.statusDidChange?(self.status)
                return
            }
            
            // Show consent form
            switch self.consentStyle {
            case .adMob(let shouldOfferAdFree):
                self.showDefaultConsentForm(from: viewController, shouldOfferAdFree: shouldOfferAdFree) { [weak self] status in
                    guard let self = self else { return }
                    handler(status)
                    self.statusDidChange?(status)
                }
            case .custom(let content):
                self.showCustomConsentForm(from: viewController, content: content) { [weak self] status in
                    guard let self = self else { return }
                    handler(status)
                    self.statusDidChange?(status)
                }
            }
        }
    }
    
    func statusDidChange(handler: @escaping (SwiftyAdsConsentStatus) -> Void) {
        statusDidChange = handler
    }
}

// MARK: - Default Consent Form

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
}

// MARK: - Custom Consent Form

private extension SwiftyAdsConsentManager {
    
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
