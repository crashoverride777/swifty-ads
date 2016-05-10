
NOTE: Apple is shutting down the iAd App Network on June the 30th. 
Some articles say it does not affect developers trying to integrate iAds but developers that want to have their own apps advertised. 
Some other articles say it will completly shut down. 
Other articles say it will shut down but relaunch using an automated services to host ads.

I am not sure if you can still submit apps or what will happen to the APIs. In the future when I am 100% sure what will happen with iAds I will include another 3rd party ad provider (most likely RevMob and/or Chartboost)
https://developer.apple.com/news/?id=01152016a&1452895272

# iAds, AdMob and CustomAds Helper

A helper class that should make integrating Ads from Apple and Google as well as your own custom Ads a breeze. This helper has been made while designing my SpriteKit game but should workd for any kind of app. 

The cool thing is that iAds will be used when they are supported otherwise AdMob will be used. iAds tend to have a better impressions and are usually prefered as default ads.
Whats really cool is that if iAd banners are having an error it will automatically load an AdMob banner and if that AdMob banner is than having an error it will try loading an iAd banner again. 
When an iAd inter ad fails it will try an AdMob Inter ad but incase that adMob inter ad also fails it will not try iAd again because you obviously dont want a full screen ad showing at the wrong time.

This Helper creates whats called a shared Banner which is the recommended way by apple. The usual way to achieve this is to put the iAd and adMob banner properties into the appDelegate but because this helper is a Singleton there is no need for this because there is only 1 instance of the class and therefore the banner properties anyway. To read more about shared banner ads you can read this documentation from Apple
https://developer.apple.com/library/ios/technotes/tn2286/_index.html

# Set up DEBUG flag

