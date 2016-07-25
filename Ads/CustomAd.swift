
//  Created by Dominik on 22/08/2015.

//    The MIT License (MIT)
//
//    Permission is hereby granted, free of charge, to any person obtaining a copy
//    of this software and associated documentation files (the "Software"), to deal
//    in the Software without restriction, including without limitation the rights
//    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//    copies of the Software, and to permit persons to whom the Software is
//    furnished to do so, subject to the following conditions:
//
//    The above copyright notice and this permission notice shall be included in all
//    copies or substantial portions of the Software.
//
//    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//    SOFTWARE.

//    v5.3

/*
    Abstract:
    A Singleton class to manage custom interstitial adverts.
*/

import StoreKit

/// Get app store url for app ID
private func getAppStoreURL(forAppID id: String) -> String {
    #if os(iOS)
        return "itms-apps://itunes.apple.com/app/id" + id
    #endif
    #if os(tvOS)
        return "com.apple.TVAppStore://itunes.apple.com/app/id" + id
    #endif
}

/// Inventory
public enum Inventory: Int {
    
    // Convinience
    case angryFlappies = 0
    case vertigus
    
    /// All ads
    private static let adImagePrefix = "AdImage"
    private static var all = [
        (imageName: adImagePrefix + "AngryFlappies", appID: "991933749"),
        (imageName: adImagePrefix + "Vertigus", appID: "1051292772")
    ]
    
    /// Tracking
    private static var current = 0
}

/// Delegate
public protocol CustomAdDelegate: class {
    func customAdClicked()
    func customAdClosed()
}

/// Custom ads video class
public class CustomAd: NSObject {
    
    // MARK: - Static Properties
    public static let sharedInstance = CustomAd()
    
    // MARK: - Properties
    
    /// Delegate
    public weak var delegate: CustomAdDelegate?
    
    /// Ad creation
    private var view = UIView()
    private var imageView = UIImageView()
    private var closeButton = UIButton()
    
    /// Image and store url
    private var imageName = ""
    private var appID = ""
    
    /// Interval counter
    private var intervalCounter = 0
    
    /// Removed ads
    private var removedAds = false
    
    // MARK: - Init
    
    private override init() {
        super.init()
    }
    
    /// Show
    public func show(selectedAd selectedAd: Inventory? = nil, withInterval interval: Int = 0) {
        guard !removedAds && !Inventory.all.isEmpty else { return }
        
        if interval != 0 {
            intervalCounter += 1
            guard intervalCounter >= interval else { return }
            intervalCounter = 0
        }
        
        var adInInventory: Int
        if let selectedAd = selectedAd {
            adInInventory = selectedAd.rawValue
        } else {
            adInInventory = Inventory.current
        }
        
        let appName = NSBundle.mainBundle().infoDictionary?["CFBundleName"] as? String ?? "NoAppNameFound"
        let appNameNoWhiteSpaces = appName.stringByReplacingOccurrencesOfString(" ", withString: "")
        let appNameNoWhiteSpacesAndDash = appNameNoWhiteSpaces.stringByReplacingOccurrencesOfString("-", withString: "")
        
        if adInInventory >= Inventory.all.count {
            adInInventory = 0
            Inventory.current = 0
        }
        
        if let _ = Inventory.all[adInInventory].imageName.rangeOfString(appNameNoWhiteSpacesAndDash, options: .CaseInsensitiveSearch) {
            adInInventory += 1
            Inventory.current += 1
        }
        
        if adInInventory >= Inventory.all.count {
            adInInventory = 0
            Inventory.current = 0
        }
        
        guard let validAd = createAd(selectedAd: adInInventory) else { return }
        
        validAd.layer.zPosition = 5000
        let rootViewController = UIApplication.sharedApplication().keyWindow?.rootViewController
        rootViewController?.view?.addSubview(validAd)
        
        Inventory.current += 1
    }
    
    /// Remove
    public func remove() {
        removedAds = true
        removeFromSuperview()
    }
    
    /// Orientation changed
    public func adjustForOrientation() {
        setImageForOrientation()
        setButtonsForOrientation()
    }
}

// MARK: - Ad Management

private extension CustomAd {
    
