# SwiftyAds

A Swift helper to integrate Ads from AdMob so you can easily show Banner Ads, Interstitial Ads and RewardVideoAds anywhere in your project.

This helper follows all the best practices in regards to ads, like creating shared banners and correctly preloading interstitial and rewarded videos so they are always ready to show.

# Cocoa Pods

I know that the current way of copying the .swift file(s) into your project sucks and is bad practice, so I am working hard to finally support CocoaPods very soon. The only problem I have with this repository is the requirement of 3rd party SDKs, so it will not be as easy to do compared to my other repositories.

In the meantime I would create a folder on your Mac, called something like SharedFiles, and drag the swift file(s) into this folder. Than drag the files from this folder into your project, making sure that "copy if needed" is not selected. This way its easier to update the files and to share them between projects.

# Rewarded Videos

You should only show rewarded videos with a dedicated button and you should only show that button when a video is loaded (see how to use below). If the user presses the reward video button and watches a video it might take a few seconds for the next video to reload afterwards. Incase the user immediately tries to watch another video this helper will show an alert informing the user that no video is available at the moment. 


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

AdMob uses 2 types of AdUnit IDs, 1 for testing and 1 for release. You should not test live ads when you are testing your app.
This helper will automatically change the AdUnitID from test to release mode and vice versa. 

With the latest xCode it is no longer necessary to setup the DEBUG flag manually.

# Pre-setup

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
SwiftyAds.swift
```

- Step 4: Setup up the helper as soon as your app launches e.g AppDelegate or 1st ViewController.

```swift
SwiftyAds.shared.setup(
      bannerID:      "Enter your real id", 
      interID:       "Enter your real id", 
      rewardVideoID: "Enter your real id"
)
```

# How to use

- To show an Ad simply call these anywhere you like in your project
```swift
// View Controller
SwiftyAds.shared.showBanner(from: self) 
SwiftyAds.shared.showBanner(at: .top, from: self) // Shows banner at the top
SwiftyAds.shared.showInterstitial(from: self)
SwiftyAds.shared.showInterstitial(withInterval: 4, from: self) // Shows an ad every 4th time method is called
SwiftyAds.shared.showRewardedVideo(from: self) // Should be called when pressing dedicated button

// SpriteKit Scene (Needs to be called outside didMoveToView as window property will be nil otherwise)
SwiftyAds.shared.showBanner(from: view?.window?.rootViewController) 
SwiftyAds.shared.showBanner(at: .top, from: view?.window?.rootViewController) // Shows banner at the top
SwiftyAds.shared.showInterstitial(from: view?.window?.rootViewController)
SwiftyAds.shared.showInterstitial(withInterval: 4, from: view?.window?.rootViewController) // Shows an ad every 4th time method is called
SwiftyAds.shared.showRewardedVideo(from: view?.window?.rootViewController) // Should be called when pressing dedicated button
```

- To check if ads are ready

```swift
if SwiftyAds.shared.isRewardedVideoReady {
    // add/show reward video button
}

if SwiftyAds.shared.isInterstitialReady {
    // maybe show custom ad or something similar
}

// When these return false the helper will try to load preload an ad again.
```

- To remove Banner Ads, for example during gameplay 
```swift
SwiftyAds.shared.removeBanner() 
```

- To remove all Ads, mainly for in app purchases simply call 
```swift
SwiftyAds.shared.isRemoved = true 
```

NOTE: Remove Ads bool 

If set to true all the methods to show banner and interstitial ads will not fire anymore and therefore require no further editing. 

This will not stop rewarded videos from showing as they should have a dedicated button. Some reward videos are not skipabble and therefore should never be shown automatically. This way you can remove banner and interstitial ads but still have a rewarded videos button. 

For permanent storage you will need to create your own "removedAdsProduct" property and save it in something like UserDefaults, or preferably iOS Keychain. Than at app launch check if your saved property is set to true and than updated the helper poperty.

- Implement the delegate methods.

Set the delegate in the relevant SKScenes ```DidMoveToView``` method or in your ViewControllers ```ViewDidLoad``` method
to receive delegate callbacks.
```swift
SwiftyAds.shared.delegate = self 
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
       
       // You can also ingore the rewardAmount and do something else, for example unlocking a level or bonus item.
       
       // leave empty if unused
    }
}
```

# Supporting both landscape and portrait orientation

- If your app supports both portrait and landscape orientation go to your ViewControllers and add the following method.

```swift
override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { (UIViewControllerTransitionCoordinatorContext) in
          
            SwiftyAds.shared.updateForOrientation(from: self)
            
            }, completion: { (UIViewControllerTransitionCoordinatorContext) -> Void in
                print("Device rotation completed")
        })
    }
```

# When you submit your app to Apple

When you submit your app to Apple on iTunes connect do not forget to select YES for "Does your app use an advertising identifier", otherwise it will get rejected. If you use reward videos you should also select the 3rd point.

# Final Info

The sample project is the basic Apple spritekit template. It now shows a banner Ad on launch and an interstitial ad randomly when touching the screen. After a certain amount of clicks all ads will be removed to simulate what a removeAds button would do. 

Please feel free to let me know about any bugs or improvements. 

Enjoy

# Release Notes

- v7.0.2

Added ability to show banner ads at the top

Cleanup

- v7.0.1

UIViewController dependency injection 

Cleanup

- v7.0

Removed AppLovin as they no longer support the tvOS platform. If another reliable ad platform for tvOS comes out I will add it to this helper.

Cleanup
