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
    var isTaggedForChildDirectedTreatment: Bool { get }
    var isTaggedForUnderAgeOfConsent: Bool { get }
    @discardableResult
    func request(from viewController: UIViewController) async throws -> SwiftyAdsConsentStatus
}

final class SwiftyAdsConsentManager {

    // MARK: - Properties

    private let consentInformation: UMPConsentInformation
    private let configuration: SwiftyAdsConsentConfiguration
    private let environment: SwiftyAdsEnvironment
    private let mediationConfigurator: SwiftyAdsMediationConfiguratorType?
    private let mobileAds: GADMobileAds
    private let consentStatusDidChange: (SwiftyAdsConsentStatus) -> Void

    private var form: UMPConsentForm?

    // MARK: - Initialization

    init(configuration: SwiftyAdsConsentConfiguration,
         environment: SwiftyAdsEnvironment,
         mediationConfigurator: SwiftyAdsMediationConfiguratorType?,
         mobileAds: GADMobileAds,
         consentStatusDidChange: @escaping (SwiftyAdsConsentStatus) -> Void) {
        self.consentInformation = .sharedInstance
        self.configuration = configuration
        self.environment = environment
        self.mediationConfigurator = mediationConfigurator
        self.mobileAds = mobileAds
        self.consentStatusDidChange = consentStatusDidChange
        
        updateCOPPA()
    }
}

// MARK: - SwiftyAdsConsentManagerType

extension SwiftyAdsConsentManager: SwiftyAdsConsentManagerType {
    var consentStatus: SwiftyAdsConsentStatus {
        consentInformation.consentStatus
    }
    
    var isTaggedForChildDirectedTreatment: Bool {
        configuration.isTaggedForChildDirectedTreatment
    }

    var isTaggedForUnderAgeOfConsent: Bool {
        configuration.isTaggedForUnderAgeOfConsent
    }
    
    @discardableResult
    func request(from viewController: UIViewController) async throws -> SwiftyAdsConsentStatus {
        try await requestUpdate()
        let consentStatus = try await showForm(from: viewController)
        // If consent form was used to update consentStatus we need to update GDPR settings.
        if consentStatus != .notRequired {
            updateGDPR(consentStatus: consentStatus)
        }
        return consentStatus
    }
}

// MARK: - Private Methods

private extension SwiftyAdsConsentManager {
    func requestUpdate() async throws {
        // Create a UMPRequestParameters object.
        let parameters = UMPRequestParameters()

        // Set UMPDebugSettings if in development environment.
        switch environment {
        case .production:
            break
        case .development(let testDeviceIdentifiers, let consentConfiguration):
            let debugSettings = UMPDebugSettings()
            debugSettings.testDeviceIdentifiers = testDeviceIdentifiers
            debugSettings.geography = consentConfiguration.geography
            parameters.debugSettings = debugSettings

            if case .resetOnLaunch = consentConfiguration {
                consentInformation.reset()
            }
        }
        
        // Update parameters for under age of consent.
        parameters.tagForUnderAgeOfConsent = isTaggedForUnderAgeOfConsent

        // Request an update to the consent information.
        // The first time we request consent information, even if outside of EEA, the status
        // may return `.required` as the ATT alert has not yet been displayed and we are using
        // Google Choices ATT message.
        try await consentInformation.requestConsentInfoUpdate(with: parameters)
        
        // The consent information state was updated and we can now check if a form is available.
        if consentInformation.formStatus == .available {
            form = try await UMPConsentForm.load()
        }
    }
    
    func showForm(from viewController: UIViewController) async throws -> SwiftyAdsConsentStatus {
        // Ensure form is loaded
        guard let form = form else {
            throw SwiftyAdsError.consentFormNotAvailable
        }

        // Present the form
        try await form.present(from: viewController)
        let consentStatus = self.consentStatus
        consentStatusDidChange(consentStatus)
        return consentStatus
    }
    
    func updateCOPPA() {
        // Update mediation networks
        mediationConfigurator?.updateCOPPA(isTaggedForChildDirectedTreatment: isTaggedForChildDirectedTreatment)
        
        // Update GADMobileAds
        mobileAds.requestConfiguration.tagForChildDirectedTreatment = NSNumber(value: isTaggedForChildDirectedTreatment)
    }
    
    func updateGDPR(consentStatus: SwiftyAdsConsentStatus) {
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
