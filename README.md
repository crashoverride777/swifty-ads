# iAds and AdMob Helper

A simple helper class that should make integrating Banner and Interterstitial Ads from Apple and Google a breeze.
I decided to go the Singleton way but please feel free to change that if you dont like it. This helper has been made while designing my SpriteKit game but it can be used for any kind of app. 

The cool thing is that iAds will be used when they are supported otherwise AdMob will be used. 
Whats really cool is that if iAd banners are having an error it will automatically load an AdMob banner. In case that AdMob banner is than having an error it will load an iAd banner again. 

If an iAd Inter ad fails it will try an AdMob Inter ad, incase that adMob inter ad also fails it will however not try iAd again because you obviously dont want a full screen ad show at the wrong time.

# Set-Up

- Step 1: Copy the Ads.swift file into your project

- Step 2: Copy the Google framework folder found in the sample project into your projects folder on your computer. Its best to copy it to your projects root folder because if you just reference the file (Step 3) from a random location on your computer it could cause issues. You can also download the latest version from Googles website (https://developers.google.com/admob/ios/download)

- Step 3: Add the Google framework to your project. Go to Targets - BuildPhases - LinkedBinaries and click the + button and than press the "Add Other" button. Search your computer for the folder you copied at Step 2 containing the googleframework file and add that file. Once you done that click the + button again use the search bar at the top and search for googleframework and than add it. Your linkedBinaries should now say 1.

- Step 4: Add the other frameworks needed. Click the + button again and search for and than add each of these frameworks: AdSupport, AudioToolbox, AVFoundation, CoreGraphics, CoreMedia, CoreTelephony, EventKit, EventKitUI, MessageUI, StoreKit, SystemConfiguration (https://developers.google.com/admob/ios/quick-start?hl=en
 ). This should bring your total linked binary (framework) count to 12. You might want to consider putting all the added frameworks you now see in your project sidebar into a folder called Frameworks, similar to the sample project, to keep it clean.

- Step 5: In your AppDelegate.swift underneath ```import UIKit``` write the following
```swift
import iAd
import GoogleMobileAds

let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
```

- Step 6: Still in your AppDelegate.swift under the class implementation you will need to create these properties

```swift
var iAdBannerAdView = ADBannerView()
var adMobBannerAdView: GADBannerView!
```

This is what is called a shared Banner ad and although not really needed for a spritekit game with 1 view controller this is the correct way to use banner ads in apps with multiple ViewControllers. (https://developer.apple.com/library/ios/technotes/tn2286/_index.html)

- Step 7: In your viewController write the following in ```ViewDidLoad``` before doing any other app set-ups. 
```swift
Ads.sharedInstance.presentingViewController = self
```

This sets the presentingViewController property to your current ViewController and inits Ads.swift. This step is important because your app will crash otherwise when trying to call an Ad. In a spriteKit game this really needs to be called just once since there usually is only 1 viewController.

NOTE: If your app is not a spriteKit game and uses multiple view controllers than you should ignore this Step and check "not a SpriteKit game?" after reading the rest.

- Step 8: This Step is only needed if your app supports both portrait and landscape orientation. Still in your ViewController add the following method.
```swift
override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        
        coordinator.animateAlongsideTransition({ (UIViewControllerTransitionCoordinatorContext) -> Void in
            
            Ads.sharedInstance.deviceOrientationChanged()
            
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
NOTE: This is a ios 8 method, if your app supports ios 7 or below you maybe want to use something like a  NSNotifcationCenter UIDeviceOrientationDidChangeNotification Observer

# How to use

There should be no more errors in your project now and the Helper is ready to be used. You can blame Google for most of the work here. 

- iAds are always shown by default unless they are not supported. If you want to manually test Google ads comment out this line in the init method,
```swift
iAdsAreSupported = iAdTimeZoneSupported()
```

- To show a supported Ad simply call these anywhere you like in your project.
```swift
Ads.sharedInstance.showBannerAd() 
Ads.sharedInstance.showInterAd() // shows inter ad every time
Ads.sharedInstance.showInterAdRandomly() // 25% chance of showing inter ads, can always be tweaked.
```
- To remove Ads, for example during gameplay or for in app purchases simply call 
```swift
Ads.sharedInstance.removeBannerAds() 
Ads.sharedInstance.removeAllAds()
```

- To pause or resume tasks in your app or game when ads are opened/closed use these internal methods. These get called automatically so all you do is enter your code.
```swift
private func pauseTasks() {
}
private func resumeTasks() {
}
```
# When you go Live 

Google Ads are a bit of a hassle when testing and when going live because they are using test ad IDs and this line of code 
```swift 
request.testDevices = [ kGADSimulatorID ];
```
So before your app goes live you will have to do the following

- Step 1: If you havent used iAds before make sure your account is set up for iAds. You mainly have to sign an agreement in your developer account. (https://developer.apple.com/iad/)

- Step 2: Sign up for a Google AdMob account and create your ad IDs, 1 for banner and 1 for inter Ads. (https://support.google.com/admob/answer/2784575?hl=en-GB)

- Step 3: In Ads.swift in the struct called AdUnitId enter your real Ad IDs for both banner and inter ads.

- Step 4: In Ads.swift change the adUnit IDs to LIVE, so the properties look like this
```swift 
private var adMobBannerAdID = AdUnitID.Banner.live
private var adMobInterAdID = AdUnitID.Inter.live
``` 
Than go to both these methods  
```swift 
func adMobLoadBannerAd()
func adMobLoadInterAd()
```
 and comment out the line 
```swift 
request.testDevices = [ kGADSimulatorID"
``` 
I wrote some comments at those points to avoid this hassle in the future if you set up a D-DEBUG flag. (http://stackoverflow.com/questions/26913799/ios-swift-xcode-6-remove-println-for-release-version)

- Step 4: When you submit your app on iTunes Connect do not forget to select YES for "Does your app use an advertising identifier", otherwise it will get rejected. If you decide to just use iAds than remove all google frameworks and references from your project and make sure you select NO, otherwise your app will also get rejected.

# Final Info

The sample project is the basic Apple spritekit template. It now shows a banner Ad on launch and a inter ad randomly when touching the screen.
Like I mentioned above I primarly focused on SpriteKit to make it easy to call Ads from your SKScenes without having to use NSNotificationCenter or Delegates to constantly communicate with the viewController. Also this should help keep your viewController clean as mine became a mess after integrating AdMob.
Please let me know about any bugs or improvements, I am by now means an expert. 

Enjoy

# Not a SpriteKit game?
If you have an app that mainly uses viewControllers to show its UI than it might be clunky to call 
```swift 
Ads.sharedInstance.presentingViewController = self
```
especially repeatedly when changing viewControllers. This might even cause issue with shared banner ads, although I have not tested that myself. For those apps you should change all the user methods such as this
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
 
Than call the methods like so

```swift
Ads.sharedInstance.showBannerAd(self)
etc
```

# Release Notes

v1.8

Fixed an issue that could cause GameCenter banners to show in the wrong orienation. Please update your helper and also update your appdelegate from

var adMobBannerAdView = GADBannerView()

to
 
var adMobBannerAdView: GADBannerView!

v1.7.1

Clean-up

v1.7

Deleted the class methods as it just seemed unnecessary bloat. If you prefer to still use them just change it. Call user methods like so now
    Ads.sharedInstance.showSupportedBannerAd()
    etc

v1.6

Added new method to showInterAds randomly

v1.5

AdMob banner ads now automatically identify if your app is in potrait or landscape

All banner ads now automatically change orientation and adjust their position if you rotate your device

iAd inter ad close button size on iPads has been adjusted.

v1.4.1

Clean-up and small improvements

v1.4

Clean-up and small improvements

v1.3

Upgraded to Swift 2

v1.2

Small changes

v1.1

Sorry for all the initial commits, its my first rep. Helper should be good to go now.

v1.0



 
