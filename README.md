
NOTE: Apple is shutting down the iAd App Network on June the 30th. 
The news on this are very vague so far. Some articles say its closing down completly, some say its only developers that want to advertise their own ads that are affected, others say it will get replaced with an automated service.

I am not sure if you can still submit apps or what will happen to the APIs. Also WWDC is around the corner so maybe we get some further news.

I will include another 3rd party ad provider (most likely RevMob and/or Chartboost) very soon.

https://developer.apple.com/news/?id=01152016a&1452895272

# iAds, AdMob and CustomAds Helpers

A collection of helper classes to integrate Ads from Apple and Google as well as your own custom Ads. This helper has been been made while making my 1st SpriteKit game but should work for any kind of app. 

The cool thing is that iAds will be used when they are supported in the region of the device, otherwise AdMob will be used. iAds tend to have a better impressions and are usually prefered as default ads.
Whats really cool is that if iAd banners are having an error it will automatically load an AdMob banner and if that AdMob banner is than having an error it will try loading an iAd banner again. 
When an iAd inter ad fails it will try an AdMob Inter ad but incase that adMob inter ad also fails it will not try iAd again because you obviously dont want a full screen ad showing at the wrong time.

This Helper creates whats called a shared Banner which is the recommended way by apple. To read more about shared banner ads you can read this documentation from Apple
https://developer.apple.com/library/ios/technotes/tn2286/_index.html

# Set up DEBUG flag

Set-Up "-D DEBUG" custom flag. 
This will reduce the hassle of having to manually change the google ad ids when testing or when releasing. This step is important as google ads will otherwise not work automatically. This is a good idea in general for other things such as hiding print statements.

