# SwiftyAd

A Swift helper to integrate Ads from AdMob so you can easily show banner, interstitial and rewarded video ads anywhere in your project.

This helper follows all the best practices in regards to ads, like creating shared banners and correctly preloading interstitial and rewarded video ads so they are always ready to show.

# Rewarded Videos

Admob reward videos will only work when using a 3rd party mediation network such as Chartboost or Vungle. 
Read the AdMob mediation guidlines 

https://support.google.com/admob/bin/answer.py?answer=2413211

https://developers.google.com/admob/ios/mediation

https://developers.google.com/admob/ios/mediation-networks

and rewarded video guidlines 

https://developers.google.com/admob/ios/rewarded-video

Than read your 3rd party ad network(s) of choice mediation guidlines to set up reward videos correctly. This will unclude installing their SDK and mediation adapters. 

NOTE: AdMob reward videos will either show a black full screen ad when using the test AdUnitID or not show one at all.

# "DEBUG" custom flag

AdMob uses 2 types of AdUnit IDs, 1 for testing and 1 for release. This helper will automatically change the AdUnitID from test to release mode and vice versa. 

You should not show real ads when you are testing your app. In the past Google has been quite strict and has closed down AdMob/AdSense accounts because ads were clicked on apps that were not live. Keep this in mind when you for example test your app via TestFlight because your app will be in release mode when you send a TestFlight build which means it will show real ads.

With the latest xCode it is no longer necessary to setup the DEBUG flag manually.

# Pre-setup

- Step 1: Sign up for a Google AdMob account and create your real adUnitIDs for your app, one for each type of ad you will use (Banner, Interstitial, Reward Ads).

https://support.google.com/admob/answer/3052638?hl=en-GB&ref_topic=3052726

- Step 2: Install AdMob SDK

// Cocoa Pods
https://developers.google.com/admob/ios/quick-start#streamlined_using_cocoapods

// Manually
https://developers.google.com/admob/ios/quick-start#manually_using_the_sdk_download

I would recommend using Cocoa Pods especially if you will add more SDKs down the line from other ad networks.

They have an app now which should makes managing pods alot easier.
https://cocoapods.org/app

- Step 3: Copy the following file into your project.

```swift
SwiftyAd.swift
```

# How to use

- Setup up the helper with your AdUnitIDs as soon as your app launches e.g AppDelegate or 1st ViewController.

```swift
SwiftyAd.shared.setup(
      withBannerID:    "Enter your real id or leave empty if unused", 
      interstitialID:  "Enter your real id or leave empty if unused", 
      rewardedVideoID: "Enter your real id or leave empty if unused"
)
```

- To show an Ad call these methods anywhere you like in your project

UIViewController
```swift
SwiftyAd.shared.showBanner(from: self) 
SwiftyAd.shared.showBanner(from: self, at: .top) // Shows banner at the top
SwiftyAd.shared.showInterstitial(from: self)
SwiftyAd.shared.showInterstitial(from: self, withInterval: 4) // Shows an ad every 4th time method is called
SwiftyAd.shared.showRewardedVideo(from: self) // Should be called when pressing dedicated button
```
SKScene
(Do not call this in didMoveToView as .window property is still nil at that point. Use a delay or call it later)
```swift
if let viewController = view?.window?.rootViewController {
     SwiftyAd.shared.showBanner(from: viewController) 
     SwiftyAd.shared.showBanner(from: viewController, at: .top) // Shows banner at the top
     SwiftyAd.shared.showInterstitial(from: viewController)
     SwiftyAd.shared.showInterstitial(from: viewController, withInterval: 4) // Shows an ad every 4th time method is called  
     SwiftyAd.shared.showRewardedVideo(from: viewController) // Should be called when pressing dedicated button
}
```

Note:

You should only show rewarded videos with a dedicated button and you should only show that button when a video is loaded (see below). If the user presses the rewarded video button and watches a video it might take a few seconds for the next video to reload. Incase the user immediately tries to watch another video this helper will show a "no video is available at the moment" alert. 

