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

import GoogleMobileAds
import UserMessagingPlatform

/*
The SDK is designed to be used in a linear fashion. The steps for using the SDK are:

Request the latest consent information.
Check if consent is required.
Check if a form is available and if so load a form.
Present the form.
Provide a way for users to change their consent.
*/

protocol SwiftyAdsConsentManagerType: class {
    var consentStatus: SwiftyAdsConsentStatus { get }
    var consentType: SwiftyAdsConsentType { get }
    func requestUpdate(completion: @escaping (Result<SwiftyAdsConsentStatus, Error>) -> Void)
    func showForm(from viewController: UIViewController, completion: @escaping (Result<SwiftyAdsConsentStatus, Error>) -> Void)
}

final class SwiftyAdsConsentManager {

    // MARK: - Types

    enum ConsentError: Error {
        case formNotAvailable
    }

    // MARK: - Properties

    private let consentInformation: UMPConsentInformation
    private let configuration: SwiftyAdsConfiguration
    private let environment: SwiftyAdsEnvironment
    private let mobileAds: GADMobileAds
    private let consentStatusDidChange: (SwiftyAdsConsentStatus) -> Void

    private var form: UMPConsentForm?

    // MARK: - Initialization

    init(consentInformation: UMPConsentInformation,
         configuration: SwiftyAdsConfiguration,
         environment: SwiftyAdsEnvironment,
         mobileAds: GADMobileAds,
         consentStatusDidChange: @escaping (SwiftyAdsConsentStatus) -> Void
    ) {
        self.consentInformation = consentInformation
        self.configuration = configuration
        self.environment = environment
        self.mobileAds = mobileAds
        self.consentStatusDidChange = consentStatusDidChange
    }
}

// MARK: - SwiftyAdsConsentManagerType

extension SwiftyAdsConsentManager: SwiftyAdsConsentManagerType {

    var consentStatus: SwiftyAdsConsentStatus {
        consentInformation.consentStatus
    }

    var consentType: SwiftyAdsConsentType {
        consentInformation.consentType
    }

    func requestUpdate(completion: @escaping (Result<SwiftyAdsConsentStatus, Error>) -> Void) {
        // Create a UMPRequestParameters object.
        let parameters = UMPRequestParameters()

        // Set UMPDebugSettings if in debug environment.
        if case .debug(let testDeviceIdentifiers, let geography, let resetConsentInfo) = environment {
            let debugSettings = UMPDebugSettings()
            debugSettings.testDeviceIdentifiers = testDeviceIdentifiers
            debugSettings.geography = geography
            parameters.debugSettings = debugSettings

            if resetConsentInfo {
                consentInformation.reset()
            }
        }
        
        // Update parameters for under age of consent.
        parameters.tagForUnderAgeOfConsent = configuration.isTaggedForUnderAgeOfConsent

        // Request an update to the consent information.
        // The first time we request consent information, even if outside of EEA, the status
        // may return `.required` as the ATT alert has not yet been displayed.
        consentInformation.requestConsentInfoUpdate(with: parameters) { [weak self] error in
            guard let self = self else { return }

            if let error = error {
                completion(.failure(error))
                return
            }

            // Update for under age of consent.
            self.updateUnderAgeOfConsent(for: self.consentStatus)

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

    func showForm(from viewController: UIViewController, completion: @escaping (Result<SwiftyAdsConsentStatus, Error>) -> Void) {
        // Ensure form is loaded
        guard let form = form else {
            completion(.failure(ConsentError.formNotAvailable))
            return
        }

        // Present the form
        form.present(from: viewController) { [weak self] error in
            guard let self = self else { return }

            if let error = error {
                completion(.failure(error))
                return
            }

            // Update under age of consent again, as status might now return `.notRequired`
            // if outside of EEA and ATT alert has been displayed
            self.updateUnderAgeOfConsent(for: self.consentStatus)

            // Fire status did change handler
            self.consentStatusDidChange(self.consentStatus)

            // Fire completion handler
            completion(.success(self.consentStatus))
        }
    }
}

// MARK: - Private Methods

private extension SwiftyAdsConsentManager {

    func updateUnderAgeOfConsent(for consentStatus: SwiftyAdsConsentStatus) {
        switch consentStatus {
        case .notRequired:
            mobileAds.requestConfiguration.tagForUnderAge(ofConsent: false)
        default:
            mobileAds.requestConfiguration.tagForUnderAge(ofConsent: configuration.isTaggedForUnderAgeOfConsent)
        }
    }
}
