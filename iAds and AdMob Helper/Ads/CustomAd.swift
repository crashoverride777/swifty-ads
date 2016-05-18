
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

//    v5.0

/*
    Abstract:
    A Singleton class to manage custom interstitial adverts. This class is only included in the iOS version of the project.
*/

import UIKit

/// Settings
private struct Settings {
    
    static var images = [
        "AngryFlappiesAd",
        "AngryFlappiesAd"
    ]
    
    static var titles = [
        "Try our new game!",
        "Try our other game!"
    ]
    
    static var appURLs = [
        "https://itunes.apple.com/gb/app/angry-flappies/id991933749?mt=8",
        "https://itunes.apple.com/gb/app/angry-flappies/id991933749?mt=8"
    ]
    
    static var colors = [
        UIColor.darkGrayColor(),
        UIColor.redColor()
    ]
}

/// Device type
private struct DeviceType {
    static let maxLength = max(UIScreen.mainScreen().bounds.size.width, UIScreen.mainScreen().bounds.size.height)
    
    static let iPhone4     = UIDevice.currentDevice().userInterfaceIdiom == .Phone && maxLength < 568.0
    static let iPhone5     = UIDevice.currentDevice().userInterfaceIdiom == .Phone && maxLength == 568.0
    static let iPhone6     = UIDevice.currentDevice().userInterfaceIdiom == .Phone && maxLength == 667.0
    static let iPhone6Plus = UIDevice.currentDevice().userInterfaceIdiom == .Phone && maxLength == 736.0
    static let iPad      = UIDevice.currentDevice().userInterfaceIdiom == .Pad && maxLength == 1024.0
    static let iPadLarge = UIDevice.currentDevice().userInterfaceIdiom == .Pad && maxLength == 1366.0
    static let iPadAll   = iPad || iPadLarge
}

/// Delegate
protocol CustomAdDelegate: class {
    func customAdClicked()
    func customAdClosed()
}

/// Custom ads class
class CustomAd: NSObject {
    
    // MARK: - Static Properties
    
    static let sharedInstance = CustomAd()
    
    // MARK: - Properties
    
    /// Delegates
    weak var delegate: CustomAdDelegate?
    
    /// Presenting view controller
    private var presentingViewController: UIViewController?
    
    // Creation
    private let view: UIView
    private let headerLabel: UILabel
    private let imageView: UIImageView
    private let downloadButton: UIButton
    private let closeButton: UIButton
    private var URL: NSURL?
    
    // Inventory tracking
    var intervalCounter = 0
    var interval = 0
    
    var isFinishedForSession: Bool {
        return sessionCounter == Settings.images.count * 2 // loop through inventory twice
    }
    
    private var inventoryCounter = 0
    private var sessionCounter = 0
    
    /// Removed ads
    private var removedAds = false
    
    // MARK: - Init
    
    private override init() {
        view = UIView()
        headerLabel = UILabel()
        imageView = UIImageView()
        downloadButton = UIButton()
        closeButton = UIButton()
        
        super.init()
    }
    
    // MARK: - User Methods
    
    /// SetUp
    func setUp(viewController viewController: UIViewController, interval: Int) {
        presentingViewController = viewController
        self.interval = interval
    }
    
    /// Show inter ad randomly
    func showRandomly(randomness randomness: UInt32) {
        guard !removedAds else { return }
        
        guard Int(arc4random_uniform(randomness)) == 0 else { return }
        show()
    }
    
    /// Show inter ad
    func show() {
        guard !removedAds else { return }
        showAd()
    }
    
    /// Remove all ads (IAPs)
    func remove() {
        removedAds = true
        view.removeFromSuperview()
    }
    
    /// Orientation changed
    func orientationChanged() {
        guard let presentingViewController = presentingViewController else { return }
        setUpView(viewController: presentingViewController)
        setUpViewContentForDeviceOrientation()
    }
}

// MARK: - Custom Ad Creation
private extension CustomAd {
    
    /// Show custom ad
    func showAd() {
        guard !Settings.images.isEmpty else { return }
        guard Settings.titles.count == Settings.images.count else { return }
        guard Settings.appURLs.count == Settings.images.count else { return }
        guard Settings.colors.count == Settings.images.count else { return }
        
        guard let appURL = NSURL(string: Settings.appURLs[inventoryCounter]) else { return }
        guard let customAd = createCustomAd(headerColor: Settings.colors[inventoryCounter], headerText: Settings.titles[inventoryCounter], imageName: Settings.images[inventoryCounter], appURL: appURL) else { return }
        presentingViewController?.view?.window?.rootViewController?.view.addSubview(customAd)
        
        inventoryCounter += 1
        sessionCounter += 1
        if inventoryCounter == Settings.images.count && !isFinishedForSession {
            inventoryCounter = 0
            intervalCounter = 0 - interval
        }
    }
    
