# SwiftyAds

A collection of helper classes to integrate Ads from AdMob and AppLovin (tvOS). 
With these helpers you can easily show Banner Ads, Interstitial Ads and RewardVideoAds anywhere in your project.

This helper follows all the best practices in regards to ads, like creating shared banners and correctly preloading interstitial and rewarded videos so they are always ready to show.

NOTE: I recently spoke to app lovin support and it seems that they do not support tvOS anymore. I only included the app lovon code for tvOS because adMob does not support it. I will remove the code in the next uodate.

# Cocoa Pods

I know that the current way of copying the .swift file(s) into your project sucks and is bad practice, so I am working hard to finally support CocoaPods very soon. The only problem I have with this repository is the requirement of 3rd party SDKs, so it will not be as easy to do compared to my other repositories.

In the meantime I would create a folder on your Mac, called something like SharedFiles, and drag the swift file(s) into this folder. Than drag the files from this folder into your project, making sure that "copy if needed" is not selected. This way its easier to update the files and to share them between projects.

# Rewarded Videos

You should only show rewarded videos with a dedicated button and you should only show that button when a video is loaded (see instructions below). If the user presses the reward video button and watches a video it might take a few seconds for the next video to reload afterwards. Incase the user immediately tries to watch another video this helper will show an alert informing the user that no video is available at the moment. 

- AdMob

Admob reward videos will only work when using a 3rd party mediation network such as Chartboost or Vungle. 

Read the AdMob mediation guidlines 

https://support.google.com/admob/bin/answer.py?answer=2413211

https://developers.google.com/admob/ios/mediation

https://developers.google.com/admob/ios/mediation-networks

and rewarded video guidlines 

https://developers.google.com/admob/ios/rewarded-video

Than read your 3rd party ad network(s) of choice mediation guidlines to set up reward videos correctly. This will unclude installing their SDK and mediation adapters. 

NOTE: AdMob reward videos will either show a black full screen ad when using the test AdUnitID or not show one at all.

- AppLovin

AppLovin reward videos on tvOS on the other hand need to be set up directly via their documentation as we are directly using their APIs. Go to applovin.com and follow the documentation on how to set up rewarded videos.

# "DEBUG" custom flag

AdMob uses 2 types of AdUnit IDs, 1 for testing and 1 for release. You should not test live ads when you are testing your app.
This helper will automatically change the AdUnitID from test to release mode and vice versa. 

With the latest xCode it is no longer necessary to setup the DEBUG flag manually.

# AdMob: Pre-setup (iOS)

- Step 1: Sign up for a Google AdMob account and create your real adUnitIDs for your app, one for each type of ad you will use (Banner, Interstitial, Reward Ads).

https://support.google.com/admob/answer/3052638?hl=en-GB&ref_topic=3052726

- Step 2: Install AdMob SDK

// Cocoa Pods
https://developers.google.com/admob/ios/quick-start#streamlined_using_cocoapods

// Manually
https://developers.google.com/admob/ios/quick-start#manually_using_the_sdk_download

I would recommend using Cocoa Pods especially if you will add more SDKs down the line from other ad networks. Its a bit more complicated but once you understand and do it once or twice its a breeze. 

They have an app now which should makes managing pods alot easier.
https://cocoapods.org/app

- Step 3: Copy the following files into your project (see CocoaPods above for reference trick on multiple projects)

```swift
SwiftyAdsDelegate.swift
SwiftyAdsAdMob.swift
```

- Step 4: Setup up the helper when your app launches. 

```swift
SwiftyAdsAdMob.shared.setup(
      viewController: self, 
      bannerID:      "Enter your real id", 
      interID:       "Enter your real id", 
      rewardVideoID: "Enter your real id"
)
```

# AdMob: How to use (iOS)

- To show an Ad simply call these anywhere you like in your project
```swift
SwiftyAdsAdMob.shared.showBanner() 
SwiftyAdsAdMob.shared.showBanner(withDelay: 1) // Delay showing banner slightly eg when transitioning to new scene/view
SwiftyAdsAdMob.shared.showInterstitial()
SwiftyAdsAdMob.shared.showInterstitial(withInterval: 4) // Shows an ad every 4th time method is called
SwiftyAdsAdMob.shared.showRewardedVideo() // Should be called when pressing dedicated button

if SwiftyAdsAdMob.shared.isRewardedVideoReady { // Will try to load an ad if it returns false
    // add reward video button
}
```