    /// Create ad
    func createAd(selectedAd selectedAd: Int) -> UIView? {
        
        // Set ad properties
        imageName = Inventory.all[selectedAd].imageName
        appID = Inventory.all[selectedAd].appID
        
        // Remove previous ad just incase
        removeFromSuperview()
        
        // Image
        imageView.image = UIImage(named: imageName)
        imageView.userInteractionEnabled = true
        setImageForOrientation()
        view.addSubview(imageView)
        
        #if os(iOS)
            
            // Download tap gesture
            let downloadTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleDownload))
            downloadTapGestureRecognizer.delaysTouchesBegan = true
            imageView.addGestureRecognizer(downloadTapGestureRecognizer)
            
            // Close button
            closeButton.setTitle("X", forState: .Normal)
            closeButton.setTitleColor(UIColor.grayColor(), forState: .Normal)
            closeButton.backgroundColor = UIColor.whiteColor()
            closeButton.layer.borderColor = UIColor.grayColor().CGColor
            closeButton.layer.borderWidth = 2
            let iPad = UIDevice.currentDevice().userInterfaceIdiom == .Pad
            closeButton.layer.cornerRadius = (iPad ? 15 : 11.5)
            closeButton.addTarget(self, action: #selector(handleClose), forControlEvents: .TouchDown)
            setButtonsForOrientation()
            view.addSubview(closeButton)
        #endif
        
        // TV controls
        #if os(tvOS)
            let tapMenu = UITapGestureRecognizer(target: self, action: #selector(handleClose))
            tapMenu.delaysTouchesBegan = true
            tapMenu.allowedPressTypes = [NSNumber (integer: UIPressType.Menu.rawValue)]
            imageView.addGestureRecognizer(tapMenu)
            
            let tapMain = UITapGestureRecognizer(target: self, action: #selector(handleDownload))
            tapMain.delaysTouchesBegan = true
            tapMain.allowedPressTypes = [NSNumber (integer: UIPressType.Select.rawValue)]
            imageView.addGestureRecognizer(tapMain)
        #endif
        
        // Delegate
        delegate?.customAdClicked()
        
        return view
    }
    
    func removeFromSuperview() {
        for gestureRecognizer in imageView.gestureRecognizers ?? [] {
            imageView.removeGestureRecognizer(gestureRecognizer)
        }
        
        closeButton.removeFromSuperview()
        imageView.removeFromSuperview()
        view.removeFromSuperview()
    }
}

// MARK: - Buttons Pressed

extension CustomAd {
    
    @objc private func handleDownload() {
        print("Pressed download button")
        handleClose()
        
        #if os(iOS)
            AppStoreViewController.sharedInstance.open(forAppID: appID)
        #endif
        
        #if os(tvOS)
        if let url = NSURL(string: getAppStoreURL(forAppID: appID)) {
            UIApplication.sharedApplication().openURL(url)
        }
        #endif
    }
    
    @objc private func handleClose() {
        removeFromSuperview()
        delegate?.customAdClosed()
    }
}

/// Set For Orientation
private extension CustomAd {
    
    func setImageForOrientation() {
        guard let rootViewController = UIApplication.sharedApplication().keyWindow?.rootViewController else { return }
        
        view.frame = rootViewController.view.frame
        
        #if os(iOS)
            if UIScreen.mainScreen().bounds.height < UIScreen.mainScreen().bounds.width { // check if in landscape, works at startup
                imageView.frame = CGRect(x: 0, y: 0, width: view.frame.size.width / 1.2, height: view.frame.size.height / 1.1)
            } else {
                let iPad = UIDevice.currentDevice().userInterfaceIdiom == .Pad
                let height = iPad ? view.frame.size.height / 2 : view.frame.size.height / 2.5
                imageView.frame = CGRect(x: 0, y: 0, width: view.frame.size.width / 1.05, height: height)
            }
        #endif
        
        #if os(tvOS)
            imageView.frame = CGRect(x: 0, y: 0, width: view.frame.size.width / 1.2, height: view.frame.size.height / 1.1)
        #endif
        
        imageView.center = rootViewController.view.center
    }
    
    func setButtonsForOrientation() {
        let iPad = UIDevice.currentDevice().userInterfaceIdiom == .Pad
        let closeButtonSize: CGFloat = iPad ? 30 : 22
        closeButton.frame = CGRect(x: 0, y: 0, width: closeButtonSize, height: closeButtonSize)
        closeButton.center = CGPoint(x: CGRectGetMinX(imageView.frame) + (closeButtonSize / 1.5), y: CGRectGetMinY(imageView.frame) + (closeButtonSize / 1.5))
    }
}

// MARK: - App store view controller

public class AppStoreViewController: NSObject {
    
    // MARK: - Static Properties
    
    /// Shared instance
    public static let sharedInstance = AppStoreViewController()
    
    // MARK: - Methods
    
    /// Open app store controller for app ID
    public func open(forAppID appID: String) {
        let storeViewController = SKStoreProductViewController()
        storeViewController.delegate = self
        
        let parameters = [SKStoreProductParameterITunesItemIdentifier: appID]
        storeViewController.loadProductWithParameters(parameters) { (result, error) in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            
            guard result else { return }
            
            let rootViewController = UIApplication.sharedApplication().keyWindow?.rootViewController
            rootViewController?.presentViewController(storeViewController, animated: true, completion: nil)
        }
    }
}

/// SKStoreProductViewControllerDelegate
extension AppStoreViewController: SKStoreProductViewControllerDelegate {
    
    public func productViewControllerDidFinish(viewController: SKStoreProductViewController) {
        viewController.dismissViewControllerAnimated(true, completion: nil)
    }
}