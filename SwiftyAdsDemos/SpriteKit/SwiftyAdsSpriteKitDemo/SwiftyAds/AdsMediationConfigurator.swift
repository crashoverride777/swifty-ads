import Foundation
import SwiftyAds
import GoogleMobileAds

final class AdsMediationConfigurator: SwiftyAdsMediationConfigurator {
    func updateCOPPA(isTaggedForChildDirectedTreatment: Bool) {
        print("SwiftyAdsMediationConfigurator update COPPA", isTaggedForChildDirectedTreatment)
    }
    
    func updateGDPR(for consentStatus: SwiftyAdsConsentStatus, isTaggedForUnderAgeOfConsent: Bool) {
        print("SwiftyAdsMediationConfigurator update GDPR")
    }
}
