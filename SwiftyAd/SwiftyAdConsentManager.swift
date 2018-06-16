//    The MIT License (MIT)
//
//    Copyright (c) 2015-2018 Dominik Ringler
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

/// LocalizedString
/// TODO
private extension String {
    static let consentTitle = "Permission to use data"
    static let consentMessage = "We care about your privacy and data security. We keep this app free by showing ads. You can change your choice anytime in the app settings. Our partners will collect data and use a unique identifier on your device to show you ads."
    static let ok = "OK"
    static let weShowAdsFrom = "We show ads from: "
    static let weUseAdProviders = "We use the following ad technology providers: "
    static let adFree = "Buy ad free app"
    static let allowPersonalized = "Allow personalized ads"
    static let allowNonPersonalized = "Allow non-personalized ads"
}

/**
 SwiftyAdConsentManager
 
 A class to manage consent request for Google AdMob (e.g GDPR).
 */
final class SwiftyAdConsentManager {

    // MARK: - Types
    
    struct Configuration {
        let privacyPolicyURL: String
        let shouldOfferAdFree: Bool
        let mediationNetworks: [String]
        let isTaggedForUnderAgeOfConsent: Bool
        let formType: FormType
        
        var mediationNetworksString: String {
            return mediationNetworks.map({ $0 }).joined(separator: ", ")
        }
    }
    
    enum FormType {
        case google
        case custom
    }
    
    enum ConsentStatus {
        case personalized
        case nonPersonalized
        case adFree
        case unknown
    }
    
    // MARK: - Properties
    
    /// The current status
    var status: ConsentStatus {
        switch consentInformation.consentStatus {
        case .personalized:
            return .personalized
        case .nonPersonalized:
            return .nonPersonalized
        case .unknown:
            return .unknown
        }
    }
    
    /// Check if user is in EEA (EU economic area)
    var isInEEA: Bool {
        return consentInformation.isRequestLocationInEEAOrUnknown
    }
    
    var isRequiredToAskForConsent: Bool {
        guard isInEEA else { return false }
        guard !isTaggedForUnderAgeOfConsent else { return false } // must be non personalized only, cannot legally consent
        return true
    }
    
    /// Check if we can show ads
    var hasConsent: Bool {
        guard isInEEA, !isTaggedForUnderAgeOfConsent else { return true }
        return status != .unknown
    }
    
    /// Check if under age is turned on
    var isTaggedForUnderAgeOfConsent: Bool {
        return configuration.isTaggedForUnderAgeOfConsent
    }
    
    /// Private
    private let ids: [String]
    private let configuration: Configuration
    private let consentInformation: PACConsentInformation = .sharedInstance
    
    // MARK: - Init
    
    init(ids: [String], configuration: Configuration) {
        self.ids = ids
        self.configuration = configuration
        consentInformation.isTaggedForUnderAgeOfConsent = configuration.isTaggedForUnderAgeOfConsent
    }
    
    // MARK: - Ask For Consent
    
    func ask(from viewController: UIViewController, skipIfAlreadyAuthorized: Bool = false, handler: @escaping (ConsentStatus) -> Void) {
        consentInformation.requestConsentInfoUpdate(forPublisherIdentifiers: ids) { (_ error) in
            if let error = error {
                print("SwiftyAdConsentManager error requesting consent info update: \(error)")
                handler(self.status)
                return
            }
            
            // If we already have permission dont ask again
            if skipIfAlreadyAuthorized {
                switch self.consentInformation.consentStatus {
                case .personalized:
                    print("SwiftyAdConsentManager already has consent permission, no need to ask again")
                    handler(self.status)
                    return
                case .nonPersonalized:
                    print("SwiftyAdConsentManager already has consent permission, no need to ask again")
                    handler(self.status)
                    return
                case .unknown:
                    break
                }
            }
            
            // We only need to ask for consent if we are in the EEA
            guard self.consentInformation.isRequestLocationInEEAOrUnknown else {
                print("SwiftyAdConsentManager not in EU, no need to handle consent logic")
                self.consentInformation.consentStatus = .personalized
                handler(.personalized)
                return
            }
            
            // We also do not need to ask for consent if under age is turned on because than all add requests have to be non-personalized
            guard !self.isTaggedForUnderAgeOfConsent else {
                self.consentInformation.consentStatus = .nonPersonalized
                print("SwiftyAdConsentManager under age, no need to handle consent logic as it must be non-personalized")
                handler(.nonPersonalized)
                return
            }
            
            // Show consent form
            switch self.configuration.formType {
            case .google:
                self.showDefaultConsentForm(from: viewController, handler: handler)
            case .custom:
                self.showCustomConsentForm(from: viewController, handler: handler)
            }
        }
    }
}

// MARK: - Default Consent Form

private extension SwiftyAdConsentManager {
    
    func showDefaultConsentForm(from viewController: UIViewController, handler: @escaping (ConsentStatus) -> Void) {
        // Make sure we have a valid privacy policy url
        guard let url = URL(string: configuration.privacyPolicyURL) else {
            print("SwiftyAdConsentManager invalid privacy policy URL")
            handler(status)
            return
        }
        
        // Make sure we have a valid consent form
        guard let form = PACConsentForm(applicationPrivacyPolicyURL: url) else {
            print("SwiftyAdConsentManager PACConsentForm nil")
            handler(status)
            return
        }
        
        // Set form properties
        form.shouldOfferPersonalizedAds = true
        form.shouldOfferNonPersonalizedAds = true
        form.shouldOfferAdFree = configuration.shouldOfferAdFree
        
        // Load form
        form.load { (_ error) in
            if let error = error {
                print("SwiftyAdConsentManager error loading consent form: \(error)")
                handler(self.status)
                return
            }
            
            // Loaded successfully, present it
            form.present(from: viewController) { (error, prefersAdFree) in
                if let error = error {
                    print("SwiftyAdConsentManager error presenting consent form: \(error)")
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

private extension SwiftyAdConsentManager {
    
    func showCustomConsentForm(from viewController: UIViewController, handler: @escaping (ConsentStatus) -> Void) {
        // Create alert message with all ad providers
        var message = .consentMessage + "\n\n" + .weShowAdsFrom + "Google AdMob, " + configuration.mediationNetworksString
        
        if let adProviders = consentInformation.adProviders, !adProviders.isEmpty {
            message += "\n\n" + .weUseAdProviders + "\((adProviders.map({ $0.name })).joined(separator: ", "))"
        }
        message += "\n\n\(configuration.privacyPolicyURL)"
        
        // Create alert controller
        let alertController = UIAlertController(title: .consentTitle, message: message, preferredStyle: .alert)
        
        // Personalized action
        let personalizedAction = UIAlertAction(title: .allowPersonalized, style: .default) { action in
            self.consentInformation.consentStatus = .personalized
            handler(.personalized)
        }
        alertController.addAction(personalizedAction)
        
        // Non-Personalized action
        let nonPersonalizedAction = UIAlertAction(title: .allowNonPersonalized, style: .default) { action in
            self.consentInformation.consentStatus = .nonPersonalized
            handler(.nonPersonalized)
        }
        alertController.addAction(nonPersonalizedAction)
        
        // Ad free action
        if configuration.shouldOfferAdFree {
            let adFreeAction = UIAlertAction(title: .adFree, style: .default) { action in
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
