# iAds and AdMob Helper

A simple helper class that should make integrating Banner and Interterstitial Ads from Apple and Google a breeze.
I decided to go the Singleton way but please feel free to change it however you feel. This helper has been designed for spritekit but can be used for any kind of app.

The cool thing is that the helper will show iAds when they are supported otherwise AdMob will be shown. 
Whats really cool is that incase iAd Banners are having an error it will automatically load a Google Banner Ad. In case the Google Banner ad is having an error it will reload iAd Banners. 
I did not do this for Inter Ads since they are not regulary show and because they will always preload before being shown, and if there is an error preloading they will just try again. 

# Set-Up

- Step 1: Sign up for a Google AdMob account and create your ad IDs (https://support.google.com/admob/answer/2784575?hl=en-GB)

- Step 1: Copy the Ads.swift file into your project

- Step 2: Copy the google Frame work folder found in the sample project into your own project or download the latest version from googles website (https://developers.google.com/admob/ios/download)

- Step 3: In your project you will need to add multiple frameworks for AdMob to work. So  lets go through them as listed by Google (https://developers.google.com/admob/ios/quick-start?hl=en
 ). Go to Targets - BuildPhases - LinkBinaries and click the + button and search for and than add each of these frameworks: AdSupport, AudioToolbox, AVFoundation, CoreGraphics, CoreMedia, CoreTelephony, EventKit, EventKitUI, MessageUI, StoreKit, SystemConfiguration

- Step 4: Add the Google framework itself. 
 Click the + button again and than press the "Add Other" button and search your project for the folder you copied at Step 2 containing the googleframework file. Once you added that file search for it as you did in step 3 and add it. This should bring your total linked binary (framework) count to 12

- Step 6: In your AppDelegate.swift underneath ```import UIKit``` write the following
```
import iAd
```
```
import GoogleMobileAds
```
```
let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
Ads.sharedInstance.presentingViewController = self
```

The last line is needed for shared banner ads, see step 7



- Step 7: Still in your AppDelegate.swift you will need to create these properties

```
var bannerAdView = ADBannerView()
```
```
var googleBannerAdView = GADBannerView()
```

// This is what is called a shared Banner ad, although not really needed for a spritekit game with 1 view controller this is the correct way to use banner ads in apps with multiple ViewControllers. You can read more about shared banner ads on apples website (https://developer.apple.com/library/ios/technotes/tn2286/_index.html).

- Step 8: In your first viewController write the following in ```ViewDidLoad```. Its best to call these as soon as possible.
```
Ads.sharedInstance.presentingViewController = self
```
```
Ads.iAdsCheckSupport()
```
```
Ads.preloadInterAds()
```
The first line here sets up the presentingViewController var to your Current View Controller, this step is important as your app will crash otherwise when calling an Ad.

NOTE: In SpriteKit this normally only needs to be done once as there usually is only 1 viewController, however if your app has multiple view controllers than do not forget to call call this again when changing viewControllers and calling new ads. 

The second line checks if iAds are supported in the current location. This only needs to be called once

The third line will simply preload the first bunch of InterAds . This also only needs to be called once as interAds will preload automatically after being viewed the first time. Preloading apples inter Ads is what most tutorial don’t show you and it makes them appear much faster and more reliable, similar to googles way.


# How to use

There should be no more errors in your project now and the Helper is ready to be used. You can blame Google for most of the work here. Also bear in mind that the Google banner ads are set up for landscape, if your app is in portrait than you will need to go the the var called googleBannerType and change it from "kGADAdSizeSmartBannerLandscape" to "kGADAdSizeSmartBannerPortrait"

- To show a supported Banner or Inter Ad simply call these anywhere you like. iAds are always shown by default unless they are not supported.
```
Ads.loadSupportedBannerAd()
```
```
Ads.showSupportedInterAd()
```
- To remove Banner Ads for example during gamePlay simply call 
```
Ads.removeBannerAds()
```
- To remove all Ads, for example for in app purchases simply call
```
Ads.removeAllAds()
```
# When you go Live 
Google Ads are a bit of a hassle when testing and when going live.
Google Ads are using test ad IDs and this line of code ```request.testDevices = [ kGADSimulatorID ];```.
So when your app gooes live you will have to do the following

- 1: In Ads.swift right at the top in the struct called ID enter your real Ad IDs for both banner and inter Ads.
- 2: In the function ```loadGoolgeBannerAd()``` and ```showGoogleInterAd()``` change the ad ID reference from "ID.bannerTest/ID.interText" to "ID.bannerLive/ID.interLive" and comment out the line ```request.testDevices = [ kGADSimulatorID"```. I wrote some comments at those points to avoid this hassle in the future by setting a D_DEBUG flag.


# Final Info
The sample project shows a banner ads on launch and an inter ad when pressing a button. 
I also made some comments in relevant spots of the helper file incase your need to pause your game, music etc.
Please feel free to go through this code and let me know about any bugs or improvements, I am by now means an expert. 

Enjoy



 
