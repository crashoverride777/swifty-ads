[![Swift 5.0](https://img.shields.io/badge/swift-5.0-ED523F.svg?style=flat)](https://swift.org/download/)
[![Platform](https://img.shields.io/cocoapods/p/SwiftyAds.svg?style=flat)]()
[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/SwiftyAds.svg)](https://img.shields.io/cocoapods/v/SwiftyAds.svg)

# SwiftyAds

A Swift helper to integrate Ads from AdMob so you can easily show banner, interstitial and rewarded video ads anywhere in your project.

This helper follows all the best practices in regards to ads, like creating shared banners and correctly preloading interstitial and rewarded video ads so they are always ready to show.

## Requirements

- iOS 11.4+
- Swift 5.0+

## GDPR in EEA (European Economic Area)

[READ](https://developers.google.com/admob/ios/eu-consent#collect_consent)

## Mediation

Admob reward videos will only work when using a 3rd party mediation network such as Chartboost or Vungle. 
Please read the AdMob mediation guidlines 

https://developers.google.com/admob/ios/mediation

NOTE:

Make sure to include your mediation networks when setting up SwiftyAd (see How To Use)

## Create AdMob account

https://developers.google.com/ad-manager/mobile-ads-sdk/ios/quick-start

Sign up for a Google [AdMob account](https://support.google.com/admob/answer/3052638?hl=en-GB&ref_topic=3052726) and create your real adUnitIDs for your app, one for each type of ad you will use (Banner, Interstitial, Reward Ads).

## Installation

### Cocoa Pods

[CocoaPods](https://developers.google.com/admob/ios/quick-start#streamlined_using_cocoapods) is a dependency manager for Cocoa projects. 
Simply install the pod by adding the following line to your pod file

```swift
pod 'SwiftyAds'
```

### Manually 

Altenatively you can drag the `Source` folder and its containing files into your project.

## Usage

Note: SwifyAds will always display test app when testing in debug mode.

### Update Info.plist: 

Add a new entry in your apps info.plist called `GADIsAdManagerApp` (String) with a value of `YES` when using SDK 7.42 or higher

https://developers.google.com/ad-manager/mobile-ads-sdk/ios/quick-start#update_your_infoplist

### Add SwiftyAds.plist

Create a new `SwiftyAds.plist` file like in the demo project  and update with your ad ids and settings

### Using SwiftyAds outside a UIViewController

SwiftyAds requires reference to a UIViewController to present ads. If you are not using SwiftyAds inside a UIViewController you can do the following to get reference the `RootViewController`.

AppDelegate
```swift
if let viewController = window?.rootViewController {
    SwiftyAds.shared...
}
```

SKScene
```swift
if let viewController = view?.window?.rootViewController {
    SwiftyAds.shared...
}
```

### Setup 

It is recommended to instantiate and manage SwiftyAds in 1 centralized spot e.g rootViewController or GameViewController (SpriteKit)

Call the setup method as soon as your app launches. 

```swift
SwiftyAds.shared.setup(with: self, delegate: self, bannerAnimationDuration: 1.4, mode: .production) { consentStatus in
    guard consentStatus.hasConsent else { return }
    DispatchQueue.main.async {
        SwiftyAds.shared.showBanner(from: self, atTop: false)
    }
}
```

Than create an extension conforming to the SwiftyAdsDelegate protocol.
```swift
extension GameViewController: SwiftyAdsDelegate {
    func swiftyAdsDidOpen(_ swiftyAds: SwiftyAds) {
        // pause your game/app if needed
    }
    
    func swiftyAdsDidClose(_ swiftyAds: SwiftyAds) { 
       // resume your game/app if needed
    }
    
    func swiftyAds(_ swiftyAds: SwiftyAds, didChange consentStatus: SwiftyAdsConsentStatus) {
        // e.g update your mediation networks like Chartboost, Vungle etc
    }
    
    func swiftyAds(_ swiftyAds: SwiftyAds, didRewardUserWithAmount rewardAmount: Int) {
       // Reward amount is a decimel number I converted to an integer for convenience. This value comes from your AdNetwork.
       if let scene = (view as? SKView)?.scene as? GameScene {
            scene.coins += rewardAmount
        }
       
     
       // You can ignore this and hardcode the value if you would like but than you cannot change the value dynamically without having to update your app.
       
       // You could also do something else like unlocking a level or bonus item.
       
       // Leave empty if unused
    }
}
```

### Show Ads

```swift
SwiftyAds.shared.showBanner(from: self, atTop: false) // if atTop = true banner will be anchored to top of screen 
SwiftyAds.shared.showInterstitial(from: self)
SwiftyAds.shared.showInterstitial(from: self, withInterval: 4) // Shows an ad every 4th time method is called. Set to nil to always show.
SwiftyAds.shared.showRewardedVideo(from: self) // Should be called when pressing dedicated button only
```

Note:

You should only show rewarded videos with a dedicated button and you should only show that button when a video is loaded (see below). If the user presses the rewarded video button and watches a video it might take a few seconds for the next video to reload. Incase the user immediately tries to watch another video this helper will show a "no video is available at the moment" alert. 

### Check if ads are ready

```swift
if SwiftyAds.shared.isRewardedVideoReady {
    // show reward video button
}

if SwiftyAds.shared.isInterstitialReady {
    // maybe show custom ad or something similar
}

// When these return false the helper will try to preload an ad again.
```

### Remove Banner ads

e.g during gameplay 

```swift
SwiftyAds.shared.removeBanner() 
```

### Remove/Disable ads (in app purchases)

```swift
SwiftyAds.shared.disable()
```

NOTE:

If set to true the methods to show banner and interstitial ads will not fire anymore and therefore require no further editing. 
This will not stop rewarded videos from showing as they should have a dedicated button. Some rewarded videos are not skipabble and therefore should never be shown automatically. This way you can remove banner and interstitial ads but still have a rewarded videos. 

For permanent storage you will need to create your own "removedAdsProduct" property and save it in something like UserDefaults, or preferably Keychain. Than at app launch check if your saved property is set to true and than update the SwiftyAds poperty e.g

```swift
if UserDefaults.standard.bool(forKey: "RemovedAdsKey") == true {
    SwiftyAds.shared.disable()
}
```

### To ask for consent again (GDPR) 

It is required that the user has the option to change their GDPR consent settings, usually via a button in settings.

```swift
SwiftyAds.shared.askForConsent(from: viewController)
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

## Final Info

The sample project is the basic Apple spritekit template. It now shows a banner Ad after launch and an interstitial ad randomly when touching the screen. After a certain amount of clicks all ads will be removed to simulate what a remove ads button would do. 

Please feel free to let me know about any bugs or improvements. 

Enjoy
