# AdMob and CustomAds Helpers for iOS and AppLovin for tvOS.

A collection of helper classes to integrate Ads from AdMob, AppLovin (tvOS) as well as your own custom Ads. This helper has been been made while making my 1st SpriteKit game but should work for any kind of app. 
With these helpers you can easily show Banner Ads, Interstitial Ads, RewardVideoAds and your own custom Ads anywhere in your project

This Helper creates whats called a shared Banner which is the recommended way by apple to show banners. To read more about shared banner ads you can read this documentation from Apple.
https://developer.apple.com/library/ios/technotes/tn2286/_index.html

This helper will also correctly preload Interstitial Ads and Rewarded Videos ads automatically so that they are always ready to be shown instantly when requested.  

# Mediation

I think mediation via AdMob is the best way forward with this helper if you would like to use multiple ad networks. This means you can use the AdMob APIs to show ads from multiple providers, without having to write extra code. 
To add mediation networks please follow these instructions 

https://support.google.com/admob/bin/answer.py?answer=2413211

https://developers.google.com/admob/ios/mediation

https://developers.google.com/admob/ios/mediation-networks

Note: Mediation will not work on tvOS because the AdMob SDK does not support it, which is why I included AppLovin for tvOS.

# Pre-setup iOS only (only needed if AdMob is used)

- Step 1: Sign up for a Google AdMob account and create your real adUnitIDs for your app, one for each type of ad you will use (Banner, Interstitial, Reward Ads).

https://support.google.com/admob/answer/3052638?hl=en-GB&ref_topic=3052726

- Step 2: Install AdMob SDK

// Cocoa Pods
https://developers.google.com/admob/ios/quick-start#streamlined_using_cocoapods

// Manually
https://developers.google.com/admob/ios/quick-start#manually_using_the_sdk_download

I would recommend using Cocoa Pods especially if you will add more SDKs down the line from other ad networks. Its a bit more complicated but once you understand and do it once or twice its a breeze.

They have an app now which should make this alot easier

https://cocoapods.org/app

# Pre-setup tvOS (only needed if AppLovin is used)

Mediation will not work on tvOS because the AdMob SDK does not work with tvOS yet.
Although these instructions can also be applied to iOS I prefer to use mediation on iOS to avoid extra code so I would recommend you only follow these steps when you plan to use ads on tvOS.

Step 1: Create an AppLovin account at

https://applovin.com

Step 2: Log into your account and click on Doc (top right next to account) and tvOS and tvOS SDK integration and follow the steps to install the SDK.

This should include

1) Downloading the SDK folder that includes the headers and lib file and copy it into your project.

Note: I was having some issues with this for ages because I was copying the whole folder from the website into my project. Do NOT do this. 
Make sure you copy/drag the lib file serperatly into your project and than copy the headers folder into your project (select copy if needed and your tvTarget both times)

2) Linking the correct frameworks (AdSupport, UIKit etc)
3) Adding your appLovin SDK key (you can use your key and add it in this sample project to test out ads)
4) Enabling the -ObjC flag in other linkers.


- Step 3: Create an objC bridging header. Go to File-New-File and create a new header file. Call it something like HeaderTV and save.

Than add the app lovin swift libraries in the header file (see sample project if needed)
```swift
#import "ALSwiftHeaders.h"
```

Than go to Targets-BuildSettings and search for "bridging". Double click on "Objective C Bridging Header" and enter the name of the header file followed by .h, for example HeaderTV.h

# Pre-setup custom ads (only needed if you want to show your own custom ads)

If you are including your own ads it is recommended to read apples marketing guidlines

https://developer.apple.com/app-store/marketing/guidelines/#images

If you will use custom ads and your app/game is only in landscape mode add this code in your AppDelegate. The SKProductViewController used for iOS only supports portrait and will crash if this is not on included for landscape only apps.

```swift
func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.allButUpsideDown
}
```

# Rewarded Videos

Admob reward videos will only work when using a 3rd party mediation network such as Chartboost. Read the AdMob rewarded video guidlines

https://developers.google.com/admob/ios/rewarded-video

and your 3rd party mediation of choice ad network guidlines to set up reward videos correctly.

Note: 

Reward videos will show a black full screen ad using the test AdUnitID. I have not figured out yet how to test ads on AdMob that come from 3rd party mediation networks without using the real AdUnitID.


AppLovin reward videos on the other hand need to be set up directly via their documentation as we are directly using their APIs. Go to applovin.com and follow the documentation on how to set up rewarded videos.

