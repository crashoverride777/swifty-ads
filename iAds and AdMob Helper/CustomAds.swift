
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
private struct CustomAd {
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

/// Custom ads class
class CustomAds: NSObject {
    
    // MARK: - Static Properties
    static let sharedInstance = CustomAds()
    
    // MARK: - Properties
    
    /// Presenting view controller
    var presentingViewController: UIViewController?
    
    /// Delegates
    weak var delegate: AdsDelegate?
    
    /// Properties
    var count = 0
    var interval = 0
    var intervalCounter = 0
    
    /// Removed ads
    private var removedAds = false
    
    // Ads
    private var view = UIView()
    private var headerLabel: UILabel?
    private var image: UIImageView?
    private var URL: NSURL?
    
    // MARK: - Init
    private override init() {
        super.init()
    }
    
    /// Inter ads close button (iAd and customAd)
    private var interAdCloseButton = UIButton(type: UIButtonType.System)
    
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
extension CustomAds {
    
    /// Show custom ad
    private func showInterAd() {
        let randomCustomInterAd = Int(arc4random_uniform(UInt32(count)))
        
        switch randomCustomInterAd {
            
        case 0:
            if let customAd1 = createCustomAd(CustomAd.Ad1.backgroundColor, headerColor: CustomAd.Ad1.headerColor, headerText: CustomAd.Ad1.headerText, imageName: CustomAd.Ad1.image, appURL: CustomAd.Ad1.appURL) {
                presentingViewController?.view?.window?.rootViewController?.view.addSubview(customAd1)
            }
        case 1:
            if let customAd2 = createCustomAd(CustomAd.Ad2.backgroundColor, headerColor: CustomAd.Ad2.headerColor, headerText: CustomAd.Ad2.headerText, imageName: CustomAd.Ad2.image, appURL: CustomAd.Ad2.appURL) {
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
        downloadArea.addTarget(self, action: #selector(customAdPressedDownloadButton(_:)), forControlEvents: UIControlEvents.TouchDown)
        downloadArea.center = CGPoint(x: CGRectGetMidX(view.frame), y: CGRectGetMidY(view.frame))
        view.addSubview(downloadArea)
        
        // Close button
        prepareInterAdCloseButton()
        view.addSubview(interAdCloseButton)
        
        // Return custom ad view
        return view
    }
    
    /// Pressed custom inter download button
    func customAdPressedDownloadButton(sender: UIButton) {
        if let url = URL {
            UIApplication.sharedApplication().openURL(url)
            delegate?.pauseTasks()
        }
    }
}

// MARK: - Inter ad close button
extension CustomAds {
    
    /// Prepare inter ad close button
    private func prepareInterAdCloseButton() {
        if DeviceCheck.iPadPro {
            interAdCloseButton.frame = CGRect(x: 28, y: 28, width: 37, height: 37)
            interAdCloseButton.layer.cornerRadius = 18
        } else if DeviceCheck.iPad {
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
    
    /// Pressed inter ad close button
    func pressedInterAdCloseButton(sender: UIButton) {
        Debug.print("Inter ad closed")
        view.removeFromSuperview()
        delegate?.resumeTasks()
    }
}