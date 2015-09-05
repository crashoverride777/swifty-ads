# iAds and AdMob Helper

A simple helper class that should make integrating Banner and Interterstitial Ads from Apple and Google a breeze.
I decided to go the Singleton way but please feel free to change that if you dont like it. This helper has been made while designing my SpriteKit game but it can be used for any kind of app. 
It has all the standard features you expect, like banners only animating in when they are ready and disspapearing when they haven an error.

The cool thing is that iAds will be used when they are supported otherwise AdMob will be used. 
Whats really cool is that incase iAd banners are having an error it will automatically load an AdMob banner and in case that AdMob banner is having an error it will load an iAd banner again. 

Nice because that means chances are very low that there are no banners showing wich means more money in your pocket. There are tutorials that teach you this, but in unfortunatley in the wrong way. In those tutorials if there is an iAd banner error and than the adMob banner also has an error, and believe me this can happen, it would never reload another iAd banner until you close the app. You dont want that as that means less money in your pocket.

I did not do the same for Inter Ads because they have to be preloaded before you can actually show them. Besides that they are not shown regularly so there really is no point.

# Set-Up

- Step 1: Copy the Ads.swift file into your project

- Step 2: Copy the Google framework folder found in the sample project into your projects folder on your computer. Its best to copy it to your projects root folder because if you just reference the file (Step 3)from a random location on your computer it could cause issues. You can also download the latest version from Googles website (https://developers.google.com/admob/ios/download)

- Step 3: Add the Google framework to your project. Go to Targets - BuildPhases - LinkedBinaries and click the + button and than press the "Add Other" button. Search your computer for the folder you copied at Step 2 containing the googleframework file and add that file. Once you done that click the + button again use the search bar at the top and search for googleframework and than add it. Your linkedBinaries should now say 1.

- Step 4: Add the other frameworks needed. Click the + button again and search for and than add each of these frameworks: AdSupport, AudioToolbox, AVFoundation, CoreGraphics, CoreMedia, CoreTelephony, EventKit, EventKitUI, MessageUI, StoreKit, SystemConfiguration (https://developers.google.com/admob/ios/quick-start?hl=en
 ). This should bring your total linked binary (framework) count to 12. You might want to consider putting all the added frameworks you now see in your project sidebar into a folder called Frameworks, similar to the sample project, to keep it clean.

- Step 5: In your AppDelegate.swift underneath ```import UIKit``` write the following
```swift
import iAd
import GoogleMobileAds

let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
```

The last line is needed for shared banner ads, see step 6

- Step 6: Still in your AppDelegate.swift under the class implementation you will need to create these properties

```swift
var bannerAdView = ADBannerView()
var googleBannerAdView = GADBannerView()
```

This is what is called a shared Banner ad, although not really needed for a spritekit game with 1 view controller this is the correct way to use banner ads in apps with multiple ViewControllers. You can read more about shared banner ads on Apples website (https://developer.apple.com/library/ios/technotes/tn2286/_index.html).

- Step 7: In your viewController write the following in ```ViewDidLoad```. Its best to call these as soon as possible.
```swift
Ads.sharedInstance.presentingViewController = self
Ads.preloadFirstSupportedInterAd()
```
The 1st line sets up the presentingViewController var to your Current View Controller, this step is important as your app will crash otherwise when calling an Ad. In a spriteKit game this only really needs to called once since there usually only is 1 viewController.

The 2nd line simply preloads the first InterAd . This also only needs to be called once, interAds will preload automatically afterwards.

NOTE: If your app is not a spriteKit game and uses multiple view controllers than you should ignore Step 7 and check  "not a SpriteKit game?" for a better way.

# How to use

There should be no more errors in your project now and the Helper is ready to be used. You can blame Google for most of the work here. Also keep in mind that the Google banner ads (iAds do it automatically ) are set up for portrait mode, if your app is in landscape than you will need to change
```swift 
var googleBannerType
```
from "kGADAdSizeSmartBannerPortrait" to "kGADAdSizeSmartBannerLandscape"

- iAds are always shown by default unless they are not supported. If you want to manually test google ads comment out the line 
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

- Step 1: If you havent used iAds before make sure your apple account is set up for iAds (https://developer.apple.com/iad/). You mainly have to sign an agreement in your developer account.

- Step 2: Sign up for a Google AdMob account and create your ad IDs. You need 1 for banner and 1 for inter ads. (https://support.google.com/admob/answer/2784575?hl=en-GB)

- Step 3: In Ads.swift in the struct called ID enter your real Ad IDs for both banner and inter Ads.

- Step 4: In
```swift 
func loadGoogleBannerAd()
func preloadGoogleInterAd()
``` 
change the ad ID reference from "ID.bannerTest/ID.interTest" to "ID.bannerLive/ID.interLive" and comment out the line 
```swift 
request.testDevices = [ kGADSimulatorID"
``` 
I wrote some comments at those points to avoid this hassle in the future if you set up a D-DEBUG flag.

- Step 4: When you submit your app on itunes connect do not forget to select yes for "does your app use an advertising identifier", otherise your app will get rejected. This is needed for AdMob, if you decide to only use iAds than make sure you select no, otherwise your app will also get rejected.

# Not a SpriteKit game?
If you have an app that mainly uses viewControllers to show its UI than it might be clunky to call 
```swift 
Ads.sharedInstance.presentingViewController = self
```
especially repeatedly when changing viewControllers. This might even potentially cause issue with shared banner ads, although I have not tested that myself. For those apps you should change these functions
```swift 
  class func loadSupportedBannerAd() {
        ...
    }
    
    func loadSupportedBannerAd() {
        ...
    }
    
  class func preloadFirstSupportedInterAd() {
        ...
    }
    
    func preloadFirstSupportedInterAd() {
        ...
     }
     
     class func showSupportedInterAd() {
        ...
    }
    
    func showSupportedInterAd() {
        ...
    }
```
to
```swift 
  class func loadSupportedBannerAd(viewController: UIViewController) {
        ...
    }
    
    func loadSupportedBannerAd(viewController: UIViewController) {
        ...
    }
    
  class func preloadFirstSupportedInterAd(viewController: UIViewController) {
        ...
    }
    
    func preloadFirstSupportedInterAd(viewController: UIViewController) {
        ...
    }
    
  class func showSupportedInterAd(viewController: UIViewController) {
        ...
    }
    
    func showSupportedInterAd(viewController: UIViewController) {
        ...
    }
```
You than simply preload the first interAd like so (Step 7)
```swift 
Ads.preloadFirstSupportedInterAd(self)
```

and than show Ads like so
```swift
Ads.loadSupportedBannerAd(self)
or
Ads.showSupportedInterAd(self)
```
# Final Info

The sample project is the basic Apple spritekit template. It now shows a banner Ad on launch and an inter ad, if it has loaded, when touching the screen.
To make it easier to call these methods I made class functions in Ads.swift. If you would like to cut down the helper file a bit you can delete all the class functions and call the methods like so
```swift
Ads.sharedInstance.preloadFirstSupportedInterAd()
Ads.sharedInstance.loadSupportedBannerAd()
Ads.sharedInstance.showSupportedInterAd()
```
Like I mentioned above I primarly focused on SpriteKit to make it easy to call Ads from your SKScenes without having to use NSNotificationCenter or delegates to constantly communicate with the viewController. Also this should help keep your viewController clean as mine became a mess after integrating AdMob.

I also made some comments in the relevant spots of the helper file incase you need to pause your game, music etc.

Please let me know about any bugs or improvements, I am by now means an expert. 

Enjoy

# Release Notes
v.1.0



 