- To remove Banner Ads, for example during gameplay 
```swift
SwiftyAdsAdMob.shared.removeBanner() 
```

- To remove all Ads, mainly for in app purchases simply call 
```swift
SwiftyAdsAdMob.shared.isRemoved = true 
```

NOTE: Remove Ads bool 

If set to true all the methods to show banner and interstitial ads will not fire anymore and therefore require no further editing. 

This will not stop rewarded videos from showing as they should have a dedicated button. Some reward videos are not skipabble and therefore should never be shown automatically. This way you can remove banner and interstitial ads but still have a rewarded videos button. 

For permanent storage you will need to create your own "removedAdsProduct" property and save it in something like UserDefaults, or preferably iOS Keychain. Than call this method when your app launches after you have set up the helper.

- Implement the delegate methods.

Set the delegate in the relevant SKScenes ```DidMoveToView``` method or in your ViewControllers ```ViewDidLoad``` method
to receive delegate callbacks.
```swift
SwiftyAdsAdMob.shared.delegate = self 
```

Than create an extension conforming to the AdsDelegate protocol.
```swift
extension GameScene: SwiftyAdsDelegate {
    func adDidOpen() {
        // pause your game/app if needed
    }
    func adDidClose() { 
       // resume your game/app if needed
    }
    func adDidRewardUser(withAmount rewardAmount: Int) {
        self.coins += rewardAmount
       // Reward amount is a DecimelNumber I converted to an Int for convenience. 
       // You can ignore this and hardcore the value if you would like but than you cannot change the value dynamically without having to update your app.
       
       // leave empty if unused
    }
}
```

# AppLovin: Pre-setup (tvOS)

Step 1: Create an AppLovin account at

https://applovin.com

Step 2: Log into your account and click on Doc (top right next to account) and tvOS and tvOS SDK integration and follow the steps to install the SDK.

This should include

1) Downloading the SDK folder that includes the headers and lib file and copy it into your project.

Note: I was having some issues with this for ages because I was copying the whole folder from the website into my project. Do NOT do this. Make sure you copy/drag the lib file serperatly into your project and than copy the headers folder into your project and select copy if needed (Dont forget to do same with the tvOS SDK).

2) Linking the correct frameworks (AdSupport, UIKit etc)
3) Adding your appLovin SDK key (you can use your key and add it in this sample project to test out ads)
4) Enabling the -ObjC flag in other linkers.


- Step 3: Create an objC bridging header. Go to File-New-File and create a new header file. Call it something like HeaderTV and save.

Than add the app lovin swift libraries in the header file (see sample project if needed)
```swift
#import "ALSwiftHeaders.h"
```

Than go to Targets-BuildSettings and search for "bridging". Double click on "Objective C Bridging Header" and enter the name of the header file followed by .h, for example HeaderTV.h

- Step 4: Copy the following files into your project (see CocoaPods above for reference trick on multiple projects)

```swift
SwiftyAdsDelegate.swift
SwiftyAdsAppLovin.swift
```
- Step 5: Setup the helper when your app launches. 

```swift
SwiftyAdsAppLovin.shared.setup()
```

# App Lovin: How to use (tvOS)

- To show an Ad simply call these anywhere you like in your project
```swift
SwiftyAdsAppLovin.shared.showInterstitial()
SwiftyAdsAppLovin.shared.showInterstitial(withInterval: 4) // Show an ad every 4th time method is called
SwiftyAdsAppLovin.shared.showRewardedVideo() // Should be called when pressing dedicated button

if SwiftyAdsAppLovin.shared.isRewardedVideoReady { // Will try to load an ad if it returns false
    // add reward video button
}
```

- To remove all Ads, mainly for in app purchases simply call 
```swift
SwiftyAdsAppLovin.shared.isRemoved = true 
```

