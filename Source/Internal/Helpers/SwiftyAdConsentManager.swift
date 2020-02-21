//
//  SwiftyAdConsentManager.swift
//  SwiftyAd
//
//  Created by Dominik Ringler on 21/05/2019.
//  Copyright © 2019 Dominik. All rights reserved.
//

import UIKit
import PersonalizedAdConsent

public enum SwiftyAdConsentStatus {
    case personalized
    case nonPersonalized
    case adFree
    case unknown
}

protocol SwiftyAdConsentManagerType: class {
    var status: SwiftyAdConsentStatus { get }
    var isInEEA: Bool { get }
    var isRequiredToAskForConsent: Bool { get }
    var hasConsent: Bool { get }
    var isTaggedForUnderAgeOfConsent: Bool { get }
    func ask(from viewController: UIViewController,
             skipIfAlreadyAuthorized: Bool,
             handler: @escaping (SwiftyAdConsentStatus) -> Void)
}

final class SwiftyAdConsentManager {

    // MARK: - Properties

    private let ids: [String]
    private let configuration: SwiftyAdConsentConfiguration
    private let consentInformation: PACConsentInformation = .sharedInstance
    
    // MARK: - Init
    
    init(ids: [String], configuration: SwiftyAdConsentConfiguration) {
        self.ids = ids
        self.configuration = configuration
        consentInformation.isTaggedForUnderAgeOfConsent = configuration.isTaggedForUnderAgeOfConsent
    }
}

// MARK: - SwiftyAdConsentManagerType

extension SwiftyAdConsentManager: SwiftyAdConsentManagerType {

    var status: SwiftyAdConsentStatus {
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
             skipIfAlreadyAuthorized: Bool,
             handler: @escaping (SwiftyAdConsentStatus) -> Void) {
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
                @unknown default:
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
            if self.configuration.isCustomForm {
                self.showCustomConsentForm(from: viewController, handler: handler)
            } else {
                self.showDefaultConsentForm(from: viewController, handler: handler)
            }
        }
    }
}

// MARK: - Default Consent Form

private extension SwiftyAdConsentManager {
    
    func showDefaultConsentForm(from viewController: UIViewController,
                                handler: @escaping (SwiftyAdConsentStatus) -> Void) {
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
    
    func showCustomConsentForm(from viewController: UIViewController,
                               handler: @escaping (SwiftyAdConsentStatus) -> Void) {
        // Create alert message with all ad providers
        var message =
            SwiftyAdLocalizedString.consentMessage +
            "\n\n" +
            SwiftyAdLocalizedString.weShowAdsFrom +
            "Google AdMob, " +
            configuration.mediationNetworksString
        
        if let adProviders = consentInformation.adProviders, !adProviders.isEmpty {
            message += "\n\n" + SwiftyAdLocalizedString.weUseAdProviders + "\((adProviders.map({ $0.name })).joined(separator: ", "))"
        }
        message += "\n\n\(configuration.privacyPolicyURL)"
        
        // Create alert controller
        let alertController = UIAlertController(title: SwiftyAdLocalizedString.consentTitle, message: message, preferredStyle: .alert)
        
        // Personalized action
        let personalizedAction = UIAlertAction(title: SwiftyAdLocalizedString.allowPersonalized, style: .default) { action in
            self.consentInformation.consentStatus = .personalized
            handler(.personalized)
        }
        alertController.addAction(personalizedAction)
        
        // Non-Personalized action
        let nonPersonalizedAction = UIAlertAction(title: SwiftyAdLocalizedString.allowNonPersonalized, style: .default) { action in
            self.consentInformation.consentStatus = .nonPersonalized
            handler(.nonPersonalized)
        }
        alertController.addAction(nonPersonalizedAction)
        
        // Ad free action
        if configuration.shouldOfferAdFree {
            let adFreeAction = UIAlertAction(title: SwiftyAdLocalizedString.adFree, style: .default) { action in
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
