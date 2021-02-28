[![Swift 5.0](https://img.shields.io/badge/swift-5.0-ED523F.svg?style=flat)](https://swift.org/download/)
[![Platform](https://img.shields.io/cocoapods/p/SwiftyAds.svg?style=flat)]()
[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/SwiftyAds.svg)](https://img.shields.io/cocoapods/v/SwiftyAds.svg)

# SwiftyAds

A Swift library to display banner, interstitial, rewarded and native ads from Google AdMob and supported mediation partners.

# 2021 Roadmap

- Multiple ad unit ids
- Swift package manager support

## Requirements

- iOS 11.4+
- Swift 5.0+

## Create AdMob account

Sign up for an [AdMob account](https://admob.google.com/home/get-started/) and create your required adUnitIDs for the types of ads you would like to display. 

## Create Funding Choices account and messages (GDPR and App Tracking Transparency)

SwiftyAds uses Google`s [User Messaging Platform](https://developers.google.com/admob/ump/ios/quick-start) (UMP) SDK to handle user consent. This SDK can handle both GDPR requests and also the iOS 14 [ATT](https://developers.google.com/admob/ios/ios14) alert if required. Please read the Funding Choices [documentation](https://support.google.com/fundingchoices/answer/9180084) to ensure they are setup up correctly for your requirements.

NOTE: Currently it seems Apple is rejecting apps that use the UMP SDK to display the iOS 14 ATT alert because Google is displaying an explainer message and/or the GDPR message before the actual ATT alert. Please read about the workaround in the setup section of this readme.

## Mediation

[READ](https://developers.google.com/admob/ios/mediation)

## Installation

### Cocoa Pods

[CocoaPods](https://developers.google.com/admob/ios/quick-start#streamlined_using_cocoapods) is a dependency manager for Cocoa projects. 
Simply install the pod by adding the following line to your pod file

```swift
pod 'SwiftyAds'
```

### Manually 

Alternatively you can copy the `Sources` folder and its containing files into your project. Install the required dependencies either via Cocoa Pods.

```swift
pod 'Google-Mobile-Ads-SDK'
```

or manually

- [AdMob](https://developers.google.com/admob/ios/quick-start#manual_download)
- [UMP](https://developers.google.com/admob/ump/ios/quick-start#manual_download)

## Usage

### Update Info.plist

- [AdMob](https://developers.google.com/admob/ios/quick-start#update_your_infoplist)
- [UMP](https://developers.google.com/admob/ump/ios/quick-start#update_your_infoplist)

### Add SwiftyAds.plist

Download the [template ](Resources/SwiftyAdsPlistTemplate.zip) plist and add it to your projects main bundle. Than enter your required ad unit ids and set the isTaggedForUnderAgeOfConsent flag.

Mandatory fields:
- isTaggedForUnderAgeOfConsent (Boolean) ([GDPR](https://developers.google.com/admob/ios/targeting#users_under_the_age_of_consent))

Optional fields:
- bannerAdUnitId (String)
- interstitialAdUnitId (String)
- rewardedAdUnitId (String)
- rewardedInterstitialAdUnitId (String)
- nativeAdUnitId (String)
- isTaggedForChildDirectedTreatment (Boolean) ([COPPA](https://developers.google.com/admob/ios/targeting#child-directed_setting))

### Link AppTrackingTransparency framework

[Link](https://developers.google.com/admob/ump/ios/quick-start#update_your_infoplist) the AppTrackingTransparency framework in `Framework, Libraries and Embedded Content` under the general tab, otherwise ATT alerts will not display.

If you are supporting iOS 13 and below you will also have to make it optional in `BuildPhases->Link Binary With Libraries` to avoid a crash.

### Add import (CocoaPods)

- Add the import statement to your swift file(s) when you installed via CocoaPods

```swift
import SwiftyAds
```

### Setup 

Create a setup method and call it as soon as your app launches e.g. AppDelegate `didFinishLaunchingWithOptions`. This will also trigger the initial consent flow (GDPR and ATT).

```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    if let rootViewController = window?.rootViewController {
        setupSwiftyAds(from: rootViewController)
    }
    return true
}

private func setupSwiftyAds(from viewController: UIViewController) {
    #if DEBUG
    // testDeviceIdentifiers: The test device indentifiers used for debugging purposes.
    // geography: Set your debug location for GDPR consent debugging purposes.
    // resetConsentInfo: If set to true resets the consent info as if they have not been set previously.
    let environment: SwiftyAdsEnvironment = .debug(testDeviceIdentifiers: [], geography: .EEA, resetConsentInfo: true)
    #else
    let environment: SwiftyAdsEnvironment = .production
    #endif
    
    SwiftyAds.shared.setup(
        from: viewController,
        for: environment,
        consentStatusDidChange: { status in
            print("The consent status has changed: \(status)")
            // Update mediation networks with under age of consent and other settings if required, 
            // for example when not using IAB TCF v2 framework in Google funding choices
            // See mediation network documentation
        },
        completion: { result in
            switch result {
            case .success(let consentStatus):
                print("Setup successful")
            case .failure(let error):
                print("Setup error: \(error)")
            }
        }
    )
}
```

NOTE: Currently it seems Apple is rejecting apps that use the UMP SDK to display the iOS 14 ATT alert because Google is displaying an explainer message and/or the GDPR message before the actual ATT alert. As a workaround you can disable the ATT message from Funding Choices and [manually](https://github.com/crashoverride777/swifty-ads/issues/50) display the ATT alert before configuring SwiftyAds. 

```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    if let rootViewController = window?.rootViewController {
        if  #available(iOS 14, *)  {
            ATTrackingManager.requestTrackingAuthorization { status in
                self.setupSwiftyAds(from: rootViewController)
            }
        } else {
            setupSwiftyAds(from: rootViewController)
        }
    }
    return true
}
```

### Showing ads outside a UIViewController

SwiftyAds requires reference to a `UIViewController` to present ads. If you are not using SwiftyAds inside a `UIViewController` you can do the following to get reference the rootViewController.

AppDelegate
```swift
if let viewController = window?.rootViewController {
    SwiftyAds.shared.show(...)
}
```

SKScene
```swift
if let viewController = view?.window?.rootViewController {
    SwiftyAds.shared.show(...)
}
```

### Banner Ads

Create a property in your `UIViewController` for the banner to be displayed

```swift
class SomeViewController: UIViewController {

    private var bannerAd: SwiftyAdsBannerType?
}
```

Prepare the banner in `viewDidLoad`

```swift
override func viewDidLoad() {
    super.viewDidLoad()
    
    bannerAd = SwiftyAds.shared.makeBannerAd(
        in: self,
        adUnitIdType: .plist, // set to `.custom("AdUnitId")` to add a different AdUnitId for this particular banner ad
        position: .bottom(isUsingSafeArea: true) // banner is pinned to bottom and follows the safe area layout guide
        animation: .slide(duration: 1.5),
        onOpen: {
            print("SwiftyAds banner ad did receive ad and was opened")
        },
        onClose: {
            print("SwiftyAds banner ad did close")
        },
        onError: { error in
            print("SwiftyAds banner ad error \(error)")
        },
        onWillPresentScreen: {
            print("SwiftyAds banner ad was tapped and is about to present screen")
        },
        onWillDismissScreen: {
            print("SwiftyAds banner ad presented screen is about to be dismissed")
        },
        onDidDismissScreen: {
            print("SwiftyAds banner did dismiss presented screen")
        }
    )
}
```

and show it in `viewDidAppear`. This is to ensure that the view has been layed out correctly and has a valid safe area. If you do not rely on the safe area you can also call this in `viewDidLoad`.

```swift
override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    bannerAd?.show(isLandscape: view.frame.width > view.frame.height)
}
```

To handle orientation changes, simply call the show method again in `viewWillTransition`

```swift
override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)
    
    coordinator.animate(alongsideTransition: { [weak self] _ in
        self?.bannerAd?.show(isLandscape: size.width > size.height)
    })
}
```

You can hide the banner by calling the `hide` method. 

```swift
bannerAd?.hide() 
```

You can remove the banner from its superview by calling the `remove` method and afterwards nil out the reference.

```swift
bannerAd?.remove() 
bannerAd = nil
```

### Interstitial Ads

```swift
SwiftyAds.shared.showInterstitialAd(
    from: self,
    afterInterval: 2, // every 2nd time method is called ad will be displayed
    onOpen: {
        print("SwiftyAds interstitial ad did open")
    },
    onClose: {
        print("SwiftyAds interstitial ad did close")
    },
    onError: { error in
        print("SwiftyAds interstitial ad error \(error)")
    }
)
```

### Rewarded Ads

Rewared ads may be non-skippable and should only be presented when pressing a dedicated button.

```swift
SwiftyAds.shared.showRewardedAd(
    from: self,
    onOpen: {
        print("SwiftyAds rewarded ad did open")
    },
    onClose: {
        print("SwiftyAds rewarded ad did close")
    }, 
    onError: { error in
        print("SwiftyAds rewarded ad error \(error)")
    },
    onNotReady: { [weak self] in
        guard let self = self else { return }
        print("SwiftyAds rewarded ad was not ready")
        // If the user presses the rewarded video button and watches a video it might take a few seconds for the next video to reload.
        // Use this callback to display an alert incase the video was not ready. 
        let alertController = UIAlertController(
            title: "Sorry",
            message: "No video available to watch at the moment.",
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: "Ok", style: .cancel))
        self.present(alertController, animated: true)
    },
    onReward: { [weak self] rewardAmount in
        print("SwiftyAds rewarded ad did reward user with \(rewardAmount)")
        // Provide the user with the reward e.g coins, diamonds etc
    }
)
```

NOTE: AdMob provided a new rewarded video API which lets you preload multiple rewarded videos with different AdUnitIds. While SwiftyAds uses this new API it currently only supports loading 1 rewarded video ad at a time.

### Rewarded Interstitial Ads

Rewared interstitial ads can be presented naturally in your app flow, similar to interstitial ads, and do not require a dedicated button like regular rewarded ads.

```swift
SwiftyAds.shared.showRewardedInterstitialAd(
    from: self,
    onOpen: {
        print("SwiftyAds rewarded interstitial ad did open")
    },
    onClose: {
        print("SwiftyAds rewarded interstitial ad did close")
    }, 
    onError: { error in
        print("SwiftyAds rewarded interstitial ad error \(error)")
    },
    onReward: { [weak self] rewardAmount in
        print("SwiftyAds rewarded interstitial ad did reward user with \(rewardAmount)")
        // Provide the user with the reward e.g coins, diamonds etc
    }
)
```

NOTE: Before displaying a rewarded interstitial ad to users, you must present the user with an [intro screen](https://support.google.com/admob/answer/9884467) that provides clear reward messaging and an option to skip the ad before it starts.

### Native Ads

To present a native ad simply call the load method. Once a native ad has been received you can update your custom ad view with the native ad content.

You can set the amount of ads to load (`GADMultipleAdsAdLoaderOptions`) via the `loaderOptions` parameter. Set to `.single` to use the default options.

As per Googles documentation, requests for multiple native ads don't currently work for AdMob ad unit IDs that have been configured for mediation. Publishers using mediation should avoid using the GADMultipleAdsAdLoaderOptions class when making requests. In that case you can also set the `loaderOptions` parameter to `.single`.


```swift
SwiftyAds.shared.loadNativeAd(
    from: self,
    adUnitIdType: .plist, // set to `.custom("AdUnitId")` to add a different AdUnitId for this particular native ad
    loaderOptions: .single, // set to `.multiple(2)` to load multiple ads for example 2
    onFinishLoading: {
        // Native ad has finished loading and new ads can now be loaded
    },
    onError: { error in
        // Native ad could not load ad due to error
    },
    onReceive: { nativeAd in
        // show native ad (see demo app or google documentation)
    }
)
```

NOTE: While prefetching ads is a great technique, it's important that you don't keep old native ads around forever without displaying them. Any native ad objects that have been held without display for longer than an hour should be discarded and replaced with new ads from a new request.

### Errors

Use can use the `SwiftyAdsError` enum to handle received errors more granuarly if required.

```swift
if let swiftyAdsError = error as? SwiftyAdsError {
    switch swiftyAdsError { 
    case .interstitialAdNotLoaded:
        // Ad was not loaded
    default:
        break
    }
}
```

### Consent Status/Type

```swift
// Check current consent status
SwiftyAds.shared.consentStatus

