
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

//    v4.0

/*
    Abstract:
    A Singleton class to manage custom interstitial adverts. This class is only included in the iOS version of the project.
*/

import UIKit

/// Custom ad settings
private struct CustomAds {
    struct Ad1 {
        static let backgroundColor = UIColor(red:0.08, green:0.62, blue:0.85, alpha:1.0)
        static let headerColor = UIColor.whiteColor()
        static let image = "CustomAd"
        static let headerText = "Played Angry Flappies yet?"
        static let appURL = NSURL(string: "https://itunes.apple.com/gb/app/angry-flappies/id991933749?mt=8")
    }
    
    struct Ad2 {
        static let backgroundColor = UIColor.orangeColor()
        static let headerColor = UIColor.blackColor()
        static let image = "CustomAd"
        static let headerText = "Played Angry Flappies yet?"
        static let appURL = NSURL(string: "https://itunes.apple.com/gb/app/angry-flappies/id991933749?mt=8")
    }
}

/// Device check
private struct DeviceCheck {
    static let iPad      = UIDevice.currentDevice().userInterfaceIdiom == .Pad && maxLength == 1024.0
    static let iPadPro   = UIDevice.currentDevice().userInterfaceIdiom == .Pad && maxLength == 1366.0
    
    static let width     = UIScreen.mainScreen().bounds.size.width
    static let height    = UIScreen.mainScreen().bounds.size.height
    static let maxLength = max(width, height)
    static let minLength = min(width, height)
}

/// Hide print statements for release
private struct Debug {
    static func print(object: Any) {
        #if DEBUG
            Swift.print("DEBUG", object) //, terminator: "")
        #endif
    }
}

/// Delegate
protocol CustomAdDelegate: class {
    func customAdPause()
    func customAdResume()
}

/// Custom ads class
class CustomAd: NSObject {
    
    // MARK: - Static Properties
    static let sharedInstance = CustomAd()
    
    // MARK: - Properties
    
    /// Properties
    var totalCount = 0
    
    /// Delegates
    weak var delegate: CustomAdDelegate?
    
    /// Presenting view controller
    private var presentingViewController: UIViewController?
    
    /// Removed ads
    private var removedAds = false
    
    // Ads
    private var view = UIView()
    private var headerLabel: UILabel?
    private var image: UIImageView?
    private var URL: NSURL?
    
    /// Inter ads close button
    private var interAdCloseButton = UIButton(type: .System)
    
    // MARK: - Init
    private override init() {
        super.init()
    }
    
    /// SetUp
    func setUp(viewController viewController: UIViewController) {
        presentingViewController = viewController
    }
    
    /// Show inter ads
    func showInterRandomly(randomness randomness: UInt32) {
        guard !removedAds else { return }
        
        let randomInterAd = Int(arc4random_uniform(randomness)) // get a random number between 0 and 2, so 33%
        guard randomInterAd == 0 else { return }
        showInterAd()
    }
    
    func showInter() {
        guard !removedAds else { return }
        showInterAd()
    }
    
    /// Remove all ads (IAPs)
    func removeAll() {
        Debug.print("Removed all ads")
        
        removedAds = true
        view.removeFromSuperview()
    }
    
    /// Orientation changed
    func orientationChanged() {
        guard let presentingViewController = presentingViewController else { return }
        Debug.print("Adjusting ads for new device orientation")
        
        // Custom ad
        view.frame = CGRect(x: 0, y: 0, width: presentingViewController.view.frame.width, height: presentingViewController.view.frame.height)
        headerLabel?.frame = CGRect(x: 0, y: 0, width: presentingViewController.view.frame.width, height: presentingViewController.view.frame.height)
        headerLabel?.center = CGPoint(x: view.frame.width / 2, y: CGRectGetMinY(view.frame) + 80)
        image?.frame = CGRect(x: 0, y: 0, width: presentingViewController.view.frame.width / 1.1, height: presentingViewController.view.frame.height / 2)
        image?.contentMode = UIViewContentMode.ScaleAspectFit
        image?.center.x = view.center.x
        image?.center.y = view.center.y + 20
    }
}

// MARK: - Custom Ads
extension CustomAd {
    
    /// Show custom ad
    private func showInterAd() {
        let randomCustomInterAd = Int(arc4random_uniform(UInt32(totalCount)))
        
        switch randomCustomInterAd {
            
        case 0:
            if let customAd1 = createCustomAd(CustomAds.Ad1.backgroundColor, headerColor: CustomAds.Ad1.headerColor, headerText: CustomAds.Ad1.headerText, imageName: CustomAds.Ad1.image, appURL: CustomAds.Ad1.appURL) {
                presentingViewController?.view?.window?.rootViewController?.view.addSubview(customAd1)
            }
        case 1:
            if let customAd2 = createCustomAd(CustomAds.Ad2.backgroundColor, headerColor: CustomAds.Ad2.headerColor, headerText: CustomAds.Ad2.headerText, imageName: CustomAds.Ad2.image, appURL: CustomAds.Ad2.appURL) {
                presentingViewController?.view?.window?.rootViewController?.view.addSubview(customAd2)
            }
        default:
            break
        }
    }
    
