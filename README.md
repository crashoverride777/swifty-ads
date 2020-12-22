[![Swift 5.0](https://img.shields.io/badge/swift-5.0-ED523F.svg?style=flat)](https://swift.org/download/)
[![Platform](https://img.shields.io/cocoapods/p/SwiftyAds.svg?style=flat)]()
[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/SwiftyAds.svg)](https://img.shields.io/cocoapods/v/SwiftyAds.svg)

# Note

- Currently having trouble getting cocoa pods to push newer versions to due me being on holiday and only having my work laptop with me that blocks cocoa pods
on my personal projects. 
- If you want the latest version (tab bar fix and native ads) you will have to manually manage this yourself. The latest version will be on dedicated release branches.

# 2021 Roadmap/Plans

- Fix cocoa pods ASAP
- iOS 14 app tracking transparency 
- Swift package support
- Multiple ad unit ids

# SwiftyAds

SwiftyAds is a Swift library to display banner, interstitial and rewarded video ads from AdMob and supported mediation networks.

## Requirements

- iOS 11.4+
- Swift 5.0+

## Create AdMob account

https://developers.google.com/ad-manager/mobile-ads-sdk/ios/quick-start

Sign up for an [AdMob account](https://support.google.com/admob/answer/3052638?hl=en-GB&ref_topic=3052726) and create your required adUnitIDs.

## GDPR in EEA (European Economic Area)

[READ](https://developers.google.com/admob/ios/eu-consent#collect_consent)

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

Altenatively you can drag the `Sources` folder and its containing files into your project.

## Usage

### Update Info.plist

Add a new entry in your apps info.plist called `GADApplicationIdentifier` (String) and enter your apps admob id

[READ](https://developers.google.com/admob/ios/quick-start#update_your_infoplist)

### Add SwiftyAds.plist

Download the template plist and add it to your projects main bundle. Than enter your required ad unit ids and settings.

[Template ](Downloads/SwiftyAdsPlistTemplate.zip)

### Setup 

Create a setup method and call it as soon as your app launches e.g AppDelegate didFinishLaunchingWithOptions. 

```swift
func setupSwiftyAds() {
    #if DEBUG
    let mode: SwiftyAdsMode = .debug(testDeviceIdentifiers: []) // add your test device identifiers if needed
    #else
    let mode: SwiftyAdsMode = .production
    #endif
    
    // In this example we want to show a custom consent alert
    let customConsentContent = SwiftyAdsCustomConsentAlertContent(
        title: "Permission to use data",
        message: "We care about your privacy and data security. We keep this app free by showing ads. You can change your choice anytime in the app settings. Our partners will collect data and use a unique identifier on your device to show you ads.",
        actionAllowPersonalized: "Allow personalized",
        actionAllowNonPersonalized: "Allow non personalized",
        actionAdFree: nil, // we do not want to offer ad free in this example
    )
    
    SwiftyAds.shared.setup(
        with: self,
        mode: mode,
        consentStyle: .custom(content: customConsentContent), // alternatively set to adMob to use googles native consent form
        consentStatusDidChange: ({ consentStatus in
            print("SwiftyAds did change consent status to \(consentStatus)")
            
            if consentStatus != .notRequired {
                // update mediation networks if required
            }
        }),
        completion: ({ status in
            guard status.hasConsent else { return }
            // Show banner for example
        })
    )
}
```

### Showing ads outside a UIViewController

SwiftyAds requires reference to a UIViewController to present ads. If you are not using SwiftyAds inside a UIViewController you can do the following to get reference the `rootViewController`.

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

```swift
SwiftyAds.shared.showBanner(
    from: self,
    atTop: false,
    ignoresSafeArea: false,
    animationDuration: 1.5,
    onOpen: ({
        print("SwiftyAds banner ad did open")
    }),
    onClose: ({
        print("SwiftyAds banner ad did close")
    }),
    onError: ({ error in
        print("SwiftyAds banner ad error \(error)")
    })
)
```

Orientation changes

```swift
override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)
    coordinator.animate(alongsideTransition: { _ in
        SwiftyAds.shared.updateBannerForOrientationChange(isLandscape: size.width > size.height)
    })
}
```
Remove e.g during gameplay 

```swift
SwiftyAds.shared.removeBanner() 
```

### Interstitial Ads

```swift
SwiftyAds.shared.showInterstitial(
    from: self,
    withInterval: 2, // every 2nd time method is called ad will be displayed
    onOpen: ({
        print("SwiftyAds interstitial ad did open")
    }),
    onClose: ({
        print("SwiftyAds interstitial ad did close")
    }),
    onError: ({ error in
        print("SwiftyAds interstitial ad error \(error)")
    })
)
```

### Rewarded Ads

Always use a dedicated button to display rewarded videos, never show them automatically as some might be non-skippable.

AdMob provided a new rewarded video API which lets you preload multiple rewarded videos with different AdUnitIds. While SwiftyAds uses this new API it currently only supports loading 1 rewarded video ad at a time. I will try to add support for multiple ads very soon.

```swift
SwiftyAds.shared.showRewardedVideo(
    from: self,
    onOpen: ({
        print("SwiftyAds rewarded video ad did open")
    }),
    onClose: ({
        print("SwiftyAds rewarded video ad did close")
    }), 
    onError: ({ error in
        print("SwiftyAds rewarded video ad error \(error)")
    }),
    onNotReady: ({ [weak self] in
        guard let self = self else { return }
        print("SwiftyAds rewarded video ad was not ready")
        // If the user presses the rewarded video button and watches a video it might take a few seconds for the next video to reload.
        // Use this callback to display an alert incase the video was not ready. 
        let alertController = UIAlertController(
            title: "Sorry",
            message: "No video available to watch at the moment.",
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: "Ok", style: .cancel))
        self.present(alertController, animated: true)
    }),
    onReward: ({ [weak self] rewardAmount in
        print("SwiftyAds rewarded video ad did reward user with \(rewardAmount)")
        // Provide the user with the reward e.g coins, retries etc
    })
)
```

### Booleans

```swift
SwiftyAds.shared.hasConsent // Check if user has given consent. Also returns true if not required to ask for consent (outside EEA)
SwiftyAds.shared.isRequiredToAskForConsent // Check if user in inside EEA and has to ask for consent
SwiftyAds.shared.isRewardedVideoReady // e.g show/hide rewarded video button
SwiftyAds.shared.isInterstitialReady { // e.g show custom/in-house ad
```

### Disable ads (In App Purchases)

```swift
SwiftyAds.shared.disable()
```

NOTE:

If this method is called banner and interstitial ads will not longer display when calling the `show` method. This will not stop rewarded videos from showing as they should have a dedicated button. This way you can remove banner and interstitial ads but still have a rewarded videos. 

For permanent storage you will need to create your own "removedAdsProduct" property and save it in something like UserDefaults, or preferably Keychain. 
Than at app launch, after you called `SwiftyAds.shared.setup`  check if your saved property is set to true and than call the `disable()` method

```swift
if UserDefaults.standard.bool(forKey: "RemovedAdsKey") == true {
    SwiftyAds.shared.disable()
}
```

### To ask for consent again (GDPR) 

It is required that the user has the option to change their GDPR consent settings, usually via a button in settings. 

```swift
func consentButtonPressed() {
    SwiftyAds.shared.askForConsent(from: self)
}
```

The consent button can be hidden for non EEA users like so

```swift
consentButton.isHidden = !SwiftyAds.shared.isRequiredToAskForConsent
```

## When you submit your app to Apple

When you submit your app to Apple on iTunes connect do not forget to select YES for "Does your app use an advertising identifier", otherwise it will get rejected. If you use reward videos you should also select the 3rd bulletpoint.

## Tip

From my personal experience and from a user perspective you should not spam full screen interstitial ads all the time. This will also increase your revenue because user retention rate is higher so you should not be greedy. Therefore you should

1) Not show an interstitial ad everytime a button is pressed 
2) Not show an interstitial ad everytime you die in a game
