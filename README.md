# AdMob and CustomAds Helpers for iOS and AppLovin for tvOS.

A collection of helper classes to integrate Ads from AdMob, AppLovin (tvOS) as well as your own custom Ads. This helper has been been made while making my 1st SpriteKit game but should work for any kind of app. 

With these helpers you can easily show Banner Ads, Interstitial Ads, RewardVideoAds and your own custom Ads anywhere in your project

This Helper creates whats called a shared Banner which is the recommended way by apple to show banners. To read more about shared banner ads you can read this documentation from Apple which should be used for banner ads by all providers.
https://developer.apple.com/library/ios/technotes/tn2286/_index.html

This helper should also correctly preload Interstitial Ads and RewardVideo ads automatically so that they are always ready to be shown instantly when requested.  

# Mediation

I think mediation via AdMob is the best way forward with this helper if you would like to use multiple ad networks. This means you can use the AdMob APIs to show ads from multiple providers,without having to write extra code. 
To add mediation networks please follow these instructions 

https://support.google.com/admob/bin/answer.py?answer=2413211

https://developers.google.com/admob/ios/mediation

https://developers.google.com/admob/ios/mediation-networks

Note: Mediation will not work on tvOS because the AdMob SDK does not support it, which is why I included AppLovin for tvOS.

# Rewarded Videos

Admob reward videos will only work when using a 3rd party mediation network such as Chartboost. Read the AdMob rewarded video guidlines

https://developers.google.com/admob/ios/rewarded-video

and your 3rd party mediation of choice ad network guidlines to set up reward videos correctly.

Note: 

Reward videos will show a black full screen ad using the test AdUnitID. I have not figured out yet how to test ads on AdMob that come from 3rd party mediation networks without using the real AdUnitID.

# Pre-setup iOS

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

# Pre-setup (tvOS)

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

# Pre-setup custom ads

If you are including your own ads it is recommended to read apples marketing guidlines

https://developer.apple.com/app-store/marketing/guidelines/#images

If you will use custom ads and your app/game is only in landscape mode add this code in your AppDelegate. The SKProductViewController used for iOS only supports portrait and will crash if this is not on included for landscape only apps.

```swift
func application(application: UIApplication, supportedInterfaceOrientationsForWindow window: UIWindow?) -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.AllButUpsideDown
    }
```

# Setup -D DEBUG" custom flag.

This step is important because AdMob will otherwise not change AdUnitID from test to release automatically.
This is also useful for things such as hiding print statments.

Click on Targets (left project sideBar, at the top) -> BuildSettings. Than underneath buildSettings next to the search bar, on the left there should be buttons called Basic, All, Combined and Level. Click on All and than you should be able to scroll down in buildSettings and find the section called SwiftCompiler-CustomFlags. Click on other flags and than debug and add a custom flag named -D DEBUG

http://stackoverflow.com/questions/26913799/ios-swift-xcode-6-remove-println-for-release-version)

# How to use

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

- Step 2: Setup Ads Manager (both targets if needed)

In your ViewController write the following in ```ViewDidLoad``` before doing any other app set-ups. 

```swift
AdsManager.sharedInstance.setup(customAdsInterval: 3, maxCustomAdsPerSession: 3)
```

- Step 3: SetUp AdMob (iOS target only)

In your ViewController write the following in ```ViewDidLoad``` before doing any other app set-ups. 
```swift
let bannerID = "Enter your real id"
let interstitialID = "Enter your real id"
let rewardVideoID = "Enter your real id"

AdMob.sharedInstance.setup(viewController: self, bannerID: bannerID, interID: interstitialID, rewardVideoID: rewardVideoID)
```

Step 3: CustomAdSetUp (both targets if needed)

Go to the CustomAd.swift file and right at the top in the Inventory struct create all the  case names for the app/games you would like to advertise. Than enter them into the "all" array as done in the sample project.

To make this as reusable as possible e.g if you have multiple projects and share the same file, you can inlude all your custom ads in the array. The helper will automatically compare the bundle ID name to the ad image (including whitespaces and -) to see if they are the same and if so will move onto the next ad in the inventory.
Please follow the image naming conventions for this  to work. In your asset catalogue the images should look like this
"AdImageYourAppName". 

HOW TO USE

- To show an Ad simply call these anywhere you like in your project
```swift
AdsManager.sharedInstance.showBanner() 
AdsManager.sharedInstance.showBanner(withDelay: 1) // delay showing banner slightly eg when transitioning to new scene/view
AdsManager.sharedInstance.showInterstitial()
AdsManager.sharedInstance.showInterstitial(withRandomness: 4) // 25% chance of showing inter ads (1/4)
```

- To remove Banner Ads, for example during gameplay 
```swift
AdsManager.sharedInstance.removeBanner() 
```

- To remove all Ads, mainly for in app purchases simply call 
```swift
AdsManager.sharedInstance.removeAll() 
```

NOTE: Remove Ads bool 

This method will set a removedAds bool to true in all the ad helpers. This ensures you only have to call this method and afterwards all the methods to show ads will not fire anymore and therefore require no further editing.

For permanent storage you will need to create your own "removedAdsProduct" property and save it in something in NSUserDefaults, or preferably ios Keychain. Than call this method when your app launches after you have set up the helper.

- Implement the delegate methods.

Set the delegate in the relevant SKScenes ```DidMoveToView``` method or in your ViewControllers ```ViewDidLoad``` method
to receive delegate callbacks.
```swift
AdsManager.sharedInstance.delegate = self 
```

Than create an extension conforming to the AdsDelegate protocol.
```swift
extension GameScene: AdsDelegate {
    func adClicked() {
        // pause your game/app if needed
    }
    func adClosed() { 
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

# Supporting both landscape and portrait orientation

- If your app supports both portrait and landscape orientation go to the ViewController and add the following method.

```swift
override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        
        coordinator.animateAlongsideTransition({ (UIViewControllerTransitionCoordinatorContext) -> Void in
           
            AdsManager.sharedInstance.adjustForOrientation()
            
            }, completion: { (UIViewControllerTransitionCoordinatorContext) -> Void in
                print("Device rotation completed")
        })
    }
```
NOTE: This is an ios 8 method, if your app supports ios 7 or below you maybe want to use something like a
```swift
NSNotificationCenter UIDeviceOrientationDidChangeNotification Observer
```

# Helper without AdsManager

If you dont use the ads manager and just want to use a particular helper(s) than you can follow the same set up steps as above (HowToUse). All the helpers have the same method calls.

e.g

```swift
AdMob.sharedInstance.delegate = self
AdMob.sharedInstance.showRewardedVideo()
AppLovin.sharedInstance.showRewardedVideo()
CustomAd.sharedInstance.show() // will show an ad in the inventory and than move on to next one
AdMob.sharedInstance.adjustForOrientation()
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
