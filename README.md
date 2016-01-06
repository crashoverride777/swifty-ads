# iAds, AdMob and CustomAds Helper

A simple helper class that should make integrating Ads from Apple and Google as well as your own custom Ads a breeze.
I decided to go the Singleton way but please feel free to change that if you dont like it. This helper has been made while designing my SpriteKit game but it can be used for any kind of app. 

The cool thing is that iAds will be used when they are supported otherwise AdMob will be used. 
Whats really cool is that if iAd banners are having an error it will automatically load an AdMob banner. In case that AdMob banner is than having an error it will load an iAd banner again. 

If an iAd Inter ad fails it will try an AdMob Inter ad, incase that adMob inter ad also fails it will however not try iAd again because you obviously dont want a full screen ad show at the wrong time.

This Helper creates whats called a shared Banner which is the recommended way by apple. The usual way is to put the iAd and adMob banner properties into the appDelegate but because this helper is a Singleton there is no need for this because there is only 1 instance of the class. To read more about shared banner ads read this documentation from Apple
https://developer.apple.com/library/ios/technotes/tn2286/_index.html

# Set-Up

- Step 1: Set-Up "-D DEBUG" custom flag. This will reduce the hassle of having to manually change the google ad ids when testing or when releasing. This is a good idea in general for other things such as hiding print statements.
Go to Targets -> BuildSettings -> SwiftCompiler-CustomFlags and add a custom flag named "-D DEBUG "under the Debug section (see the sample project or http://stackoverflow.com/questions/26913799/ios-swift-xcode-6-remove-println-for-release-version)

- Step 2: Copy the Ads.swift file into your project

- Step 3: Copy the Google framework folder found in the sample project into your projects folder on your computer. Its best to copy it to your projects root folder because if you just reference the file (next Step) from a random location on your computer it could cause issues when that file gets deleted/moved. You can download the latest version from Googles website (https://developers.google.com/admob/ios/download)

- Step 4: Add the Google framework to your project. Go to Targets -> BuildPhases -> LinkedBinaries and click the + button. Than press the "Add Other" button and search your computer for the folder you copied at Step 3 containing the googleframework file and add that file. Your linkedBinaries should now say 1.

NOTE: - If you ever update the frameworks, you will need delete the old framework from your project siderbar and the framework folder from your project root folder. You need to than go to Targets-BuildSettings-SearchPaths and under FrameworkSearchPaths you should see a link to your old folder. Delete this link and than redo step 4 to add the updated version.

- Step 5: Add the other frameworks needed. Click the + button again and search for and than add each of these frameworks: AdSupport, AudioToolbox, AVFoundation, CoreGraphics, CoreMedia, CoreTelephony, EventKit, EventKitUI, MessageUI, StoreKit, SystemConfiguration. (https://developers.google.com/admob/ios/quick-start?hl=en
 ). 
You might want to consider putting all the added frameworks you now see in your projects sidebar into a folder called Frameworks, similar to the sample project, to keep it clean.

- Step 6: In your ViewController write the following in ```ViewDidLoad``` before doing any other app set-ups. 
```swift
Ads.sharedInstance.presentingViewController = self
```

This sets the presentingViewController property to your current ViewController and inits Ads.swift. This step is important because your app will crash otherwise when trying to call an Ad. In a spriteKit game this really needs to be called just once since there usually is only 1 viewController.

NOTE: If your app is not a spriteKit game or uses multiple view controllers than you should ignore this Step and check "not a SpriteKit game?" after reading the rest.

- Step 7: This Step is only needed if your app supports both portrait and landscape orientation. Still in your ViewController add the following method.
```swift
override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        
        coordinator.animateAlongsideTransition({ (UIViewControllerTransitionCoordinatorContext) -> Void in
            
            Ads.sharedInstance.orientationChanged()
            
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
NOTE: This is an ios 8 method, if your app supports ios 7 or below you maybe want to use something like a  NSNotifcationCenter UIDeviceOrientationDidChangeNotification Observer

# How to use

There should be no more errors in your project now and the Helper is ready to be used. You can blame Google for most of the work here. 

- iAds are always shown by default unless they are not supported. If you want to manually test Google ads comment out this line in the init method,
```swift
iAdsAreSupported = iAdTimeZoneSupported()
```

- To show a supported Ad simply call these anywhere you like in your project.
```swift
Ads.sharedInstance.showBannerAd() 
Ads.sharedInstance.showBannerAdDelayed() // delay showing banner slightly eg when transitioning to new scene/view
Ads.sharedInstance.showInterAd(includeCustomAd: true) // if true it will show a customAd every 4th time an ad is shown
Ads.sharedInstance.showInterAdRandomly(includeCustomAd: true) // 33% chance of showing inter ads, if true it will show a customAd every 4th time an ad is shown. Settings can always be tweaked
```
- To remove Banner Ads, for example during gameplay 
```swift
Ads.sharedInstance.removeBannerAds() 
```

- To remove all Ads, mainly for in app purchases simply call 
```swift
Ads.sharedInstance.removeAllAds() 
```

NOTE: - This method will set a removedAds bool to true in the Ads.swift helper. This ensures you only have to call this method to remove Ads and afterwards all the above "Ads.sharedInstance.show..." methods will not fire anymore and therefore require no further editing.

For permanent storage you will need to create your own product bool and save it in something like NSUserDefaults, Keychain or NSCoding and than call this method when your app launches.

- To pause/resume tasks in your app/game when Ads are viewed you can implement the delegate methods if needed

Set the delegate in the same GameScene "didMoveToView" (init) method like so
```swift
Ads.sharedInstance.delegate = self
```

and create an extension conforming to the protocol (this helps with clean code as well)
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

- To add more custom Ads simply create a new struct called CustomAd2 with the new properties and than go to the method
```swift
func showInterAd(includeCustomAd showCustomAd: Bool) {
```
and see the comments I made.

# When you go Live 

- Step 1: If you havent used iAds before make sure your account is set up for iAds. You mainly have to sign an agreement in your developer account. (https://developer.apple.com/iad/)

- Step 2: Sign up for a Google AdMob account and create your ad IDs, 1 for banner and 1 for inter Ads. (https://support.google.com/admob/answer/2784575?hl=en-GB)

- Step 3: In Ads.swift in the struct called AdUnitId enter your real Ad IDs for both banner and inter ads.

- Step 4: When you submit your app on iTunes Connect do not forget to select YES for "Does your app use an advertising identifier", otherwise it will get rejected. If you decide to just use iAds than remove all google frameworks and references from your project and make sure you select NO, otherwise your app will also get rejected.

NOTE: - Dont forget to setup the "-D DEBUG" custom flag (step 1) or the helper will not change the google adUnit IDs automatically from test to release. 

# Not a SpriteKit game?
If you have an app that mainly uses viewControllers to show its UI than it might be clunky to call 
```swift 
Ads.sharedInstance.presentingViewController = self
```
especially repeatedly when changing viewControllers. For those apps you should change all the user methods in Ads.swift such as this
```swift 
  func showBannerAd() {
        ...
    }
```
to
```swift 
  func showBannerAd(viewController: UIViewController) {
        presentingViewController = viewController
        ...
    }
 ```
 
Than call the user methods from your ViewControllers like so

```swift
Ads.sharedInstance.showBannerAd(self)
etc
```

# Final Info

The sample project is the basic Apple spritekit template. It now shows a banner Ad on launch and an inter ad randomly when touching the screen. 
Like I mentioned above I primarly focused on SpriteKit to make it easy to call Ads from your SKScenes without having to use NSNotificationCenter or Delegates to constantly communicate with the viewController. Also this should help keep your viewController clean as mine became a mess after integrating AdMob.

Please let me know about any bugs or improvements, I am by now means an expert. 

Enjoy

# Release Notes

v 3.1

- Removed iAd and AdMob banner properties from the appDelegate because there is no need for this with a Singleton because there is only 1 instance of the class anyway.
- If you used a previous version of this helper you can delete the 1 "let appDelegate..." property and 2 banner properties in your "AppDelegate.swift"

v 3.0

- Added ability to show custom ads
- Added extension to hide print statements for release
- Small fixes, improvements and clean-up







 