    /// Create custom ad
    private func createCustomAd(backgroundColor: UIColor, headerColor: UIColor, headerText: String, imageName: String, appURL: NSURL?) -> UIView? {
        guard let presentingViewController = presentingViewController else { return nil }
        
        // App URL
        URL = appURL
        
        // Custom view
        view.frame = CGRect(x: 0, y: 0, width: presentingViewController.view.frame.width, height: presentingViewController.view.frame.height)
        view.backgroundColor = backgroundColor
        
        // Header
        headerLabel = UILabel()
        headerLabel?.text = headerText
        let font = "Damascus"
        if DeviceCheck.iPadPro {
            headerLabel?.font = UIFont(name: font, size: 62)
        } else if DeviceCheck.iPad {
            headerLabel?.font = UIFont(name: font, size: 36)
        } else {
            headerLabel?.font = UIFont(name: font, size: 28)
        }
        headerLabel?.frame = CGRect(x: 0, y: 0, width: presentingViewController.view.frame.width, height: presentingViewController.view.frame.height)
        headerLabel?.center = CGPoint(x: view.frame.width / 2, y: CGRectGetMinY(view.frame) + 80)
        headerLabel?.textAlignment = NSTextAlignment.Center
        headerLabel?.textColor = headerColor
        view.addSubview(headerLabel!)
        
        // Image
        image = UIImageView(image: UIImage(named: imageName))
        image?.frame = CGRect(x: 0, y: 0, width: presentingViewController.view.frame.width / 1.1, height: presentingViewController.view.frame.height / 2)
        image?.contentMode = UIViewContentMode.ScaleAspectFit
        image?.center.x = view.center.x
        image?.center.y = view.center.y + 20
        view.addSubview(image!)
        
        // Download button
        let downloadArea = UIButton()
        downloadArea.frame = CGRect(x: 0, y: 0, width: view.frame.size.width, height: view.frame.size.height)
        downloadArea.backgroundColor = UIColor.clearColor()
        downloadArea.addTarget(self, action: #selector(pressedDownloadButton(_:)), forControlEvents: UIControlEvents.TouchDown)
        downloadArea.center = CGPoint(x: CGRectGetMidX(view.frame), y: CGRectGetMidY(view.frame))
        view.addSubview(downloadArea)
        
        // Close button
        prepareInterAdCloseButton()
        view.addSubview(interAdCloseButton)
        
        // Return custom ad view
        return view
    }
    
    /// Download button
    func pressedDownloadButton(sender: UIButton) {
        if let url = URL {
            UIApplication.sharedApplication().openURL(url)
            delegate?.customAdPause()
        }
    }
}

// MARK: - Close Button
extension CustomAd {
    
    private func prepareInterAdCloseButton() {
        
        let maxLength = max(UIScreen.mainScreen().bounds.size.width, UIScreen.mainScreen().bounds.size.height)
        let iPad      = UIDevice.currentDevice().userInterfaceIdiom == .Pad && maxLength == 1024.0
        let iPadPro   = UIDevice.currentDevice().userInterfaceIdiom == .Pad && maxLength == 1366.0
        
        if iPadPro {
            interAdCloseButton.frame = CGRect(x: 28, y: 28, width: 37, height: 37)
            interAdCloseButton.layer.cornerRadius = 18
        } else if iPad {
            interAdCloseButton.frame = CGRect(x: 19, y: 19, width: 28, height: 28)
            interAdCloseButton.layer.cornerRadius = 14
        } else {
            interAdCloseButton.frame = CGRect(x: 12, y: 12, width: 21, height: 21)
            interAdCloseButton.layer.cornerRadius = 11
        }
        
        interAdCloseButton.setTitle("X", forState: .Normal)
        interAdCloseButton.setTitleColor(UIColor.grayColor(), forState: .Normal)
        interAdCloseButton.backgroundColor = UIColor.whiteColor()
        interAdCloseButton.layer.borderColor = UIColor.grayColor().CGColor
        interAdCloseButton.layer.borderWidth = 2
        interAdCloseButton.addTarget(self, action: #selector(pressedInterAdCloseButton(_:)), forControlEvents: UIControlEvents.TouchDown)
    }
    
    /// Close button
    func pressedInterAdCloseButton(sender: UIButton) {
        Debug.print("Inter ad closed")
        view.removeFromSuperview()
        delegate?.customAdResume()
    }
}