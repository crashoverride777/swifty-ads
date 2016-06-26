
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

//    v5.2

/*
    Abstract:
    A Singleton class to manage custom interstitial adverts.
*/

import UIKit

/// Get app store url for app ID
func getAppStoreURL(forAppID id: String) -> String {
    #if os(iOS)
        return "itms-apps://itunes.apple.com/app/id" + id
    #endif
    #if os(tvOS)
        return "com.apple.TVAppStore://itunes.apple.com/app/id" + id
    #endif
}

/// Delegate
protocol CustomAdDelegate: class {
    func customAdClicked()
    func customAdClosed()
}

/// Inventory
struct CustomAdInventory {
    let imageName: String
    let storeURL: String
}

/// Custom ads video class
class CustomAd: NSObject {
    
    // MARK: - Static Properties
    static let sharedInstance = CustomAd()
    
    // MARK: - Properties
    
    /// Delegate
    weak var delegate: CustomAdDelegate?
    
    /// View controller
    private var presentingViewController: UIViewController?
    
    /// Ad creation
    private var view = UIView()
    private var imageView = UIImageView()
    private var closeButton = UIButton()
    
    /// Inventory
    private var inventory = [CustomAdInventory]()
    
    /// Inventory tracking
    private var inventoryCounter = 0 {
        didSet {
            if inventory.count == inventoryCounter {
                inventoryCounter = 0
            }
        }
    }
    
    private var image: String {
        return inventory[inventoryCounter].imageName
    }
    
    private var storeURL: String {
        return inventory[inventoryCounter].storeURL
    }
    
    /// Removed ads
    private var removedAds = false
    
    // MARK: - Init
    
    private override init() {
        super.init()
    }
    
    /// SetUp
    func setUp(viewController viewController: UIViewController, inventory: [CustomAdInventory]) {
        self.presentingViewController = viewController
        self.inventory = inventory
    }
    
    /// Show
    func show() {
        guard !removedAds && !inventory.isEmpty else { return }
        guard let validAd = createAd() else { return }
        validAd.layer.zPosition = 5000
        presentingViewController?.view?.window?.rootViewController?.view?.addSubview(validAd)
        
        inventoryCounter += 1
    }
    
    /// Remove
    func remove() {
        removedAds = true
        removeFromSuperview()
    }
    
    /// Orientation changed
    func  orientationChanged() {
        setImageForOrientation()
        setButtonsForOrientation()
    }
}

// MARK: - Ad Management

private extension CustomAd {
    
    func createAd() -> UIView? {
        
        // Remove previous ad just incase
        removeFromSuperview()
        
        // Image
        imageView.image = UIImage(named: image)
        setImageForOrientation()
        view.addSubview(imageView)
        
        #if os(iOS)
            
            // Download tap gesture
            let downloadTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handelDownload))
            downloadTapGestureRecognizer.delaysTouchesBegan = true
            imageView.userInteractionEnabled = true
            imageView.addGestureRecognizer(downloadTapGestureRecognizer)
            
            // Close button
            closeButton.setTitle("X", forState: .Normal)
            closeButton.setTitleColor(UIColor.grayColor(), forState: .Normal)
            closeButton.backgroundColor = UIColor.whiteColor()
            closeButton.layer.borderColor = UIColor.grayColor().CGColor
            closeButton.layer.borderWidth = 2
            let iPad = UIDevice.currentDevice().userInterfaceIdiom == .Pad
            closeButton.layer.cornerRadius = (iPad ? 15 : 11.5)
            closeButton.addTarget(self, action: #selector(pressedCloseButton), forControlEvents: .TouchDown)
            setButtonsForOrientation()
            view.addSubview(closeButton)
        #endif
        
        // TV controls
        #if os(tvOS)
            let rootViewController = presentingViewController?.view?.window?.rootViewController
            
            let tapMenu = UITapGestureRecognizer()
            tapMenu.addTarget(self, action: #selector(pressedCloseButton))
            tapMenu.allowedPressTypes = [NSNumber (integer: UIPressType.Menu.rawValue)]
            rootViewController?.view.addGestureRecognizer(tapMenu)
            
            let tapMain = UITapGestureRecognizer()
            tapMain.addTarget(self, action: #selector(pressedDownloadButton))
            tapMain.allowedPressTypes = [NSNumber (integer: UIPressType.Select.rawValue)]
            rootViewController?.view.addGestureRecognizer(tapMain)
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
    
    func handelDownload() {
        print("Pressed download button")
        pressedCloseButton()
        if let url = NSURL(string: storeURL) {
            UIApplication.sharedApplication().openURL(url)
        }
    }
    
    func pressedCloseButton() {
        removeFromSuperview()
        delegate?.customAdClosed()
    }
}

// MARK: - Set For Orientation

private extension CustomAd {
    
    func setImageForOrientation() {
        guard let rootViewController = presentingViewController?.view?.window?.rootViewController else { return }
        
        view.frame = rootViewController.view.frame
        
        #if os(iOS)
            if UIDevice.currentDevice().orientation.isLandscape {
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