# SwiftyAds

A collection of helper classes to integrate Ads from AdMob, AppLovin (tvOS) as well as your own custom Ads. 
With these helpers you can easily show Banner Ads, Interstitial Ads, RewardVideoAds and your own custom Ads anywhere in your project.

This helper follows all the best practices in regards to ads, like creating shared banners and correctly preloading interstitial and rewarded videos so they are always ready to show.

# Cocoa Pods

I know that the current way of copying the .swift file(s) into your project sucks and is bad practice, so I am working hard to finally support CocoaPods very soon. The only problem I have with this repository is the requirement of 3rd party SDKs, so it will not be as easy to do compared to my other repositories.

In the meantime I would create a folder on your Mac, called something like SharedFiles, and drag the swift file(s) into this folder. Than drag the files from this folder into your project, making sure that "copy if needed" is not selected. This way its easier to update the files and to share them between projects.

# Pre-setup: "DEBUG" custom flag

AdMob uses 2 types of AdUnit IDs, 1 for testing and 1 for release. You should not test live ads when you are testing your app.
With this step the helper will not automatically change the AdUnitID from test to release. This is also useful for things such as hiding print statments so you should not forget to include this step.

Click on Targets (left project sideBar, at the top) -> BuildSettings. Than underneath buildSettings next to the search bar, on the left there should be buttons called Basic, All, Combined and Level. Click on All and than you should be able to scroll down in buildSettings and find the section called SwiftCompiler-CustomFlags (alternatively use the search bar). Click on Active Compilation Conditions and add an entry under the Debug section called DEBUG.

NOTE: I think this is added in xCode 8 automatically.

http://stackoverflow.com/questions/26913799/ios-swift-xcode-6-remove-println-for-release-version)

# Pre-setup: AdMob (iOS)

Igore this step if you are not planning to use AdMob.

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

# Pre-setup: AppLovin (tvOS)

Igore this step if you are not planning to use AppLovin on tvOS.

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

# Pre-setup: Custom Ads (iOS and tvOS)

Igore this step if you are not planning to use Custom ads.


If you are including your own ads it is recommended to read apples marketing guidlines
https://developer.apple.com/app-store/marketing/guidelines/#images

If your app/game is only in landscape mode add this code in your AppDelegate. 

NOTE: It seems this is no longer required with iOS 10, so I assume apple made some changes. I am not sure if its still needed for iOS 9 or if its a general fix.

```swift
func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.allButUpsideDown
}
```

The SKProductViewController used for iOS only supports portrait and will crash if this is not on included for landscape only apps.

# Mediation

I think mediation via AdMob is the best way forward with this helper if you would like to use multiple ad networks. This means you can use the AdMob APIs to show ads from multiple providers, without having to write extra code. 
To add mediation networks please follow these instructions 

https://support.google.com/admob/bin/answer.py?answer=2413211
https://developers.google.com/admob/ios/mediation
https://developers.google.com/admob/ios/mediation-networks

Note: Mediation will not work on tvOS because the AdMob SDK does not support it, which is why I included AppLovin for tvOS.

# Rewarded Videos

- AdMob

Admob reward videos will only work when using a 3rd party mediation network such as Chartboost or Vungle. Read the AdMob rewarded video guidlines 

https://developers.google.com/admob/ios/rewarded-video

and your 3rd party mediation of choice ad network guidlines to set up reward videos correctly. This will unclude installing their SDK and mediation adapters. AdMob reward videos will either show a black full screen ad when using the test AdUnitID
or not show one at all.

- AppLovin

AppLovin reward videos on tvOS on the other hand need to be set up directly via their documentation as we are directly using their APIs. Go to applovin.com and follow the documentation on how to set up rewarded videos.

# How to use AdMob

SETUP

- Step 1: Copy the following files into your project

```swift
SwiftyAdsDelegate.swift
SwiftyAdsAdMob(iOS).swift
```

- Step 2: In your ViewController write the following in ```ViewDidLoad``` before doing any other app set-ups. 
```swift
let bannerID = "Enter your real id"
let interstitialID = "Enter your real id"
let rewardVideoID = "Enter your real id"

SwiftyAdsAdMob.shared.setup(viewController: self, bannerID: bannerID, interID: interstitialID, rewardVideoID: rewardVideoID)
```

HOW TO USE