Set-Up "-D DEBUG" custom flag. This will reduce the hassle of having to manually change the google ad ids when testing or when releasing. This step is important as google ads will otherwise not work automatically.
This is a good idea in general for other things such as hiding print statements.
Go to Targets (left project sideBar, right at the top) -> BuildSettings. Than underneath buildSettings next to the search bar on the left there should be buttons called Basic, All, Combined and Level. 
Click on All and than you should be able to scroll down in buildSettings and find the section called SwiftCompiler-CustomFlags. Click on other flags and than debug and add a custom flag named -D DEBUG (see the sample project or http://stackoverflow.com/questions/26913799/ios-swift-xcode-6-remove-println-for-release-version)

# Set up required AdMob SDK and frameworks

- Step 1: 

Copy the Google framework folder found in the sample project into your projects folder on your computer. Its best to copy it to your projects root folder because if you just reference the file (next Step) from a random location on your computer it could cause issues when that file gets deleted/moved. You can download the latest version from Googles website (https://developers.google.com/admob/ios/download)

- Step 2: 

Add the Google framework to your project. Go to Targets -> BuildPhases -> LinkedBinaries and click the + button. Than press the "Add Other" button and search your computer for the folder you copied at Step 3 containing the googleframework file and add that file. Your linkedBinaries should now say 1.

NOTE: - If you ever update the frameworks, you will need delete the old framework from your project siderbar and the framework folder from your projects root folder on your computer. You need to than go to Targets-BuildSettings-SearchPaths and under FrameworkSearchPaths you should see a link to your old folder. Delete this link to ensure there are no warnings when you add an updated version and than redo step 4.

- Step 3: 

Add the other frameworks needed. Click the + button again and search for and than add each of these frameworks: AdSupport, AudioToolbox, AVFoundation, CoreGraphics, CoreMedia, CoreTelephony, EventKit, EventKitUI, MessageUI, StoreKit, SystemConfiguration. (https://developers.google.com/admob/ios/quick-start?hl=en). 

You might want to consider putting all the added frameworks you now see in your projects sidebar into a folder called Frameworks, similar to the sample project, to keep it clean.

# Set up using multiple Ad providers with custom ads

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

This sets the viewController property in the helpers to your viewController.
In this example there is 2 custom ads in total. The interval means that every 4th time an Inter ad is shown it will show a custom one, randomised between the total ads count. 

To add more custom adds go to the struct CustomAds in CustomAds.swift and add more. Than go to the method 

```swift
func showInter() { ....
```

and add more cases to the switch statement to match your total custom Ads you want to show. 

# Set up using multiple Ad providers no custom ads

Follow the same steps as above but exclude the CustomAds.swift file. Than in AdsManager.swift you should see some errors which you need to delete. This should be fairly straight forward, simply remove all the errors that relate to custom Ads.

Than in your ViewController write the following in ```ViewDidLoad``` before doing any other app set-ups. 
```swift
AdsManager.sharedInstance.setUp(viewController: self, customAdsCount: 0, customAdsInterval: 0)
```

# Set up using single Ad provider and custom ads

Follow the same steps as above. Copy the ads folder into your project minus the adProvider that you do not wish to use. Than again delete all the errors in AdsManager.swift.

# Set up using single adProvider no custom ads

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

# Supporting both landscape and portrait orientation

- Step 1: This Step is only needed if your app supports both portrait and landscape orientation. Still in your ViewController add the following method.
```swift
override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        
        coordinator.animateAlongsideTransition({ (UIViewControllerTransitionCoordinatorContext) -> Void in
            
            // Multiple ad providers
            AdsManager.sharedInstance.orientationChanged()
            
            // Single ad provider (e.g AdMob)
            AdMob.sharedInstance.orientationChanged()
            
            //let orientation = UIApplication.sharedApplication().statusBarOrientation
            //switch orientation {
            //case .Portrait:
            //    print("Portrait")
            //    // Do something
            //default:
            //    print("Anything But Portrait")
            //    // Do something else
            //}
            
            }, completion: { (UIViewControllerTransitionCoordinatorContext) -> Void in
                print("Device rotation completed")
        })
    }
```
NOTE: This is an ios 8 method, if your app supports ios 7 or below you maybe want to use something like a
```swift
NSNotificationCenter UIDeviceOrientationDidChangeNotification Observer
```

# How to use with multiple ad providers

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

NOTE: - These methods will set a removedAds bool to true in the ad helpers. This ensures you only have to call this method to remove Ads and afterwards all the methods such as
```swift
AdsManager.sharedInstance.show...
```

will not fire anymore and therefore require no further editing.

For permanent storage you will need to create your own "removedAdsProduct" bool and save it in something like NSUserDefaults, Keychain or a class using NSCoding and than call it when your app launches.


- To pause/resume tasks in your app/game when Ads are viewed you can implement the delegate methods if needed

Set the delegate in your GameScenes "didMoveToView" (init) method like so
```swift
AdsManager.sharedInstance.delegate = self 
```

Than create an extension in your SKScene conforming to the protocol (this helps with clean code as well) 
```swift
extension GameScene: AdsDelegate {
    func pauseTasks() {
        // pause your game/app
    }
    func resumeTasks() { 
       // resume your game/app
    }
}
```

NOTE: For adMob these only get called when in release mode and not when in test mode.


# How to use with single adProvider only (e.g AdMob)

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

NOTE: - These methods will set a removedAds bool to true in the ad helpers. This ensures you only have to call this method to remove Ads and afterwards all the methods such as
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
    func adMobPause() {
        // pause your game/app
    }
    func adMobResume() { 
       // resume your game/app
    }
}
```

NOTE: For adMob these only get called when in release mode and not when in test mode.

# When you go Live 

iAd 

- Step 1: If you havent used iAds before make sure your account is set up for iAds. You mainly have to sign an agreement in your developer account. (https://developer.apple.com/iad/)

AdMob

- Step 1: Sign up for a Google AdMob account and create your real ad IDs, 1 for banner and 1 for inter Ads. (https://support.google.com/admob/answer/2784575?hl=en-GB)

- Step 2: In Ads.swift in the struct called AdUnitId enter your real Ad IDs for both banner and inter ads.

- Step 3: When you submit your app on iTunes Connect do not forget to select YES for "Does your app use an advertising identifier", otherwise it will get rejected. If you decide to just use iAds than remove all google frameworks and references from your project and make sure you select NO, otherwise your app will also get rejected.

NOTE: - Dont forget to setup the "-D DEBUG" custom flag (step 1) or the helper will not work correctly with adMob.

# Resize view for banner ads

In SpriteKit games you normally dont want the view to resize when showing banner ads, however in UIKit apps this might be prefered. To resize your views (iAds only) you need to let apple create the Banners by themselves by using the canDisplayBannerAds bool. You should change the showBannerAd method in IAds.swift so it looks like this

```swift
  func showBanner(...) {
        ...
        presentingViewController.canDisplayBannerAds = true // uncomment line to resize view for banner ads
        //iAdLoadBannerAd() // comment out if canDisplayBanner ads is used because it now creates banner automatically
    }
```
NOTE:
This might not create a sharedBanner ad that can be used accross multiple viewControllers.

# Final Info

The sample project is the basic Apple spritekit template. It now shows a banner Ad on launch and an inter ad randomly when touching the screen. 
Like I mentioned above I primarly focused on SpriteKit to make it easy to call Ads from your SKScenes without having to use NSNotificationCenter or Delegates to constantly communicate with the viewController. Also this should help keep your viewController clean as mine became a mess after integrating AdMob.

Please let me know about any bugs or improvements, I am by no means an expert. 

Enjoy

# Release Notes

- v4.0

Complete redesign of the helper. The project was getting too big for my liking and since I am planning on adding another ad provider soon I decided to split the helper into individual files.

This has the benefit of

1) Cleaner code

2) Easier to maintain

3) More flexible, people can decide to just use a single Ad provider or use a combination of multiple providers just as before.

Please re-read the instructions again for the new setUp.





 
