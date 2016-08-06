
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

//    v5.4

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

/// Custom ad
private struct Ad {
    let imageName: String
    let appID: String
    let isNewGame: Bool
}

/// Inventory
public enum Inventory: Int {
    
    // Convinience
    case random = -1
    case angryFlappies
    case vertigus
    
    /// All ads
    private static let adImagePrefix = "AdImage"
    private static var all = [
        Ad(imageName: adImagePrefix + "AngryFlappies", appID: "991933749", isNewGame: false),
        Ad(imageName: adImagePrefix + "Vertigus", appID: "1051292772", isNewGame: true)
    ]
    
    /// Tracking
    private static var current = 0
}

/// Custom ads video class
public class CustomAd {
    
    // MARK: - Static Properties
    public static let sharedInstance = CustomAd()
    
    // MARK: - Properties
    
    /// Delegate
    public weak var delegate: AdsDelegate?
    
    /// View
    private let view = UIView()

    /// Image view
    private lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.userInteractionEnabled = true
        return view
    }()
    
    /// Font style
    private let font = "HelveticaNeue"
    private let fontBold = "HelveticaNeue-Bold"
    
    /// Header label
    private lazy var headerLabel: UILabel = {
        let label = UILabel()
        label.text = "Override Interactive"
        label.textAlignment = .Center
        label.textColor = UIColor.blackColor()
        return label
    }()
    
    /// New game label
    private lazy var newGameLabel: UILabel = {
        let label = UILabel()
        label.text = "New"
        label.textAlignment = .Center
        label.textColor = UIColor.redColor()
        label.transform = CGAffineTransformMakeRotation(CGFloat(M_PI_4))
        return label
    }()
    
    /// Close button
    private lazy var closeButton: UIButton = {
        let button = UIButton()
        button.setTitle("X", forState: .Normal)
        button.setTitleColor(UIColor.grayColor(), forState: .Normal)
        button.backgroundColor = UIColor.whiteColor()
        button.layer.borderColor = UIColor.grayColor().CGColor
        button.layer.borderWidth = 2
        let iPad = UIDevice.currentDevice().userInterfaceIdiom == .Pad
        button.layer.cornerRadius = (iPad ? 15 : 11.5)
        button.addTarget(self, action: #selector(handleClose), forControlEvents: .TouchDown)
        return button
    }()
    
    /// Image and store url
    private var imageName = ""
    private var appID = ""
    private var isNewGame = false
    
    /// Interval counter
    private var intervalCounter = 0
    
    /// Removed ads
    private var removedAds = false
    
    // MARK: - Init
    
    private init() { }
    
    /// Show custom ad
    ///
    /// - parameter selectedAd: Show ad for inventory identifier, if set to nil will loop through inventory.
    /// - parameter withInterval: The interval when to show the ad, e.g when set to 4 ad will be shown every 4th time. Defaults to 0.
    public func show(selectedAd selectedAd: Inventory? = nil, withInterval interval: Int = 0) {
        guard !removedAds && !Inventory.all.isEmpty else { return }
        
        if interval != 0 {
            intervalCounter += 1
            guard intervalCounter >= interval else { return }
            intervalCounter = 0
        }
        
        var adInInventory: Int
        if let selectedAd = selectedAd {
            if selectedAd == .random {
                let range = UInt32(Inventory.all.count)
                adInInventory = Int(arc4random_uniform(range))
            } else {
                adInInventory = selectedAd.rawValue
            }
        } else {
            adInInventory = Inventory.current
        }
        
        if adInInventory >= Inventory.all.count {
            adInInventory = 0
            Inventory.current = 0
        }
        
        let appName = NSBundle.mainBundle().infoDictionary?["CFBundleName"] as? String ?? "NoAppNameFound"
        let appNameNoWhiteSpaces = appName.stringByReplacingOccurrencesOfString(" ", withString: "")
        let appNameNoWhiteSpacesAndDash = appNameNoWhiteSpaces.stringByReplacingOccurrencesOfString("-", withString: "")
        
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
        setupForOrientation()
    }
}

// MARK: - Ad Management

private extension CustomAd {
    