# Setup -D DEBUG" custom flag (IMPORTANT)

This step is important because otherwise the AdMob helper will not automatically change the AdUnitID from test to release.
This is also useful for things such as hiding print statments.

Click on Targets (left project sideBar, at the top) -> BuildSettings. Than underneath buildSettings next to the search bar, on the left there should be buttons called Basic, All, Combined and Level. Click on All and than you should be able to scroll down in buildSettings and find the section called SwiftCompiler-CustomFlags. Click on other flags and than debug and add a custom flag named -D DEBUG

http://stackoverflow.com/questions/26913799/ios-swift-xcode-6-remove-println-for-release-version)

# How to use full helper (iOS, tvOS and custom ads)

If you do not wish to use the full helper please skip this part and go to the relevant section after this one (e.g How to use AdMob only)

SETUP

- Step 1: 

Copy the Ads folder into your project. This should include the files

```swift
AdsDelegate.swift
AdsManager.swift 
AdMob(iOS).swift // only add this to iOS target
CustomAds.swift
AppLovin(tvOS).swift // only add this to tvOS target
```

Step 1: CustomAdSetUp (both project targets if needed)

When your app launches setup your custom ads as soon as possible.

```swift
CustomAd.Inventory.all = [
      Ad(imageName: "AdAngryFlappies", appID: "991933749", isNewGame: false),
      Ad(imageName: "AdVertigus", appID: "1051292772", isNewGame: true)
]
```

To make this as reusable as possible e.g if you have multiple projects and share the same file, you can inlude all your custom ads in the array directly in the CustomAds.swift file. The helper will automatically compare the bundle ID name to the ad image (including whitespaces and -) to see if they are the same and if so will move onto the next ad in the inventory.

- Step 2: Setup Ads Manager (both targets if needed)

In your ViewController write the following in ```ViewDidLoad``` before doing any other app set-ups. 

```swift
AdsManager.shared.setup(customAdsInterval: 3, maxCustomAdsPerSession: 3)
```

- Step 3: SetUp AdMob (iOS target only)

In your ViewController write the following in ```ViewDidLoad``` before doing any other app set-ups. 
```swift
let bannerID = "Enter your real id"
let interstitialID = "Enter your real id"
let rewardVideoID = "Enter your real id"

AdMob.shared.setup(viewController: self, bannerID: bannerID, interID: interstitialID, rewardVideoID: rewardVideoID)
```

HOW TO USE

AdsManager.swift is basically a manager of all the ad helpers to have 1 convinient place to call ads from all helpers. AdsManager.swift will automatically show the correct ad depending on your target (iOS or tvOS) and also mix in custom ads with your preferred settings.

- To show an Ad simply call these anywhere you like in your project
```swift
AdsManager.shared.showBanner() 
AdsManager.shared.showBanner(withDelay: 1) // Delay showing banner slightly eg when transitioning to new scene/view
AdsManager.shared.showInterstitial()
AdsManager.shared.showInterstitial(withInterval: 4) // Shows an ad every 4th time
AdsManager.shared.showRewardedVideo()
AdsManager.shared.showRewardedVideo(withInterval: 4) // Shows an ad every 4th time
```

- To remove Banner Ads, for example during gameplay 
```swift
AdsManager.shared.removeBanner() 
```

- To remove all Ads, mainly for in app purchases simply call 
```swift
AdsManager.shared.removeAll() 
```

NOTE: Remove Ads bool 

This method will set a removedAds bool to true in all the ad helpers. This ensures you only have to call this method and afterwards all the methods to show ads will not fire anymore and therefore require no further editing.

For permanent storage you will need to create your own "removedAdsProduct" property and save it in something in NSUserDefaults, or preferably ios Keychain. Than call this method when your app launches after you have set up the helper.

- Implement the delegate methods.

Set the delegate in the relevant SKScenes ```DidMoveToView``` method or in your ViewControllers ```ViewDidLoad``` method
to receive delegate callbacks.
```swift
AdsManager.shared.delegate = self 
```

Than create an extension conforming to the AdsDelegate protocol.
```swift
extension GameScene: AdsDelegate {
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

# How to only use AdMob

If you dont wish to use the full helper and just want to use adMob follow these steps

SETUP

- Step 1: 

Copy the following files into your project

```swift
AdsDelegate.swift
AdMob(iOS).swift
```

- Step 2: 

In your ViewController write the following in ```ViewDidLoad``` before doing any other app set-ups. 
```swift
let bannerID = "Enter your real id"
let interstitialID = "Enter your real id"
let rewardVideoID = "Enter your real id"

