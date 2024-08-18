//    The MIT License (MIT)
//
//    Copyright (c) 2015-2024 Dominik Ringler
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

import UserMessagingPlatform
import GoogleMobileAds

/*
The SDK is designed to be used in a linear fashion. The steps for using the SDK are:

Request the latest consent information.
Check if consent is required.
Check if a form is available and if so load a form.
Present the form.
Provide a way for users to change their consent.
*/

protocol SwiftyAdsConsentManagerType: AnyObject {
    var consentStatus: SwiftyAdsConsentStatus { get }
    func request(from viewController: UIViewController) async throws
}

final class SwiftyAdsConsentManager {

    // MARK: - Properties

    private let consentInformation: UMPConsentInformation
    private let isTaggedForChildDirectedTreatment: Bool
    private let isTaggedForUnderAgeOfConsent: Bool
    private let mediationConfigurator: SwiftyAdsMediationConfigurator?
    private let environment: SwiftyAdsEnvironment
    private let mobileAds: GADMobileAds

    // MARK: - Initialization

    init(isTaggedForChildDirectedTreatment: Bool,
         isTaggedForUnderAgeOfConsent: Bool,
         mediationConfigurator: SwiftyAdsMediationConfigurator?,
         environment: SwiftyAdsEnvironment,
         mobileAds: GADMobileAds) {
        self.isTaggedForChildDirectedTreatment = isTaggedForChildDirectedTreatment
        self.isTaggedForUnderAgeOfConsent = isTaggedForUnderAgeOfConsent
        self.consentInformation = .sharedInstance
        self.mediationConfigurator = mediationConfigurator
        self.environment = environment
        self.mobileAds = mobileAds
    }
}

// MARK: - SwiftyAdsConsentManagerType

extension SwiftyAdsConsentManager: SwiftyAdsConsentManagerType {
    var consentStatus: SwiftyAdsConsentStatus {
        consentInformation.consentStatus
    }
    
    func request(from viewController: UIViewController) async throws {
        // Update consent status configuration when finished.
        defer {
            if consentStatus != .notRequired {
                configure(for: consentStatus)
            }
        }
        
        // Request consent information update.
        try await requestUpdate()
        
        // The consent information state was updated and we can now check if a form is available.
        switch consentInformation.formStatus {
        case .available:
            let form = try await loadForm()
            try await showForm(form, from: viewController)
        case .unavailable:
            // Showing a consent form is not required
            break
        case .unknown:
            // Should first request consent information update.
            break
        @unknown default:
            break
        }
    }
}

// MARK: - Private Methods

private extension SwiftyAdsConsentManager {
    func requestUpdate() async throws {
        // Create a UMPRequestParameters object.
        let parameters = UMPRequestParameters()
        parameters.tagForUnderAgeOfConsent = isTaggedForUnderAgeOfConsent
        
        if case .development(let developmentConfig) = environment {
            let debugSettings = UMPDebugSettings()
            debugSettings.testDeviceIdentifiers = developmentConfig.testDeviceIdentifiers
            debugSettings.geography = developmentConfig.geography
            parameters.debugSettings = debugSettings
            if developmentConfig.resetsConsentOnLaunch {
                consentInformation.reset()
            }
        }
        
        // Request an update to the consent information.
        // The first time we request consent information, even if outside of EEA, the status
        // may return `.required` as the ATT alert has not yet been displayed and we are using
        // Google Choices ATT message.
        try await consentInformation.requestConsentInfoUpdate(with: parameters)
    }
    
    func loadForm() async throws -> UMPConsentForm {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async {
                UMPConsentForm.load() { form, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else if let form {
                        continuation.resume(returning: form)
                    } else {
                        // Fallback but both values should never be nil.
                        continuation.resume(throwing: SwiftyAdsError.loadConsentForm)
                    }
                }
            }
        }
    }
    
    func showForm(_ form: UMPConsentForm, from viewController: UIViewController) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            DispatchQueue.main.async {
                form.present(from: viewController) { error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
            }
        }
    }
    
    func configure(for consentStatus: SwiftyAdsConsentStatus) {
        // Update mediation networks
        //
        // The GADMobileADs tagForUnderAgeOfConsent parameter is currently NOT forwarded to ad network
        // mediation adapters.
        // It is your responsibility to ensure that each third-party ad network in your application serves
        // ads that are appropriate for users under the age of consent per GDPR.
        mediationConfigurator?.updateGDPR(for: consentStatus, isTaggedForUnderAgeOfConsent: isTaggedForUnderAgeOfConsent)
        
        // Update GADMobileAds
        //
        // The tags to enable the child-directed setting and tagForUnderAgeOfConsent
        // should not both simultaneously be set to true.
        // If they are, the child-directed setting takes precedence.
        // https://developers.google.com/admob/ios/targeting#child-directed_setting
        guard !isTaggedForChildDirectedTreatment else { return }
        
        mobileAds.requestConfiguration.tagForUnderAgeOfConsent = NSNumber(value: isTaggedForUnderAgeOfConsent)
    }
}
