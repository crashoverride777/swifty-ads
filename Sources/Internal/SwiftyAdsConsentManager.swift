//    The MIT License (MIT)
//
//    Copyright (c) 2015-2023 Dominik Ringler
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

public protocol SwiftyAdsConsentManagerType: AnyObject {
    var consentStatus: SwiftyAdsConsentStatus { get }
    var isTaggedForChildDirectedTreatment: Bool { get }
    var isTaggedForUnderAgeOfConsent: Bool { get }
    func start(from viewController: UIViewController, completion: @escaping (Result<SwiftyAdsConsentStatus, Error>) -> Void)
    func request(from viewController: UIViewController, completion: @escaping (Result<SwiftyAdsConsentStatus, Error>) -> Void)
}

public final class SwiftyAdsConsentManager {

    // MARK: - Properties

    private let consentInformation: UMPConsentInformation
    private let configuration: SwiftyAdsConsentConfiguration
    private let environment: SwiftyAdsEnvironment
    private let mediationConfigurator: SwiftyAdsMediationConfiguratorType?
    private let mobileAds: GADMobileAds
    private let consentStatusDidChange: (SwiftyAdsConsentStatus) -> Void

    private var form: UMPConsentForm?

    // MARK: - Initialization

    public init(configuration: SwiftyAdsConsentConfiguration,
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
    }
}

// MARK: - SwiftyAdsConsentManagerType

extension SwiftyAdsConsentManager: SwiftyAdsConsentManagerType {
    public var consentStatus: SwiftyAdsConsentStatus {
        consentInformation.consentStatus
    }
    
    public var isTaggedForChildDirectedTreatment: Bool {
        configuration.isTaggedForChildDirectedTreatment
    }

    public var isTaggedForUnderAgeOfConsent: Bool {
        configuration.isTaggedForUnderAgeOfConsent
    }

    public func start(from viewController: UIViewController, completion: @escaping (Result<SwiftyAdsConsentStatus, Error>) -> Void) {
        startInitialConsentRequest(from: viewController) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let consentStatus):
                /// Once initial consent flow has finished we need to update COPPA settings.
                self.updateCOPPA()
                
                /// Once initial consent flow has finished and consentStatus is not `.notRequired`
                /// we need to update GDPR settings.
                if consentStatus != .notRequired {
                    self.updateGDPR(consentStatus: consentStatus)
                }
                
                completion(result)
            case .failure:
                completion(result)
            }
        }
    }
    
    public func request(from viewController: UIViewController, completion: @escaping (Result<SwiftyAdsConsentStatus, Error>) -> Void) {
        DispatchQueue.main.async {
            self.requestUpdate { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success:
                    DispatchQueue.main.async {
                        self.showForm(from: viewController) { [weak self] result in
                            guard let self = self else { return }
                            // If consent form was used to update consentStatus
                            // we need to update GDPR settings
                            if case .success(let newConsentStatus) = result {
                                self.updateGDPR(consentStatus: newConsentStatus)
                            }
                            
                            completion(result)
                        }
                    }
                case .failure:
                    completion(result)
                }
            }
        }
    }
}

// MARK: - Private Methods

private extension SwiftyAdsConsentManager {
    func startInitialConsentRequest(from viewController: UIViewController, completion: @escaping SwiftyAdsConsentResultHandler) {
        DispatchQueue.main.async {
            self.requestUpdate { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let status):
                    switch status {
                    case .required:
                        DispatchQueue.main.async {
                            self.showForm(from: viewController, completion: completion)
                        }
                    default:
                        completion(result)
                    }
                case .failure:
                    completion(result)
                }
            }
        }
    }
    
    func requestUpdate(completion: @escaping SwiftyAdsConsentResultHandler) {
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
        consentInformation.requestConsentInfoUpdate(with: parameters) { [weak self] error in
            guard let self = self else { return }

            if let error = error {
                completion(.failure(error))
                return
            }

            // The consent information state was updated and we can now check if a form is available.
            switch self.consentInformation.formStatus {
            case .available:
                DispatchQueue.main.async {
                    UMPConsentForm.load { [weak self ] (form, error) in
                        guard let self = self else { return }
                        
                        if let error = error {
                            completion(.failure(error))
                            return
                        }

                        self.form = form
                        completion(.success(self.consentStatus))
                    }
                }
            case .unavailable:
                completion(.success(self.consentStatus))
            case .unknown:
                completion(.success(self.consentStatus))
            @unknown default:
                completion(.success(self.consentStatus))
            }
        }
    }
    
    func showForm(from viewController: UIViewController, completion: @escaping SwiftyAdsConsentResultHandler) {
        // Ensure form is loaded
        guard let form = form else {
            completion(.failure(SwiftyAdsError.consentFormNotAvailable))
            return
        }

        // Present the form
        form.present(from: viewController) { [weak self] error in
            guard let self = self else { return }

            if let error = error {
                completion(.failure(error))
                return
            }

            let consentStatus = self.consentStatus
            self.consentStatusDidChange(consentStatus)
            completion(.success(consentStatus))
        }
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
        guard !isTaggedForChildDirectedTreatment else {
            return
        }

        mobileAds.requestConfiguration.tagForUnderAgeOfConsent = NSNumber(value: isTaggedForUnderAgeOfConsent)
    }
}