- To check if ads are ready

```swift
if SwiftyAd.shared.isRewardedVideoReady {
    // show reward video button
}

if SwiftyAd.shared.isInterstitialReady {
    // maybe show custom ad or something similar
}

// When these return false the helper will try to preload an ad again.
```

- To remove Banner Ads, for example during gameplay 
```swift
SwiftyAd.shared.removeBanner() 
```

- To remove all Ads, mainly for in app purchases, simply call 
```swift
SwiftyAd.shared.isRemoved = true 
```

NOTE: Remove Ads bool 

If set to true the methods to show banner and interstitial ads will not fire anymore and therefore require no further editing. 

For permanent storage you will need to create your own "removedAdsProduct" property and save it in something like UserDefaults, or preferably Keychain. Than at app launch check if your saved property is set to true and than update the SwiftyAds poperty e.g

```swift
if UserDefaults.standard.bool(forKey: "RemovedAdsKey") {
    SwiftyAd.shared.isRemoved = true 
}
```

This will not stop rewarded videos from showing as they should have a dedicated button. Some rewarded videos are not skipabble and therefore should never be shown automatically. This way you can remove banner and interstitial ads but still have a rewarded videos. 

- Implement the delegate methods.

Set the delegate in the relevant SKScenes ```DidMoveToView``` method or in your ViewControllers ```ViewDidLoad``` method
to receive delegate callbacks.
```swift
SwiftyAd.shared.delegate = self 
```

Than create an extension conforming to the AdsDelegate protocol.
```swift
extension GameScene: SwiftyAdDelegate {
    func swiftyAdDidOpen(_ swiftyAd: SwiftyAd) {
        // pause your game/app if needed
    }
    func swiftyAdDidClose(_ swiftyAd: SwiftyAd) { 
       // resume your game/app if needed
    }
    func swifyAd(_ swiftyAd: SwiftyAd, didRewardUserWithAmount rewardAmount: Int) {
        self.coins += rewardAmount
       // Reward amount is a decimel number I converted to an integer for convenience. This value comes from your AdNetwork.
     
       // You can ignore this and hardcode the value if you would like but than you cannot change the value dynamically without having to update your app.
       
       // You could also ignore the reward amount and do something else, for example unlocking a level or bonus item.
       
       // Leave empty if unused
    }
}
```

Note:

This helper will pass a default reward amount to the below method

```swift
func swiftyAd(_ swiftyAd: SwiftyAd, didRewardUserWithAmount rewardAmount: Int) {
```

incase there is a problem fetching the value from the ad network or you set it to 0 by accident. The default value is 1. You can change this in the setup method.

```swift
SwiftyAd.shared.setup(
      withBannerID:    ..., 
      interstitialID:  ..., 
      rewardedVideoID: ...,
      rewardAmountBackup: 20
)
```

# When you submit your app to Apple

When you submit your app to Apple on iTunes connect do not forget to select YES for "Does your app use an advertising identifier", otherwise it will get rejected. If you use reward videos you should also select the 3rd bulletpoint.

# Tip

From my personal experience and from a user perspective you should not spam full screen interstitial ads all the time. This will also increase your revenue because user retention rate is higher so you should not be greedy. Therefore you should

1) Not show an interstitial ad everytime a button is pressed 
2) Not show an interstitial ad everytime you die in a game

# Final Info

The sample project is the basic Apple spritekit template. It now shows a banner Ad after launch and an interstitial ad randomly when touching the screen. After a certain amount of clicks all ads will be removed to simulate what a remove ads button would do. 

Please feel free to let me know about any bugs or improvements. 

Enjoy

# Release Notes

- v8.1.2

Orientation changes are now handled automatically

- v8.1.1

Removed left-over test function

- v8.1

Banners are now positioned with constraints

iPhoneX support

- v8.0.1

Swift 4 update

- v8.0

Project has been renamed to SwiftyAd

Updated show methods

Updated delegate methods

Project cleanup

Please check the documentation again
