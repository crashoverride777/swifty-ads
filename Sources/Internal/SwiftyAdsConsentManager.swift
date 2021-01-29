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

import UserMessagingPlatform

/*
The SDK is designed to be used in a linear fashion. The steps for using the SDK are:

Request the latest consent information.
Check if consent is required.
Check if a form is available and if so load a form.
Present the form.
Provide a way for users to change their consent.
*/

enum SwiftyAdsConsentManagerError: Error {
    case formNotLoaded

    var localizedDescription: String {
        switch self {
        case .formNotLoaded:
            return "The form was not loaded, call requestUpdate"
        }
    }
}

protocol SwiftyAdsConsentManagerType: class {
    var status: SwiftyAdsConsentStatus { get }
    func requestUpdate(completion: @escaping (Result<SwiftyAdsConsentStatus, Error>) -> Void)
    func showForm(from viewController: UIViewController, completion: ((Result<SwiftyAdsConsentStatus, Error>) -> Void)?)
}

final class SwiftyAdsConsentManager {

    // MARK: - Properties

    private let consentInformation: UMPConsentInformation
    private let configuration: SwiftyAdsConfiguration
    private let environment: SwiftyAdsEnvironment
    private var form: UMPConsentForm?

    // MARK: - Initialization

    init(consentInformation: UMPConsentInformation,
         configuration: SwiftyAdsConfiguration,
         environment: SwiftyAdsEnvironment
    ) {
        self.consentInformation = consentInformation
        self.configuration = configuration
        self.environment = environment
    }
}

// MARK: - SwiftyAdsConsentManagerType

extension SwiftyAdsConsentManager: SwiftyAdsConsentManagerType {

    var status: SwiftyAdsConsentStatus {
        guard !configuration.isTaggedForUnderAgeOfConsent else {
            return .underAge
        }
        
        switch consentInformation.consentStatus {
        case .obtained:
            return .obtained
        case .required:
            return .required
        case .notRequired:
            return .notRequired
        case .unknown:
            return .unknown
        @unknown default:
            return .unknown
        }
    }

    func requestUpdate(completion: @escaping (Result<SwiftyAdsConsentStatus, Error>) -> Void) {
        // Create a UMPRequestParameters object.
        let parameters = UMPRequestParameters()

        // Debug settings
        if case .debug(let testDeviceIdentifiers) = environment {
            let debugSettings = UMPDebugSettings()
            debugSettings.testDeviceIdentifiers = testDeviceIdentifiers
            debugSettings.geography = .disabled
            parameters.debugSettings = debugSettings
        }
        
        // Set tag for under age of consent. Here false means users are not under age.
        parameters.tagForUnderAgeOfConsent = configuration.isTaggedForUnderAgeOfConsent

        // Request an update to the consent information.
        consentInformation.requestConsentInfoUpdate(with: parameters) { [weak self] error in
            guard let self = self else { return }

            // The consent information state could not be updated
            if let error = error {
                completion(.failure(error))
                return
            }

            // The consent information state was updated.
            // You are now ready to see if a form is available.
            switch self.consentInformation.formStatus {
            case .available:
                self.loadForm { [weak self] result in
                    guard let self = self else { return }
                    switch result {
                    case .success(let form):
                        self.form = form
                        completion(.success(self.status))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            case .unavailable:
                #warning("handle")
            case .unknown:
                #warning("handle")
            @unknown default:
                #warning("handle")
            }
        }
    }

    func showForm(from viewController: UIViewController, completion: ((Result<SwiftyAdsConsentStatus, Error>) -> Void)?) {
        // Only display form if consent is required
        guard consentInformation.consentStatus == .required else {
            completion?(.success(.notRequired))
            return
        }
        
        // Ensure form is loaded
        guard let form = form else {
            completion?(.failure(SwiftyAdsConsentManagerError.formNotLoaded))
            return
        }

        // Present the form
        form.present(from: viewController) { [weak self] error in
            guard let self = self else { return }

            if let error = error {
                completion?(.failure(error))
                return
            }

            completion?(.success(self.status))
        }
    }
}

// MARK: - Private Methods

private extension SwiftyAdsConsentManager {

    func loadForm(completion: @escaping (Result<UMPConsentForm?, Error>) -> Void) {
        UMPConsentForm.load { (form, error) in
            if let error = error {
                completion(.failure(error))
                return
            }

            completion(.success(form))
        }
    }
}
