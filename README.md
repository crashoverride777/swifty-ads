# iAds and AdMob Helper

A simple helper class that should make integrating Banner and Interterstitial Ads from Apple and Google a breeze.
I decided to go the Singleton way but please feel free to change it however you feel. This helper has been made while designing my SpriteKit game but it can be used for any kind of app.

The cool thing is that the helper will show iAds when they are supported otherwise it will show AdMob. 
Whats really cool is that incase iAd Banners are having an error it will automatically load a Google Banner Ad. In case the Google Banner ad is having an error it will reload iAd Banners. 
I did not do this for Inter Ads since they will always preload and cannot be shown before.

# Set-Up

- Step 1: Copy the Ads.swift file into your project

- Step 2: Copy the google framework folder found in the sample project into your own project or download the latest version from googles website (https://developers.google.com/admob/ios/download)

- Step 3: Add the Google framework to your project. Go to Targets - BuildPhases - LinkedBinaries and click the + button and than press the "Add Other" button and search your computer for the folder you copied at Step 2 containing the googleframework file. Once you done that search for googleframework and add it, your linkedBinaries should now say 1.

- Step 4: Add the other frameworks needed. Click the + button again and search for and than add each of these frameworks: AdSupport, AudioToolbox, AVFoundation, CoreGraphics, CoreMedia, CoreTelephony, EventKit, EventKitUI, MessageUI, StoreKit, SystemConfiguration (https://developers.google.com/admob/ios/quick-start?hl=en
 ). This should bring your total linked binary (framework) count to 12

- Step 5: In your AppDelegate.swift underneath ```import UIKit``` write the following
```swift
import iAd
```
```swift
import GoogleMobileAds
```
```swift
let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
```

The last line is needed for shared banner ads, see step 6


- Step 6: Still in your AppDelegate.swift under the class implementation you will need to create these properties

```swift
var bannerAdView = ADBannerView()
```
```swift
var googleBannerAdView = GADBannerView()
```

This is what is called a shared Banner ad, although not really needed for a spritekit game with 1 view controller this is the correct way to use banner ads in apps with multiple ViewControllers. You can read more about shared banner ads on Apples website (https://developer.apple.com/library/ios/technotes/tn2286/_index.html).

- Step 7: In your viewController write the following in ```ViewDidLoad```. Its best to call these as soon as possible.
```swift
Ads.sharedInstance.presentingViewController = self
```
```swift
Ads.preloadSupportedInterAd()
```
The 1st line sets up the presentingViewController var to your Current View Controller, this step is important as your app will crash otherwise when calling an Ad.

NOTE: In SpriteKit this normally only needs to be done once as there usually is only 1 viewController, however if your app has multiple view controllers than do not forget to call call this again when changing viewControllers and calling new ads. 

The 2nd line will simply preload the first bunch of InterAds . This also only needs to be called once as interAds will preload automatically after being viewed the first time. Preloading Apples inter Ads is also what most tutorial don’t show you and it makes them appear much faster and more reliable, similar to Googles inter ads.


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
in the super.init() method.

- To show a supported Banner or Inter Ad simply call these anywhere you like in your project.
```swift
Ads.loadSupportedBannerAd()
```
```swift
Ads.showSupportedInterAd()
```
- To remove Banner Ads for example during gamePlay simply call 
```swift
Ads.removeBannerAds()
```
- To remove all Ads, for example for in app purchases simply call
```swift
Ads.removeAllAds()
```
# When you go Live 

Google Ads are a bit of a hassle when testing and when going live.
Google Ads are using test ad IDs and this line of code 
```swift 
request.testDevices = [ kGADSimulatorID ];
```
So when your app goes live you will have to do the following

- Step 1: Make sure your apple account is set up for iAds (https://developer.apple.com/iad/)

- Step 2: Sign up for a Google AdMob account and create your ad IDs (https://support.google.com/admob/answer/2784575?hl=en-GB)

- Step 3: In Ads.swift in the struct called ID enter your real Ad IDs for both banner and inter Ads.

- Step 4: In the functions
```swift 
- func loadGoogleBannerAd()
``` 
and 
```swift 
func showGoogleInterAd()
``` 
change the ad ID reference from "ID.bannerTest/ID.interText" to "ID.bannerLive/ID.interLive" and comment out the line 
```swift 
request.testDevices = [ kGADSimulatorID"
``` 
I wrote some comments at those points to avoid this hassle in the future if you set up D_DEBUG flag.

# Final Info

The sample project is the basic apple spritekit template. It now shows a banner Ad on launch and an inter ad, if it has loaded, when touching the screen.
I also made some comments in relevant spots of the helper file incase your need to pause your game, music etc.

Please let me know about any bugs or improvements, I am by now means an expert. 

Enjoy



 