AdMob.shared.setup(viewController: self, bannerID: bannerID, interID: interstitialID, rewardVideoID: rewardVideoID)
```

HOW TO USE

- To show an Ad simply call these anywhere you like in your project
```swift
AdMob.shared.showBanner() 
AdMob.shared.showBanner(withDelay: 1) // Delay showing banner slightly eg when transitioning to new scene/view
AdMob.shared.showInterstitial()
AdMob.shared.showInterstitial(withInterval: 4) // Shows an ad every 4th time
AdMob.shared.showRewardedVideo()
AdMob.shared.showRewardedVideo(withInterval: 4) // Shows an ad every 4th time
```

- To remove Banner Ads, for example during gameplay 
```swift
AdMob.shared.removeBanner() 
```

- To remove all Ads, mainly for in app purchases simply call 
```swift
AdMob.shared.removeAll() 
```

NOTE: Remove Ads bool 

This method will set a removedAds bool to true in all the adMob helper. This ensures you only have to call this method and afterwards all the methods to show ads will not fire anymore and therefore require no further editing.

For permanent storage you will need to create your own "removedAdsProduct" property and save it in something in NSUserDefaults, or preferably ios Keychain. Than call this method when your app launches after you have set up the helper.

- Implement the delegate methods.

Set the delegate in the relevant SKScenes ```DidMoveToView``` method or in your ViewControllers ```ViewDidLoad``` method
to receive delegate callbacks.
```swift
AdMob.shared.delegate = self 
```

Than create an extension conforming to the AdsDelegate protocol.
```swift
extension GameScene: AdsDelegate {
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

# How to only use CustomAds

If you dont wish to use the full helper and just want to use custom ads follow these steps

SETUP

- Step 1: 

Copy the following files into your project
```swift
AdsDelegate.swift
CustomAds.swift
```

Step 2:

When your app launches setup your custom ads as soon as possible.

```swift
CustomAd.Inventory.all = [
      Ad(imageName: "AdAngryFlappies", appID: "991933749", isNewGame: false),
      Ad(imageName: "AdVertigus", appID: "1051292772", isNewGame: true)
]
```

To make this as reusable as possible e.g if you have multiple projects and share the same file, you can inlude all your custom ads in the array directly in the CustomAds.swift file. The helper will automatically compare the bundle ID name to the ad image (including whitespaces and -) to see if they are the same and if so will move onto the next ad in the inventory.

HOW TO USE

- To show an Ad simply call these anywhere you like in your project
```swift
CustomAd.shared.show()
```

- To remove all Ads, mainly for in app purchases simply call 
```swift
CustomAd.shared.remove() 
```

NOTE: Remove Ads bool 

This method will set a removedAds bool to true in the custom ads helper. This ensures you only have to call this method and afterwards all the methods to show ads will not fire anymore and therefore require no further editing.

For permanent storage you will need to create your own "removedAdsProduct" property and save it in something in NSUserDefaults, or preferably ios Keychain. Than call this method when your app launches after you have set up the helper.

- Implement the delegate methods.

Set the delegate in the relevant SKScenes ```DidMoveToView``` method or in your ViewControllers ```ViewDidLoad``` method
to receive delegate callbacks.
```swift
CustomAd.shared.delegate = self 
```

Than create an extension conforming to the AdsDelegate protocol.
```swift
extension GameScene: AdsDelegate {
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

# How to only use App Lovin 

If you dont wish to use the full helper and just want to use AppLovin follow these steps

SETUP

- Step 1: 

Copy the following files into your project

```swift
AdsDelegate.swift
AppLovin(tvOS).swift
```

Step 2:

In your ViewController write the following in ```ViewDidLoad``` before doing any other app set-ups. 

```swift
_ = AppLovin.shared
```

HOW TO USE

- To show an Ad simply call these anywhere you like in your project
```swift
AppLovin.shared.showInterstitial()
AppLovin.shared.showInterstitial(withInterval: 4) // Show an ad every  4th time
AppLovin.shared.showRewardedVideo()
AppLovin.shared.showRewardedVideo(withInterval: 4) // Show an ad every  4th time
```

- To remove all Ads, mainly for in app purchases simply call 
```swift
AdMob.shared.removeAll() 
```

NOTE: Remove Ads bool 

This method will set a removedAds bool to true in the app lovin helper. This ensures you only have to call this method and afterwards all the methods to show ads will not fire anymore and therefore require no further editing.

For permanent storage you will need to create your own "removedAdsProduct" property and save it in something in NSUserDefaults, or preferably ios Keychain. Than call this method when your app launches after you have set up the helper.

- Implement the delegate methods.

Set the delegate in the relevant SKScenes ```DidMoveToView``` method or in your ViewControllers ```ViewDidLoad``` method
to receive delegate callbacks.
```swift
AppLovin.shared.delegate = self 
```

Than create an extension conforming to the AdsDelegate protocol.
```swift
extension GameScene: AdsDelegate {
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

# How to only use 2 helpers 

If you only want to use 2 helpers e.g AdMob.swift and CustomAds.swift than follow the same steps as described in

How to only use AdMob
How to only use CustomAds

You will than either need to create your own logic to handle showing real ads from adMob and your own custom ads. 

Alternatively you could include the AdsManager.swift file. Than Follow the steps as described in 

How to use full helper

ingorning all the parts about the  helper you are not using , in this example AppLovin. 

Than go to  AdsManager.swift and delete all the code that shows up as an error, in this example all the code related to AppLovin.

# TVOS controls for custom ads

On tvOS you will have to manually manage the  dismissal and download button for custom ads. Create your  gesture recognizers  or  other control scheme  and  make sure you  can call these 2 methods when a custom ad is shown. I use the menu button for dismissal and the  main button for downloading.

```swift
CustomAd.shared.download()
CustomAd.shared.dismiss()
```

# Supporting both landscape and portrait orientation

- If your app supports both portrait and landscape orientation go to the ViewController and add the following method.

```swift
override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { (UIViewControllerTransitionCoordinatorContext) in
           
            AdsManager.shared.adjustForOrientation()
            
            }, completion: { (UIViewControllerTransitionCoordinatorContext) -> Void in
                print("Device rotation completed")
        })
    }
```
NOTE: This is an ios 8 method, if your app supports ios 7 or below you maybe want to use something like a
```swift
NSNotificationCenter UIDeviceOrientationDidChangeNotification Observer
```

# Set the DEBUG flag?

Dont forget to setup the "-D DEBUG" custom flag or the helper will not work as it will not use the AdUnitIDs or hide print statements.

# When you submit your app to Apple

When you submit your app to Apple on iTunes connect do not forget to select YES for "Does your app use an advertising identifier", otherwise it will get rejected. All apps that use an ad provider and their SDKs, exept iAd, require this to be Yes.

# Final Info

The sample project is the basic Apple spritekit template. It now shows a banner Ad on launch and an interstitial ad randomly when touching the screen. After 5 clicks all ads will be removed to simulate what a removeAds button would do. 

Like I mentioned above I primarly focused on SpriteKit to make it easy to call Ads from your SKScenes without having to use NSNotificationCenter or Delegates to constantly communicate with the viewController. Also this should help keep your viewController nice and clean.

Please feel free to let me know about any bugs or improvements, I am by no means an expert. 

Enjoy

# Release Notes

- v5.6

Cleanup and documentation improvements

Renamed open and close methods in AdsDelegate.swift to

```swift
func adDidOpen() { }
func adDidClose() { }
```

- v5.5.2

Slight change to custom ad handling on tvOS, please read the  "How to use section" again

Cleanup and documentation fixes

- v5.5.1

Cleanup and documentation fixes

- v5.5

Updated to Swift 3

- v5.4

Merged AppLovinInter and AppLovinReward into a single class called AppLovin.
Clean up and improvements

- v5.3.2

Cleanup and small improvements. Please make sure your projects includes the new file AdsDelegate.swift.

- v5.3.1

Small fixes and improvements to custom ads

- v5.3

Custom ad improvements. 

AppStoreProductViewController now used to link to app store on ios.

Please read the instructions again.

- v5.2.2

Instead of optionally showing ads randomly you now can optionally show ads after a set interval e.g. show ad every 4 times the show method is called. 
I prefer this instead of showing ads randomly because occasionally ads would show behind each other or show the first time they are called. I don't think is a good user experience as you dont want users to see ads immediatly after launching/using the app/game.

- v5.2.1

Tweaks and improvements

- v5.2

Custom ad improvements (read instructions for setUp)

Clean-up

- v5.1

Small changes to adMobAdUnitID set up.

- v5.0

Included AppLovin helper for tvOS. The adMob SDK does not work on tvOS so you will have to use AppLovin code if you want to show ads (AppLovin works with mediation on iOS)
