
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

/// Device type
private struct Device {
    static let iPad = UIDevice.currentDevice().userInterfaceIdiom == .Pad
}

/// Delegate
protocol CustomAdDelegate: class {
    func customAdClicked()
    func customAdClosed()
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
    private let view = UIView()
    private let imageView = UIImageView()
    private var closeButton = UIButton()
    private var downloadButton = UIButton()
    
    /// Inventory
    private var inventory = [(image: String, storeURL: String)]()
    
    /// Inventory tracking
    private var inventoryCounter = 0 {
        didSet {
            guard inventory.count < inventoryCounter else { return }
            inventoryCounter = 0
        }
    }
    
    private var image: String {
        return inventory.count > inventoryCounter ? inventory[inventoryCounter].image : ""
    }
    
    private var storeURL: String {
        return inventory.count > inventoryCounter ? inventory[inventoryCounter].storeURL : ""
    }
    
    /// Removed ads
    private var removedAds = false
    
    // MARK: - Init
    
    private override init() {
        super.init()
    }
    
    /// SetUp
    func setUp(viewController viewController: UIViewController, inventory: [(image: String, storeURL: String)]) {
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
        
        // Buttons
        #if os(iOS)
            downloadButton.backgroundColor = UIColor.clearColor()
            downloadButton.addTarget(self, action: #selector(pressedDownloadButton), forControlEvents: .TouchDown)
            
            closeButton.setTitle("X", forState: .Normal)
            closeButton.setTitleColor(UIColor.grayColor(), forState: .Normal)
            closeButton.backgroundColor = UIColor.whiteColor()
            closeButton.layer.borderColor = UIColor.grayColor().CGColor
            closeButton.layer.borderWidth = 2
            closeButton.layer.cornerRadius = (Device.iPad ? 15 : 11.5)
            closeButton.addTarget(self, action: #selector(pressedCloseButton), forControlEvents: .TouchDown)
            
            setButtonsForOrientation()
            view.addSubview(downloadButton)
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
        closeButton.removeFromSuperview()
        downloadButton.removeFromSuperview()
        imageView.removeFromSuperview()
        view.removeFromSuperview()
    }
}

// MARK: - Buttons Pressed

extension CustomAd {
    
    func pressedDownloadButton() {
        guard let url = NSURL(string: storeURL) else { return }
        UIApplication.sharedApplication().openURL(url)
        pressedCloseButton()
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
                let height = Device.iPad ? view.frame.size.height / 2 : view.frame.size.height / 2.5
                imageView.frame = CGRect(x: 0, y: 0, width: view.frame.size.width / 1.05, height: height)
            }
        #endif
        
        #if os(tvOS)
            imageView.frame = CGRect(x: 0, y: 0, width: view.frame.size.width / 1.2, height: view.frame.size.height / 1.1)
        #endif
        
        imageView.center = rootViewController.view.center
    }
    
    func setButtonsForOrientation() {
        downloadButton.frame = CGRect(x: 0, y: 0, width: imageView.frame.size.width, height: imageView.frame.size.height)
        downloadButton.center = CGPoint(x: CGRectGetMidX(imageView.frame), y: CGRectGetMidY(imageView.frame))
        
        let closeButtonSize: CGFloat = Device.iPad ? 30 : 22
        closeButton.frame = CGRect(x: 0, y: 0, width: closeButtonSize, height: closeButtonSize)
        closeButton.center = CGPoint(x: CGRectGetMinX(imageView.frame) + (closeButtonSize / 1.5), y: CGRectGetMinY(imageView.frame) + (closeButtonSize / 1.5))
    }
}