NOTE: iAd is shutting down on June the 30th. I have removed all the iAd APIs from this project because iAds can easily be intergrated using AdMob mediation. Mediation is a much better way to handle multiple adProviders mainly due to not having to integrate extra code apart from AdMob APIs.


# AdMob and CustomAds Helpers

A collection of helper classes to integrate Ads from Google as well as your own custom Ads. This helper has been been made while making my 1st SpriteKit game but should work for any kind of app. 

With this helper you can easily show Banner Ads, Interstitial Ads, RewardVideoAds and your own custom Ads anywhere from your projet with 1 line of code.

This Helper creates whats called a shared Banner which is the recommended way by apple to show banners. To read more about shared banner ads you can read this documentation from Apple which should be used for banner ads by all providers.
https://developer.apple.com/library/ios/technotes/tn2286/_index.html

This helper should also correctly preload Interstitial Ads and RewardVideo ads automatically so that they are always ready to be shown instantly when requested.  

# Set up DEBUG flag

This will reduce the hassle of having to manually change the google ad ids when testing or when releasing. This step is important as google ads will otherwise not work automatically. This is a good idea in general for other things such as hiding print statements such as in this project.

Click on Targets (left project sideBar, at the top) -> BuildSettings. Than underneath buildSettings next to the search bar on the left there should be buttons called Basic, All, Combined and Level. 
Click on All and than you should be able to scroll down in buildSettings and find the section called SwiftCompiler-CustomFlags. Click on other flags and than debug and add a custom flag named -D DEBUG 

(see the sample project or http://stackoverflow.com/questions/26913799/ios-swift-xcode-6-remove-println-for-release-version)

# Set up AdMob SDK and frameworks (Cocoal Pods is the recommended way)

https://developers.google.com/admob/ios/quick-start#prerequisites

# Use helper with custom ads

SETUP

- Step1: 

Copy the Ads folder into your project. This should include the files

AdsManager.swift 

AdMob.swift

CustomAds.swift

- Step 2:

In your ViewController write the following in ```ViewDidLoad``` before doing any other app set-ups. 
```swift
AdsManager.sharedInstance.setUp(viewController: self, customAdsCount: 2, customAdsInterval: 5)
```

This sets the viewController property in the helpers to your viewController. In this example there is 2 custom ads in total. The first interAd will be a custom one and than every 4th time an Inter ad is shown it will show another custom one (randomised between the total ads count)

To add more custom adds go to the struct CustomAds in CustomAd.swift and add more properties. Than go to the method 

```swift
func showInterAd() { ....
```

and add more cases to the switch statement to match your total custom Ads you want to show. 

HOW TO USE

- To show an Ad simply call these anywhere you like in your project
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

NOTE:

This method will set a removedAds bool to true in all the ad helpers. This ensures you only have to call this method to remove Ads and afterwards all the methods to show ads will not fire anymore and therefore require no further editing.

For permanent storage you will need to create your own "removedAdsProduct" bool and save it in something like NSUserDefaults, Keychain or a class using NSCoding and than call this method when your app launches.

- Implement the delegate methods

Set the delegate in your GameScenes "didMoveToView" (init) method like so
```swift
AdsManager.sharedInstance.delegate = self 
```

Than create an extension conforming to the protocol.
```swift
extension GameScene: AdsDelegate {
    func adClicked() {
        // pause your game/app
    }
    func adClosed() { 
       // resume your game/app
    }
    func adDidRewardUser(rewardAmount rewardAmount: Int) {
       // code for reward videos, see instructions below
    }
}
```

NOTE: These seem to only get called when in release mode and not when in test mode.


# Use helper without custom ads

SETUP

- Step 1:

Copy AdMob.swift into your project 

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

NOTE:

This method will set a removedAds bool to true in all the ad helpers. This ensures you only have to call this method to remove Ads and afterwards all the methods to show ads will not fire anymore and therefore require no further editing.

For permanent storage you will need to create your own "removedAdsProduct" bool and save it in something like NSUserDefaults, Keychain or a class using NSCoding and than call this method when your app launches.

- Implement the delegate methods

Set the delegate in your GameScenes "didMoveToView" (init) method like so

```swift
AdMob.sharedInstance.delegate = self
```

Than create an extension conforming to the protocol
```swift
extension GameScene: AdMobDelegate {
    func adMobAdClicked() {
        // pause your game/app
    }
    func adMobAdClosed() { 
       // resume your game/app
    }
    func adMobDidRewardUser(rewardAmount rewardAmount: Int) {
       // code for reward videos, see instructions below
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

# Mediation

I think mediation is the best way forward with this helper if you would like to use multiple ad providers. This means you can use the AdMob APIs to show ads from multiple providers without having to write extra code. 
To add mediation networks please follow the instructions 

https://developers.google.com/admob/ios/mediation

to integrate mediation partners such as iAd or Chartboost.

# Reward Videos

Admob reward videos will only work when using a 3rd party mediation network such as Chartboost. To use reward videos follow the steps above to intergrate your mediation network(s) of choice. Than read the AdMob guidlines and your 3rd party ad provider guidliness to set up reward videos correctly. Once everything is set you can show reward videos by calling

```swift
AdsManager.sharedInstance.showRewardVideo()
```

or 

```swift
AdMob.sharedInstance.showRewardVideo()
```

Use this method in the extension you created above to unlock the reward (e.g coins)

```swift
func adDidRewardUser(rewardAmount rewardAmount: Int) {
    self.coins += rewardAmount
}
```

or

```swift
func adMobDidRewardUser(rewardAmount rewardAmount: Int) {
    self.coins += rewardAmount
}
```

Reward amount is an DecimelNumber I converted to an Int for convenience. You can ignore this and hardcore the value if you would like but than you cannot change the value dynamically in your adMob account (if you use adMob for reward settings)


# When you go Live 

- Step 1: Sign up for a Google AdMob account and create your real adUnitIDs depending on the ad types you use (Banner, Inter Reward Ads).

(https://support.google.com/admob/answer/2784575?hl=en-GB)

- Step 2: In AdMob.swift in 
```swift
private enum AdUnitID: String {...
```
enter your real AdUnitIDs.

- Step 3: When you submit your app on iTunes Connect do not forget to select YES for "Does your app use an advertising identifier", otherwise it will get rejected.

NOTE: - Dont forget to setup the "-D DEBUG" custom flag or the helper will not work correctly with adMob.

# Final Info

The sample project is the basic Apple spritekit template. It now shows a banner Ad on launch and an inter ad randomly when touching the screen. After 5 clicks all ads will be removed to simulate what a removeAds button would do. 

Like I mentioned above I primarly focused on SpriteKit to make it easy to call Ads from your SKScenes without having to use NSNotificationCenter or Delegates to constantly communicate with the viewController. Also this should help keep your viewController clean as mine became a mess after integrating AdMob.

Please let me know about any bugs or improvements, I am by no means an expert. 

Enjoy

# Release Notes

- v4.1

Removed IAd.swift as you can get iAds by using AdMob mediation. (if you still need it download v4.0)

Included AdMob reward videos.

Please read the instructions again if you are stuck.

- v4.0

Complete redesign of the helper. The project was getting too big for my liking and since I am planning on adding another Ad provider soon I decided to split the helper into individual files.

This should make code cleaner and better to maintain as well as easier to understand. I also think this way is more flexible because you can decide to just use a single Ad provider without having to edit the whole project. 

Please re-read the instructions again for the new setUp.






 