NOTE: Remove Ads bool 

If set to true all the methods to show banner and interstitial ads will not fire anymore and therefore require no further editing. 

This will not stop rewarded videos from showing as they should have a dedicated button. Some reward videos are not skipabble and therefore should never be shown automatically. This way you can remove banner and interstitial ads but still have a rewarded videos button. 

For permanent storage you will need to create your own "removedAdsProduct" property and save it in something like UserDefaults, or preferably iOS Keychain. Than call this method when your app launches after you have set up the helper.

- Implement the delegate methods.

Set the delegate in the relevant SKScenes ```DidMoveToView``` method or in your ViewControllers ```ViewDidLoad``` method
to receive delegate callbacks.
```swift
SwiftyAdsAppLovin.shared.delegate = self 
```

Than create an extension conforming to the AdsDelegate protocol.
```swift
extension GameScene: SwiftyAdsDelegate {
    func adDidOpen() {
        // pause your game/app if needed
    }
    func adDidClose() { 
       // resume your game/app if needed
    }
    func adDidRewardUser(withAmount rewardAmount: Int) {
       // leave empty if unused
    }
}
```

# How to use all helpers

I deprecated the AdsManager.swift file in v6.1 as I felt like it was complicating things unnecessarlily and making the helper(s) less flexible and more confusing to beginners. If you are using both helpers at the same time you will have to implement your own logic for showing the correct ad.

To differentiate between targets you can do something like this.

```swift
#if os(iOS)
    SwiftyAdsAdMob.shared.showInterstitial()
#endif
#if os(tvOS)
    SwiftyAdsAppLovin.shared.showInterstitial()
#endif
```

Also do not forget things like settings up the delegates 

```swift
SwiftyAdsAdMob.shared.delegate = self
SwiftyAdsAppLovin.shared.delegate = self
```

or calling the remove method in all helpers when the remove ads button was pressed

```swift
SwiftyAdsAdMob.shared.isRemoved = true 
SwiftyAdsAppLovin.shared.isRemoved = true 
```

# Supporting both landscape and portrait orientation

- If your app supports both portrait and landscape orientation go to the ViewController and add the following method.

```swift
override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { (UIViewControllerTransitionCoordinatorContext) in
          
            SwiftyAdsAdMob.shared.updateForOrientation()
            
            }, completion: { (UIViewControllerTransitionCoordinatorContext) -> Void in
                print("Device rotation completed")
        })
    }
```

# When you submit your app to Apple

When you submit your app to Apple on iTunes connect do not forget to select YES for "Does your app use an advertising identifier", otherwise it will get rejected.

# Final Info

The sample project is the basic Apple spritekit template. It now shows a banner Ad on launch and an interstitial ad randomly when touching the screen. After a certain amount of clicks all ads will be removed to simulate what a removeAds button would do. 

Please feel free to let me know about any bugs or improvements. 

Enjoy

# Release Notes

- v6.2.2

Added AppLovin setup method (see instructions)

Cleanup

- v6.2.1

Added a UIAlertController when the "showRewardedVideo" method is called but the video is not ready. Remember you should only show reward videos with a dedicated button and you should only show that reward video button when a video is loaded. 
However when the user the presses the reward video button and watches a video it might take a few seconds for the next video to reload. If the user immediately tries to watch another video afterwards IMO the easiest and cleanest way is to just show an alert "No video available at the moment"

Removed deprecated methods

Cleanup

- v6.2

Removed Custom ads to further simplify this project

Cleanup

- v6.1.1

Custom ads improvements

The remove methods are deprecated, use "...shared.isRemoved = true" instead

- v6.1

Deprecated the AdsManager as I felt like it was complicating things uncecessarily. This should also make it easier for people to pick and choose what they need and make the helper more flexible and clearer to understand.

- v6.0.3

Cleanup

- v6.0.2

Cleanup

- v6.0.1

Custom ads on tvOS need to be removed manually again. Please check instructions.

Cleanup.

- v6.0

Project has been renamed to SwiftyAds.

No more source breaking changes after this update. All future changes will be handled with deprecated messages unless the whole API changes.