- To show an Ad simply call these anywhere you like in your project
```swift
SwiftyAdsAdMob.shared.showBanner() 
SwiftyAdsAdMob.shared.showBanner(withDelay: 1) // Delay showing banner slightly eg when transitioning to new scene/view
SwiftyAdsAdMob.shared.showInterstitial()
SwiftyAdsAdMob.shared.showInterstitial(withInterval: 4) // Shows an ad every 4th time
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

# How to use CustomAds

SETUP

- Step 1: 

Copy the following files into your project
```swift
SwiftyAdsAdsDelegate.swift
SwiftyAdsCustom.swift
```

Step 2:

When your app launches setup your custom ads as soon as possible.

```swift
SwiftyAdsCustom.shared.ads = [
      SwiftyAdsCustom.Inventory(imageName: "AdVertigus", appID: "1051292772", color: .green),
      SwiftyAdsCustom.Inventory(imageName: "AdAngryFlappies", appID: "991933749", color: .blue)
]
```

The first item in the array will include a new" label at the top right corner.
To make this as reusable as possible e.g if you have multiple projects and share the same file, you can inlude all your custom ads in the array. The helper will automatically compare the bundle ID name to the ad image to see if they are the same and if so will move onto the next ad in the inventory.

HOW TO USE

- To show an Ad simply call these anywhere you like in your project
```swift
SwiftyAdsCustom.shared.show()
```

- To remove all Ads, mainly for in app purchases simply call 
```swift
SwiftyAdsCustom.shared.isRemoved = true 
```

NOTE: Remove Ads bool 

If set to true all the methods to show banner and interstitial ads will not fire anymore and therefore require no further editing. 

For permanent storage you will need to create your own "removedAdsProduct" property and save it in something like UserDefaults, or preferably iOS Keychain. Than call this method when your app launches after you have set up the helper.

- Implement the delegate methods.

Set the delegate in the relevant SKScenes ```DidMoveToView``` method or in your ViewControllers ```ViewDidLoad``` method
to receive delegate callbacks.
```swift
SwiftyAdsCustom.shared.delegate = self 
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

- tvOS controls

On tvOS you need to manually handle the download and dismiss button when showing a custom ad. I use the menu button for dismissal and the select button (press touchpad) for download.

```swift
if SwiftAdsCustom.shared.isShowing {
   SwiftyAdsCustom.shared.download()
}

if SwiftAdsCustom.shared.isShowing {
    SwiftAdsCustom.shared.dismiss()
}
```

# How to use App Lovin 

SETUP

- Step 1: 

Copy the following files into your project

```swift
SwiftyAdsDelegate.swift
SwiftyAdsAppLovin(tvOS).swift
```

Step 2:

In your ViewController write the following in ```ViewDidLoad``` before doing any other app set-ups. 

```swift
_ = SwiftyAdsAppLovin.shared
```

HOW TO USE

- To show an Ad simply call these anywhere you like in your project
```swift
SwiftyAdsAppLovin.shared.showInterstitial()
SwiftyAdsAppLovin.shared.showInterstitial(withInterval: 4) // Show an ad every 4th time
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

I removed the AdsManager.swift file in v6.1 as I felt like it was complicating things unnecessarlily and making the helper(s) less flexible. If you are using all 3 helpers at the same time you will have to implement your own logic for showing the correct ad.

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
SwiftyAdsCustom.shared.delegate = self
SwiftyAdsAdMob.shared.delegate = self
SwiftyAdsAppLovin.shared.delegate = self
```

or calling the remove method in all helpers when the remove ads button was pressed

```swift
SwiftyAdsCustom.shared.isRemoved = true 
SwiftyAdsAdMob.shared.isRemoved = true 
SwiftyAdsAppLovin.shared.isRemoved = true 
```

# Supporting both landscape and portrait orientation

- If your app supports both portrait and landscape orientation go to the ViewController and add the following method.

```swift
override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { (UIViewControllerTransitionCoordinatorContext) in
          
            SwiftyAdsAdMob.shared.adjustForOrientation()
            
            }, completion: { (UIViewControllerTransitionCoordinatorContext) -> Void in
                print("Device rotation completed")
        })
    }
```

# Set the DEBUG flag?

Dont forget to setup the "-D DEBUG" custom flag or the helper will not work as it will not use the AdUnitIDs or hide print statements.

# When you submit your app to Apple

When you submit your app to Apple on iTunes connect do not forget to select YES for "Does your app use an advertising identifier", otherwise it will get rejected.

# Final Info

The sample project is the basic Apple spritekit template. It now shows a banner Ad on launch and an interstitial ad randomly when touching the screen. After a certain amount of clicks all ads will be removed to simulate what a removeAds button would do. 

Please feel free to let me know about any bugs or improvements. 

Enjoy

# Release Notes

- v6.1.1

Custom ads improvements

The remove method is deprecated, use isRemoved = true instead

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