// Check type of consent provided (returns unknown if using IAB TCF v2 framework)
// https://stackoverflow.com/questions/63415275/obtaining-consent-with-the-user-messaging-platform-android
SwiftyAds.shared.consentType
```

### Booleans

```swift
// Check if rewarded video is ready, for example to show/hide button
SwiftyAds.shared.isRewardedAdReady

// Check if interstitial ad is ready, for example to show an alternative ad
SwiftyAds.shared.isInterstitialAdReady

// Check if child directed treatment is tagged on/off. Nil if not indicated how to be treated. (COPPA)
SwiftyAds.shared.isTaggedForChildDirectedTreatment

// Check if under age of consent is tagged on/off (GDPR)
SwiftyAds.shared.isTaggedForUnderAgeOfConsent

// Check if ads have been disabled
SwiftyAds.shared.isDisabled
```

### Disable Ads (In App Purchases)

Call the `disable()` method and banner, interstitial and rewarded interstitial ads will no longer display. 
This will not stop regular rewarded videos from displaying as they should have a dedicated button. This way you can remove banner, interstitial and rewarded interstitial ads but still have regular rewarded videos. 

```swift
SwiftyAds.shared.disable()
```

For permanent storage you will need to create your own boolean logic and save it in something like `NSUserDefaults`, or preferably `Keychain`. 
Than at app launch, before you call `SwiftyAds.shared.configure(...)`, check your saved boolean and disable the ads if required.

```swift
if UserDefaults.standard.bool(forKey: "RemovedAdsKey") == true {
    SwiftyAds.shared.disable()
}
```

### Ask for consent again

It is required that the user has the option to change their GDPR consent settings, usually via a button in settings. 

```swift
func consentButtonPressed() {
    SwiftyAds.shared.askForConsent(from: self) { result in
        switch result {
        case .success(let status):
            print("Did change consent status")
        case .failure(let error):
            print("Consent status change error \(error)")
        }
    }
}
```

The consent button can be hidden if consent is not required.

```swift
consentButton.isHidden = SwiftyAds.shared.consentStatus == .notRequired
```

### App Store release information

Make sure to prepare for Apple's App Store data disclosure [requirements](https://developers.google.com/admob/ios/data-disclosure)
