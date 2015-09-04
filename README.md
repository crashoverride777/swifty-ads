# iAds-and-AdMob-helper

A simple helper class that should make integrating Banner and Interterstitial Ads from Apple and Google a breeze.
I decided to go the singleton way but please feel free to change it however you feel.
This helper has been designed for spritekit but can be used for any kind of app.

The idea is that the helper will show iAds when they are supported otherwise AdMob ads will be shown. 
Whats nice is that incase iAd Banners are having an error it will automatically load a Google Banner Ad. In case the Google Banner ad is having an error, and iAds are supported, than it will reload iAd Banners.


SetUp

- Step 1: Copy the AdsHelper.swift file into your project

- Step 2: Copy the google Frame work folder found in the sample project into your project or download the latest version from googles website.

Step 3: In your project you will need to add multiple frameworks for adMob to work and the errors to go away. So lets go through them as listed by google (https://developers.google.com/admob/ios/quick-start?hl=en
 )

Go to targets-BuildPhases-LinkBinaries and click the + button to and search for and add each of these frameworks.

- AdSupport
- AudioToolbox
- AVFoundation
- CoreGraphics
- CoreMedia
- CoreTelephony
- EventKit
- EventKitUI
- MessageUI
- StoreKit
- SystemConfiguration

- Step 4: Ad the google framework itself. 
 Click the + button again and than press the add other button and search your project for the folder you copied at step 2 containing the googleframeworks file. Once you added that file search for it as you did in step 3 and add it. This should bring your total linked binary (framework) count to 12

Step 5: In your app delegate underneath import UIKit write the following

import iAd
import GoogleMobileAds

let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate

// The last line is needed for step 6

- Step 6: Still in your app delegate you will need to create these properties

var bannerAdView = ADBannerView()
var googleBannerAdView = GADBannerView()

// This is what is called a shared Banner ad, although not really needed for a spritekit game with 1 view controller this is the correct way to use banner ads in apps with multiple ViewControllers. You can read more about shared banner ads on apples website.

- Step 7: In your gameViewController (spritekit) or viewController (normal app) write the following in ViewDidLoad

Ads.sharedInstance.presentingViewController = self
Ads.iAdsCheckSupport()
Ads.preloadInterAds()

The first line here sets up the presentingViewController property to your Current View Controller, this step is important as your app will crash otherwise when calling an ad.

NOTE: In SpriteKit this normally only needs to be done once as there usually is only 1 viewController, however if your app has multiple view controllers than do not forget to call call this again when changing viewControllers and calling new ads.

The second line checks if iAds are supported in the current location.

The third line will simply preload the InterAds . This only needs to be called once as interAds will preload automatically after being viewed the first time. Preloading inter Ads is what most tutorial don’t show you and it makes them appear much faster and more reliable.



- Thats it for set-Up and there should be no more errors in your project. The Helper is now ready to be used, you can blame google for most of the work here.

To show a supported banner or Inter Ad depending on location simply call this anywhere you like. iAds are shown be default unless they are not supported.

Ads.loadSupportedBannerAd()
Ads.showSupportedInterAd()

To remove Banner Ads for example during gamePlay simply call 

Ads.removeBannerAds()

To remove all Ads, for example for in app purchases simply call

Ads.removeAllAds()



- The google banner ads are set up for landscape, if your app is in portrait than you will need to go the AdsHelper.swift and find the function loadGoogleBanner ad and change this kGADAdSizeSmartBannerLandscape to this kGADAdSizeSmartBannerPortrait

The sample project shows a banner ad on launch and a inter ad when pressing a button. Please feel free to go through this code and let me know about any bugs or improvements, I am by now means an expert
.I am using this code on one of my current projects and though it would be nice to put all the code into a helper file for easier use in the future and share it with you guys.

Enjoy



 