Click on Targets (left project sideBar, at the top) -> BuildSettings. Than underneath buildSettings next to the search bar on the left there should be buttons called Basic, All, Combined and Level. 
Click on All and than you should be able to scroll down in buildSettings and find the section called SwiftCompiler-CustomFlags. Click on other flags and than debug and add a custom flag named -D DEBUG (see the sample project or http://stackoverflow.com/questions/26913799/ios-swift-xcode-6-remove-println-for-release-version)

# Set up AdMob SDK and frameworks if included

- Step 1: 

Copy the Google framework folder found in the sample project into your projects folder on your computer. Its best to copy it to your projects root folder because if you just reference the file (next Step) from a random location on your computer it could cause issues when that file gets deleted/moved. You can download the latest version from Googles website (https://developers.google.com/admob/ios/download)

- Step 2: 

Add the Google framework to your project. Go to Targets -> BuildPhases -> LinkedBinaries and click the + button. Than press the "Add Other" button and search your computer for the folder you copied at Step 3 containing the googleframework file and add that file. Your linkedBinaries should now say 1.

NOTE: - If you ever update the frameworks, you will need delete the old framework from your project siderbar and the framework folder from your projects root folder on your computer. You need to than go to Targets-BuildSettings-SearchPaths and under FrameworkSearchPaths you should see a link to your old folder. Delete this link to ensure there are no warnings when you add an updated version and than redo step 4.

- Step 3: 

Add the other frameworks needed. Click the + button again and search for and than add each of these frameworks: AdSupport, AudioToolbox, AVFoundation, CoreGraphics, CoreMedia, CoreTelephony, EventKit, EventKitUI, MessageUI, StoreKit, SystemConfiguration. (https://developers.google.com/admob/ios/quick-start?hl=en). 

You might want to consider putting all the added frameworks you now see in your projects sidebar into a folder called Frameworks, similar to the sample project, to keep it clean.

# Full helper with all ads

SETUP

- Step1: 

Copy the Ads folder into your project. This should include the files

AdsManager.swift 

IAds.swift

AdMob.swift

CustomAds.swift

- Step 2:

In your ViewController write the following in ```ViewDidLoad``` before doing any other app set-ups. 
```swift
AdsManager.sharedInstance.setUp(viewController: self, customAdsCount: 2, customAdsInterval: 5)
```

This sets the viewController property in the helpers to your viewController. In this example there is 2 custom ads in total. The first interAd will be a custom one. The interval means that every 4th time an Inter ad is shown it will show a custom one, randomised between the total ads count.

To add more custom adds go to the struct CustomAds in CustomAd.swift and add more properties. Than go to the method 

```swift
func showInterAd() { ....
```

and add more cases to the switch statement to match your total custom Ads you want to show. 

HOW TO USE

- If you are using multiple Ad providers than iAds are always shown by default unless they are not supported. If you want to manually test Google ads comment out this line in the init method of AdsManager.swift.
```swift
iAdsAreSupported = iAdTimeZoneSupported()
```

- To show a supported Ad simply call these anywhere you like in your project
```swift
AdsManager.sharedInstance.showBanner() 
AdsManager.sharedInstance.showBannerWithDelay(1) // delay showing banner slightly eg when transitioning to new scene/view
AdsManager.sharedInstance.showInter()
AdsManager.sharedInstance.showInterRandomly(randomness: 4) // 25% chance of showing inter ads (1/4)
```

- To remove Banner Ads, for example during gameplay 
```swift
AdsManager.sharedInstance.removeBanner() 
```

- To remove all Ads, mainly for in app purchases simply call 
```swift
AdsManager.sharedInstance.removeAll() 
```

NOTE: - This method will set a removedAds bool to true in all the ad helpers. This ensures you only have to call this method to remove Ads and afterwards all the show methods such as
```swift
AdsManager.sharedInstance.show...
```

will not fire anymore and therefore require no further editing.

For permanent storage you will need to create your own "removedAdsProduct" bool and save it in something like NSUserDefaults, Keychain or a class using NSCoding and than call this method when your app launches.

- To pause/resume tasks in your app/game when Ads are viewed you can implement the delegate methods if needed

Set the delegate in your GameScenes "didMoveToView" (init) method like so
```swift
AdsManager.sharedInstance.delegate = self 
```

Than create an extension in your SKScene or ViewController conforming to the protocol.
```swift
extension GameScene: AdsDelegate {
    func adClicked() {
        // pause your game/app
    }
    func adClosed() { 
       // resume your game/app
    }
}
```

NOTE: For adMob these only get called when in release mode and not when in test mode.


# Multiple Ad providers without custom ads

Follow the same steps as above but exclude the CustomAds.swift file. Than in AdsManager.swift you should see some errors which you need to delete. This should be fairly straight forward, simply remove all the errors that relate to custom Ads.

Than in your ViewController write the following in ```ViewDidLoad``` before doing any other app set-ups. 
```swift
AdsManager.sharedInstance.setUp(viewController: self, customAdsCount: 0, customAdsInterval: 0)
```

# Single Ad provider with custom ads

Follow the same steps as above. Copy the ads folder into your project minus the adProvider that you do not wish to use. Than again delete all the errors in AdsManager.swift.

# Single Ad provider without custom ads

SETUP

- Step 1:

Copy the relevant file from the Ads folder into your project (e.g AdMob.swift). 

- Step 2:

Copy the struct 
```swift
struct Debug {...
```
right at the top of AdsManager.swift into the file your copied at step 1.

- Step 2:

In your ViewController write the following in ```ViewDidLoad``` before doing any other app set-ups
```swift
AdMob.setUp(viewController: self)
```

HOW TO USE

- To show a supported Ad simply call these anywhere you like in your project
```swift
AdMob.sharedInstance.showBanner() 
AdMob.sharedInstance.showBannerWithDelay(1) // delay showing banner slightly eg when transitioning to new scene/view
AdMob.sharedInstance.showInter()
AdMob.sharedInstance.showInterRandomly(randomness: 4) // 25% chance of showing inter ads (1/4)
```

- To remove Banner Ads, for example during gameplay 
```swift
AdMob.sharedInstance.removeBanner() 
```

- To remove all Ads, mainly for in app purchases simply call 
```swift
AdMob.sharedInstance.removeAll() 
```

NOTE: - This method will set a removedAds bool to true in the ad helper. This ensures you only have to call this method to remove Ads and afterwards all the show methods such as
```swift
AdMob.sharedInstance.show...
```

will not fire anymore and therefore require no further editing.

For permanent storage you will need to create your own "removedAdsProduct" bool and save it in something like NSUserDefaults, Keychain or a class using NSCoding and than call this method when your app launches.

- To pause/resume tasks in your app/game when Ads are viewed you can implement the delegate methods if needed

Set the delegate in your GameScenes "didMoveToView" (init) method like so

```swift
AdMob.sharedInstance.delegate = self
```

Than create an extension conforming to the protocol (this helps with clean code as well) 
```swift
extension GameScene: AdMobDelegate {
    func adMobAdClicked() {
        // pause your game/app
    }
    func adMobAdClosed() { 
       // resume your game/app
    }
}
```

NOTE: For adMob these only get called when in release mode and not when in test mode.

# Supporting both landscape and portrait orientation

- If your app supports both portrait and landscape orientation go to the ViewController add the following method.

```swift
override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        
        coordinator.animateAlongsideTransition({ (UIViewControllerTransitionCoordinatorContext) -> Void in
            
            // Multiple ad providers
            AdsManager.sharedInstance.orientationChanged()
            
            // Single ad provider (e.g AdMob)
            AdMob.sharedInstance.orientationChanged()
            
            }, completion: { (UIViewControllerTransitionCoordinatorContext) -> Void in
                print("Device rotation completed")
        })
    }
```
NOTE: This is an ios 8 method, if your app supports ios 7 or below you maybe want to use something like a
```swift
NSNotificationCenter UIDeviceOrientationDidChangeNotification Observer
```

# When you go Live 

iAd 

- Step 1: If you havent used iAds before make sure your account is set up for iAds. You mainly have to sign an agreement in your developer account. (https://developer.apple.com/iad/)

AdMob

- Step 1: Sign up for a Google AdMob account and create your real ad IDs, 1 for banner and 1 for inter Ads. (https://support.google.com/admob/answer/2784575?hl=en-GB)

- Step 2: In Ads.swift in the struct called AdUnitId enter your real Ad IDs for both banner and inter ads.

- Step 3: When you submit your app on iTunes Connect do not forget to select YES for "Does your app use an advertising identifier", otherwise it will get rejected. If you only use iAds and no 3rd party ad provider make sure you select NO, otherwise your app will also get rejected.

NOTE: - Dont forget to setup the "-D DEBUG" custom flag or the helper will not work correctly with adMob.

# Resize view for banner ads

This only works for iAds, I am not sure if you can achieve the same effect with AdMob.
In SpriteKit games you normally dont want the view to resize when showing banner ads, however in UIKit apps this might be prefered. To resize your views when iAd banners are shown you need to let apple create the banners. You can use the canDisplayBannerAds bool property to achieve this. You should change the showBannerAd method in IAds.swift so it looks like this

```swift
  func showBanner(...) {
        ...
        presentingViewController.canDisplayBannerAds = true
        //iAdLoadBannerAd()
    }
```
NOTE:
This might not create a sharedBanner ad that can be used accross multiple viewControllers.

# Final Info

The sample project is the basic Apple spritekit template. It now shows a banner Ad on launch and an inter ad randomly when touching the screen. After 5 clicks all ads will be removed to simulate what a removeAds button would do. 
Like I mentioned above I primarly focused on SpriteKit to make it easy to call Ads from your SKScenes without having to use NSNotificationCenter or Delegates to constantly communicate with the viewController. Also this should help keep your viewController clean as mine became a mess after integrating AdMob.

Please let me know about any bugs or improvements, I am by no means an expert. 

Enjoy

# Release Notes

- v4.0

Complete redesign of the helper. The project was getting too big for my liking and since I am planning on adding another Ad provider soon I decided to split the helper into individual files.

This should make code cleaner and better to maintain as well as easier to understand. I also think this way is more flexible because you can decide to just use a single Ad provider without having to edit the whole project. 

Please re-read the instructions again for the new setUp.






 
