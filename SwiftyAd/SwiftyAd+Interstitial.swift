//
//  SwiftyAd+Interstitial.swift
//  SwiftyAdExample
//
//  Created by Dominik Ringler on 23/05/2019.
//  Copyright © 2019 Dominik. All rights reserved.
//

import GoogleMobileAds

// MARK: - Load

extension SwiftyAd {
    
    func loadInterstitialAd() {
        guard !isRemoved, hasConsent else { return }
        
        interstitialAd = GADInterstitial(adUnitID: configuration.interstitialAdUnitId)
        interstitialAd?.delegate = self
        let request = makeRequest()
        interstitialAd?.load(request)
    }
}

// MARK: - GADInterstitialDelegate

extension SwiftyAd: GADInterstitialDelegate {
    
    public func interstitialDidReceiveAd(_ ad: GADInterstitial) {
        print("AdMob interstitial did receive ad from: \(ad.adNetworkClassName ?? "")")
    }
    
    public func interstitialWillPresentScreen(_ ad: GADInterstitial) {
        delegate?.swiftyAdDidOpen(self)
    }
    
    public func interstitialWillLeaveApplication(_ ad: GADInterstitial) {
        delegate?.swiftyAdDidOpen(self)
    }
    
    public func interstitialWillDismissScreen(_ ad: GADInterstitial) {
    }
    
    public func interstitialDidDismissScreen(_ ad: GADInterstitial) {
        delegate?.swiftyAdDidClose(self)
        loadInterstitialAd()
    }
    
    public func interstitialDidFail(toPresentScreen ad: GADInterstitial) {
    }
    
    public func interstitial(_ ad: GADInterstitial, didFailToReceiveAdWithError error: GADRequestError) {
        print(error.localizedDescription)
        // Do not reload here as it might cause endless loading loops if no/slow internet
    }
}