    /// Create custom ad
    func createCustomAd(headerColor headerColor: UIColor, headerText: String, imageName: String, appURL: NSURL?) -> UIView? {
        guard let presentingViewController = presentingViewController else { return nil }
        
        // App URL
        URL = appURL
        
        // View
        setUpView(viewController: presentingViewController)
        view.backgroundColor = UIColor.clearColor()
        
        // Image
        imageView.image = UIImage(named: imageName)
        imageView.center = CGPoint(x: 0 + (imageView.frame.size.width / 2), y: 0 + (imageView.frame.size.height / 2))
        view.addSubview(imageView)
        
        // Header label
        headerLabel.text = headerText
        let font = "Damascus"
        let fontSize: CGFloat
        if DeviceType.iPadLarge {
            fontSize = 22 * 2.3
        } else if DeviceType.iPad {
            fontSize = 22 * 1.7
        } else {
            fontSize = 22
        }
        
        headerLabel.font = UIFont(name: font, size: fontSize)
        headerLabel.textAlignment = NSTextAlignment.Center
        headerLabel.textColor = headerColor
        imageView.addSubview(headerLabel)
        
        // Download button
        downloadButton.backgroundColor = UIColor.clearColor()
        downloadButton.addTarget(self, action: #selector(pressedDownloadButton), forControlEvents: .TouchDown)
        view.addSubview(downloadButton)
        
        // Close button
        if DeviceType.iPadLarge {
            closeButton.frame = CGRect(x: 28, y: 28, width: 37, height: 37)
            closeButton.layer.cornerRadius = 18
        } else if DeviceType.iPad {
            closeButton.frame = CGRect(x: 19, y: 19, width: 28, height: 28)
            closeButton.layer.cornerRadius = 14
        } else {
            closeButton.frame = CGRect(x: 12, y: 12, width: 21, height: 21)
            closeButton.layer.cornerRadius = 11
        }
        
        closeButton.setTitle("X", forState: .Normal)
        closeButton.setTitleColor(UIColor.grayColor(), forState: .Normal)
        closeButton.backgroundColor = UIColor.whiteColor()
        closeButton.layer.borderColor = UIColor.grayColor().CGColor
        closeButton.layer.borderWidth = 2
        closeButton.addTarget(self, action: #selector(pressedCloseButton), forControlEvents: .TouchDown)
        view.addSubview(closeButton)
        
        // Setup for correct orientation
        setUpViewContentForDeviceOrientation()
        
        // Return custom ad view
        return view
    }
    
    /// Set up view
    func setUpView(viewController viewController: UIViewController) {
        
        if UIDevice.currentDevice().orientation.isLandscape {
            if DeviceType.iPadAll {
                view.frame = CGRect(x: 0, y: 0, width: viewController.view.frame.width / 1.3, height: viewController.view.frame.height / 1.4)
            } else {
                view.frame = CGRect(x: 0, y: 0, width: viewController.view.frame.width / 1.3, height: viewController.view.frame.height / 1.2)
            }
        }
        else {
            if DeviceType.iPadAll {
                view.frame = CGRect(x: 0, y: 0, width: viewController.view.frame.width / 1.05, height: viewController.view.frame.height)
            } else {
                view.frame = CGRect(x: 0, y: 0, width: viewController.view.frame.width / 1.05, height: viewController.view.frame.height)
            }
        }
        
        view.center = viewController.view.center
    }
    
    /// Set up view content for device orientation
    func setUpViewContentForDeviceOrientation() {
        
        imageView.frame = CGRect(x: 0, y: 0, width: view.frame.size.width, height: view.frame.size.height)
        headerLabel.frame = CGRect(x: 0, y: 0, width: imageView.frame.size.width, height: imageView.frame.size.height)
        
        // Landscape
        if UIDevice.currentDevice().orientation.isLandscape {
            imageView.contentMode = .ScaleToFill
            headerLabel.center.x = CGRectGetMidX(imageView.frame)
            
            if DeviceType.iPhone4 || DeviceType.iPhone5 {
                headerLabel.center.y = 0 + 30
            }
            else if DeviceType.iPad {
                headerLabel.center.y = 0 + 60
            }
            else if DeviceType.iPadLarge {
                headerLabel.center.y = 0 + 80
            }
            else {
                headerLabel.center.y = 0 + 35
            }
            
            closeButton.center = CGPoint(x: CGRectGetMinX(imageView.frame) + (closeButton.frame.size.width * 1.5), y: headerLabel.center.y / 1.15)
            downloadButton.frame = CGRect(x: 0, y: 0, width: imageView.frame.size.width, height: imageView.frame.size.height)
        }
            
            /// Portrait
        else {
            imageView.contentMode = .ScaleAspectFit
            headerLabel.center.x = CGRectGetMidX(imageView.frame)
            
            if DeviceType.iPhone4 || DeviceType.iPhone5 {
                headerLabel.center.y = CGRectGetMidY(imageView.frame) - 80
            }
            else if DeviceType.iPhone6 {
                headerLabel.center.y = CGRectGetMidY(imageView.frame) - 95
            }
            else if DeviceType.iPhone6Plus {
                headerLabel.center.y = CGRectGetMidY(imageView.frame) - 110
            }
            else if DeviceType.iPad {
                headerLabel.center.y = CGRectGetMidY(imageView.frame) - 200
            }
            else if DeviceType.iPadLarge {
                headerLabel.center.y = CGRectGetMidY(imageView.frame) - 270
            }
            
            closeButton.center = CGPoint(x: CGRectGetMinX(imageView.frame) + (closeButton.frame.size.width * 1.3), y: headerLabel.center.y / 1.03)
            downloadButton.frame = CGRect(x: 0, y: 0, width: imageView.frame.size.width, height: imageView.frame.size.height / 3)
        }
        
        downloadButton.center = CGPoint(x: CGRectGetMidX(imageView.frame), y: CGRectGetMidY(imageView.frame))
    }
}

// MARK: - Buttons Pressed
extension CustomAd {
    
    func pressedDownloadButton() {
        guard let url = URL else { return }
        UIApplication.sharedApplication().openURL(url)
        delegate?.customAdClicked()
    }
    
    func pressedCloseButton() {
        view.removeFromSuperview()
        delegate?.customAdClosed()
    }
}