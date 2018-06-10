//
//  SwiftyAdConsentManager.swift
//  SwiftyAdExample
//
//  Created by Dominik on 10/06/2018.
//  Copyright © 2018 Dominik. All rights reserved.
//

import UIKit
import PersonalizedAdConsent

/// LocalizedString
/// TODO
private extension String {
    static let alertTitle = "Permission to use data"
    static let alertMessage = "We care about your privacy and data security. We keep this app free by showing ads."
    static let ok = "OK"
}

/**
 SwiftyAdConsentManager
 
 A class to manage consent request for Google AdMob (e.g GDPR).
 */
final class SwiftyAdConsentManager {
    
    // MARK: - Types
    
    enum ConsentType {
        case personalized
        case nonPersonalized
        case adFree
        case unknown
        
        var hasPermission: Bool {
            return self != .unknown && self != .adFree
        }
    }
    
    // MARK: - Properties
    
    private(set) var consentType: ConsentType = .unknown
    
    private let ids: [String]
    private let privacyPolicyURL: String
    private let shouldOfferAdFree: Bool
    
    // MARK: - Init
    
    init(ids: [String], privacyPolicyURL: String, shouldOfferAdFree: Bool) {
        self.ids = ids
        self.privacyPolicyURL = privacyPolicyURL
        self.shouldOfferAdFree = shouldOfferAdFree
    }
    
    // MARK: - Methods
    
    func ask(from viewController: UIViewController, skipIfAlreadyAuthorized: Bool = false, handler: @escaping (ConsentType) -> Void) {
        let consentInformation = PACConsentInformation.sharedInstance

        // Make sure we have publisher ids
        guard !ids.isEmpty else {
            consentType = .personalized
            print("SwiftyAd no publisher ids, we are in debug mode")
            handler(consentType)
            return
        }
        
        // If we already have permission dont ask again
        if skipIfAlreadyAuthorized {
            switch consentInformation.consentStatus {
            case .personalized:
                consentType = .personalized
                print("SwiftAd already has consent permission, no need to ask again")
                handler(consentType)
                return
            case .nonPersonalized:
                consentType = .nonPersonalized
                print("SwiftAd already has consent permission, no need to ask again")
                handler(consentType)
                return
            default:
                break
            }
        }
        
        // Request consent info updates
        consentInformation.requestConsentInfoUpdate(forPublisherIdentifiers: ids) { (_ error) in
            if let error = error {
                print(error)
                self.consentType = .unknown
                handler(self.consentType)
                return
            }
            
            // We only need to ask for consent if we are in the EU
            guard consentInformation.isRequestLocationInEEAOrUnknown else {
                self.consentType = .personalized
                print("SwiftyAd NOT in EU, no need to handle consent logic")
                handler(self.consentType)
                return
            }
            
            // Show consent form in EU countries
            self.showConsentForm(from: viewController, handler: handler)
        }
    }
}

// MARK: - Default Consent Form

private extension SwiftyAdConsentManager {
    
    func showConsentForm(from viewController: UIViewController, handler: @escaping (ConsentType) -> Void) {
        let consentInformation = PACConsentInformation.sharedInstance
        
        // Make sure we have a valid privacy policy url
        guard let url = URL(string: privacyPolicyURL) else {
            print("SwiftyAd Invalid consent URL")
            consentType = .unknown
            handler(consentType)
            return
        }
        
        // Make sure we have a valid consent form
        guard let form = PACConsentForm(applicationPrivacyPolicyURL: url) else {
            print("SwiftyAd PACConsentForm error")
            consentType = .unknown
            handler(consentType)
            return
        }
        
        // Set form properties
        form.shouldOfferPersonalizedAds = true
        form.shouldOfferNonPersonalizedAds = true
        form.shouldOfferAdFree = shouldOfferAdFree
        
        // Load form
        form.load { (_ error) in
            if let error = error {
                print("SwiftyAd Error loading consent form: \(error)")
                self.consentType = .unknown
                handler(self.consentType)
                return
            }
            
            // Loaded successfully, present it
            form.present(from: viewController) { (error, prefersAdFree) in
                if let error = error {
                    print(error)
                    self.consentType = .unknown
                    handler(self.consentType)
                    return
                }
                
                guard !prefersAdFree else {
                    // User prefers to use a paid version of the app.
                    self.consentType = .adFree
                    handler(self.consentType)
                    return
                    
                }
                
                // Consent info update succeeded. The shared PACConsentInformation instance has been updated.
                // Update admob SDK
                switch consentInformation.consentStatus {
                    
                case .personalized:
                    self.consentType = .personalized
                    print("SwiftyAd PERSONALIZED consent")
                    
                case .nonPersonalized:
                    self.consentType = .nonPersonalized
                    print("SwiftyAd NON PERSONALIZED consent")
                    
                case .unknown:
                    print("SwiftyAd UNKNOWN consent")
                    self.consentType = .unknown
                }
                
                handler(self.consentType)
            }
        }
    }
}

// MARK: - Custom Consent Form

private extension SwiftyAdConsentManager {
    
    func showCustomConsentForm(from viewController: UIViewController, handler: (ConsentType) -> Void) {
        let alertController = UIAlertController(title: .alertTitle, message: .alertMessage, preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: .ok, style: .cancel))
        
        DispatchQueue.main.async {
            viewController.present(alertController, animated: true)
        }
    }
}