    /// Create ad
    ///
    /// - parameter selectedAd: The int for the selected ad in the inventory.
    /// - returns: Optional UIView.
    func createAd(selectedAd selectedAd: Int) -> UIView? {
        
        // Set ad properties
        imageName = Inventory.all[selectedAd].imageName
        appID = Inventory.all[selectedAd].appID
        isNewGame = Inventory.all[selectedAd].isNewGame
        
        // Remove previous ad just incase
        removeFromSuperview()
        
        // Image
        imageView.image = UIImage(named: imageName)
        view.addSubview(imageView)
        
        // Labels
        view.addSubview(headerLabel)
        newGameLabel.hidden = !isNewGame
        view.addSubview(newGameLabel)
        
        // Button
        #if os(iOS)
            // Download tap gesture
            let downloadTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleDownload))
            downloadTapGestureRecognizer.delaysTouchesBegan = true
            imageView.addGestureRecognizer(downloadTapGestureRecognizer)

            view.addSubview(closeButton)
        #endif
        
        // TV controls
        #if os(tvOS)
            let rootViewController = UIApplication.sharedApplication().keyWindow?.rootViewController
            
            let tapMenu = UITapGestureRecognizer(target: self, action: #selector(handleClose))
            tapMenu.delaysTouchesBegan = true
            tapMenu.allowedPressTypes = [NSNumber (integer: UIPressType.Menu.rawValue)]
            rootViewController?.view.addGestureRecognizer(tapMenu)
            
            let tapMain = UITapGestureRecognizer(target: self, action: #selector(handleDownload))
            tapMain.delaysTouchesBegan = true
            tapMain.allowedPressTypes = [NSNumber (integer: UIPressType.Select.rawValue)]
            rootViewController?.view.addGestureRecognizer(tapMain)
        #endif
        
        // Set up for orientation
        setupForOrientation()
        
        // Delegate
        delegate?.adClicked()
        
        return view
    }
    
    /// Remove custom ad
    func removeFromSuperview() {
        for gestureRecognizer in imageView.gestureRecognizers ?? [] {
            imageView.removeGestureRecognizer(gestureRecognizer)
        }
        
        closeButton.removeFromSuperview()
        imageView.removeFromSuperview()
        view.removeFromSuperview()
    }
}

// MARK: - Set up for orientation

private extension CustomAd {
    
    /// Setup for orientation
    func setupForOrientation() {
        guard let rootViewController = UIApplication.sharedApplication().keyWindow?.rootViewController else { return }
        
        /// View
        view.frame = rootViewController.view.frame
        
        /// Image view
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
        
        /// Labels
        let headerFontSize = imageView.frame.size.height / 13
        headerLabel.font = UIFont(name: font, size: headerFontSize)
        headerLabel.frame = CGRect(x: 0, y: 0, width: view.frame.size.width, height: view.frame.size.height)
        headerLabel.center = CGPoint(x: 0 + (view.frame.size.width / 2), y: CGRectGetMinY(imageView.frame) + headerFontSize / 1.1)
        
        newGameLabel.font = UIFont(name: fontBold, size: self.imageView.frame.size.height / 17)
        newGameLabel.frame = CGRect(x: 0, y: 0, width: view.frame.size.width, height: view.frame.size.height)
        newGameLabel.center = CGPoint(x: CGRectGetMaxX(imageView.frame) - (headerFontSize / 1.1), y: CGRectGetMinY(imageView.frame) + headerFontSize / 1.05)
        
        /// Buttons
        let iPad = UIDevice.currentDevice().userInterfaceIdiom == .Pad
        let closeButtonSize: CGFloat = iPad ? 30 : 22
        closeButton.frame = CGRect(x: 0, y: 0, width: closeButtonSize, height: closeButtonSize)
        closeButton.center = CGPoint(x: CGRectGetMinX(imageView.frame) + (closeButtonSize / 1.5), y: CGRectGetMinY(imageView.frame) + (closeButtonSize / 1.5))
    }
}

// MARK: - Buttons Pressed

extension CustomAd {
    
    /// Handle download
    @objc private func handleDownload() {
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
    
    /// Handle close
    @objc private func handleClose() {
        removeFromSuperview()
        delegate?.adClosed()
    }
}

// MARK: - SKStoreProductViewController

#if os(iOS)
class AppStoreViewController: NSObject {
    
    // MARK: - Static Properties
    
    /// Shared instance
    private static let sharedInstance = AppStoreViewController()
    
    // MARK: - Methods
    
    /// Open app store controller for app ID
    private func open(forAppID appID: String) {
        let storeViewController = SKStoreProductViewController()
        storeViewController.delegate = self
        
        let parameters = [SKStoreProductParameterITunesItemIdentifier: appID]
        storeViewController.loadProductWithParameters(parameters) { (result, error) in
            if let error = error {
                print(error.localizedDescription)
                return
            }
        }
        
        /// Present, call outside loadProductsWithParemeter so there is no delay. VC has own loading indicator
        let rootViewController = UIApplication.sharedApplication().keyWindow?.rootViewController
        rootViewController?.presentViewController(storeViewController, animated: true, completion: nil)
    }
}

/// SKStoreProductViewControllerDelegate
extension AppStoreViewController: SKStoreProductViewControllerDelegate {
    
    func productViewControllerDidFinish(viewController: SKStoreProductViewController) {
        viewController.dismissViewControllerAnimated(true, completion: nil)
    }
}
#endif