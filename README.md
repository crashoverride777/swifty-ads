# iAds and AdMob Helper

A simple helper class that should make integrating Banner and Interterstitial Ads from Apple and Google a breeze.
I decided to go the Singleton way but please feel free to change that if you dont like it. This helper has been made while designing my SpriteKit game but it can be used for any kind of app. 

The cool thing is that iAds will be used when they are supported otherwise AdMob will be used. 
Whats really cool is that if iAd banners are having an error it will automatically load an AdMob banner. In case that AdMob banner is than having an error it will load an iAd banner again. Nice, because there are tutorials that teach you this, but unfortunately in the wrong way where if the adMob  banner fails it will not reload an iAd banner. You don't want that as it means less money in your pocket.

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
var bannerAdView = ADBannerView()
var googleBannerAdView = GADBannerView()
```

This is what is called a shared Banner ad and although not really needed for a spritekit game with 1 view controller this is the correct way to use banner ads in apps with multiple ViewControllers. (https://developer.apple.com/library/ios/technotes/tn2286/_index.html)

- Step 7: In your viewController write the following in ```ViewDidLoad``` as soon as possible. 
```swift
Ads.sharedInstance.presentingViewController = self
```
This sets the presentingViewController var to your current ViewController and inits Ads.swift. This step is important because your app will crash otherwise when trying to call an Ad. In a spriteKit game this really needs to be called just once since there usually is only 1 viewController.

NOTE: If your app is not a spriteKit game and uses multiple view controllers than you should completly ignore this Step and check "not a SpriteKit game?" after reading the rest.

# How to use

There should be no more errors in your project now and the Helper is ready to be used. You can blame Google for most of the work here. 

- Keep in mind that the Google banner ads (iAds do it automatically ) are set up for portrait mode, if your app is in landscape than you will need to change
```swift 
var googleBannerType
```
from "kGADAdSizeSmartBannerPortrait" to "kGADAdSizeSmartBannerLandscape"

- iAds are always shown by default unless they are not supported. If you want to manually test Google ads comment out the line 
```swift
iAdsAreSupported = iAdTimeZoneSupported()
```
in the init method.

- To show a supported Ad simply call these anywhere you like in your project.
```swift
Ads.loadSupportedBannerAd() 
or
Ads.showSupportedInterAd()
```
- To remove Ads, for example during gameplay or for in app purchases simply call 
```swift
Ads.removeBannerAds() 
or
Ads.removeAllAds()
```
# When you go Live 

Google Ads are a bit of a hassle when testing and when going live because they are using test ad IDs and this line of code 
```swift 
request.testDevices = [ kGADSimulatorID ];
```
So before your app goes live you will have to do the following

- Step 1: If you havent used iAds before make sure your account is set up for iAds. You mainly have to sign an agreement in your developer account. (https://developer.apple.com/iad/)

- Step 2: Sign up for a Google AdMob account and create your ad IDs, 1 for banner and 1 for inter Ads. (https://support.google.com/admob/answer/2784575?hl=en-GB)

- Step 3: In Ads.swift in the struct called ID enter your real Ad IDs for both "bannerLive" and "interLive".

- Step 4: In Ads.swift in
```swift 
func loadGoogleBannerAd()
func preloadGoogleInterAd()
``` 
change the ad ID reference from "ID.bannerTest/ID.interTest" to "ID.bannerLive/ID.interLive" and comment out the line 
```swift 
request.testDevices = [ kGADSimulatorID"
``` 
I wrote some comments at those points to avoid this hassle in the future if you set up a D-DEBUG flag. (http://stackoverflow.com/questions/26913799/ios-swift-xcode-6-remove-println-for-release-version)

- Step 4: When you submit your app on iTunes Connect do not forget to select YES for "Does your app use an advertising identifier", otherwise it will get rejected. If you decide to just use iAds than remove all google frameworks and references from your project and make sure you select NO, otherwise your app will also get rejected.

# Final Info

The sample project is the basic Apple spritekit template. It now shows a banner Ad on launch and an inter ad, if it has loaded, when touching the screen.
To make it easier to call these methods I made class functions in Ads.swift. If you would like to cut down the helper file a bit you can delete all the class functions and call the methods like so
```swift
Ads.sharedInstance.loadSupportedBannerAd()
Ads.sharedInstance.showSupportedInterAd()
etc
```
Like I mentioned above I primarly focused on SpriteKit to make it easy to call Ads from your SKScenes without having to use NSNotificationCenter or Delegates to constantly communicate with the viewController. Also this should help keep your viewController clean as mine became a mess after integrating AdMob.

I also made some comments in the relevant spots of the helper file incase you need to pause your game, music etc.
Please let me know about any bugs or improvements, I am by now means an expert. 

Enjoy

# Not a SpriteKit game?
If you have an app that mainly uses viewControllers to show its UI than it might be clunky to call 
```swift 
Ads.sharedInstance.presentingViewController = self
```
especially repeatedly when changing viewControllers. This might even cause issue with shared banner ads, although I have not tested that myself. For those apps you should change these functions
```swift 
  class func loadSupportedBannerAd() {
        Ads.sharedInstance.loadSupportedBannerAd()
    }
    
    func loadSupportedBannerAd() {
        ...
    }
    
     class func showSupportedInterAd() {
         Ads.sharedInstance.showSupportedInterAd()
    }
    
    func showSupportedInterAd() {
        ...
    }
```
to
```swift 
  class func loadSupportedBannerAd(viewController: UIViewController) {
         Ads.sharedInstance.loadSupportedBannerAd(viewController)
    }
    
    func loadSupportedBannerAd(viewController: UIViewController) {
        presentingViewController = viewController
        ...
    }
    
  class func showSupportedInterAd(viewController: UIViewController) {
         Ads.sharedInstance.showSupportedInterAd(viewController)
    }
    
    func showSupportedInterAd(viewController: UIViewController) {
        presentingViewController = viewController
        ...
    }
 ```
 Than go the Ads.swift init method and remove the line "preloadFirstSupportedInterAd()"
 
 Than edit/add these functions
    
 ```swift
class func preloadFirstSupportedInterAd(viewController: UIViewController) {
         Ads.sharedInstance.preloadFirstSupportedInterAd(viewController)
    }
    
    func preloadFirstSupportedInterAd(viewController: UIViewController) {
        presentingViewController = viewController
        ...
    }
```

You than simply preload the first interAd yourself in the ViewController like so
```swift 
Ads.preloadFirstSupportedInterAd(self)
```

and than show Ads like so
```swift
Ads.loadSupportedBannerAd(self)
or
Ads.showSupportedInterAd(self)
```

# Release Notes

v1.1 - Sorry for all the initial commits, its my first rep. Helper should be good to go now.

v1.0



 
