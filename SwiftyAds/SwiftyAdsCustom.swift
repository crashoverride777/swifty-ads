
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

//    v6.0

import StoreKit

/// Get app store url for app ID
fileprivate func getAppStoreURL(forAppID id: String) -> String {
    #if os(iOS)
        return "itms-apps://itunes.apple.com/app/id" + id
    #endif
    #if os(tvOS)
        return "com.apple.TVAppStore://itunes.apple.com/app/id" + id
    #endif
}

/**
 SwiftyAdsCustom
 
 Singleton class used for creating custom full screen ads.
 */
final public class SwiftyAdsCustom {
    
    // MARK: - Static Properties
    public static let shared = SwiftyAdsCustom()
    
    // MARK: - Properties
    
    /// Custom ad
    struct Ad {
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
        static var all = [Ad]()
        
        /// Tracking
        fileprivate static var current = 0
    }
    
    /// Delegate
    public weak var delegate: SwiftyAdsDelegate?
    
    /// View
    fileprivate let adView = UIView()

    /// Image view
    fileprivate lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.isUserInteractionEnabled = true
        return view
    }()
    
    /// Font style
    fileprivate let font = "HelveticaNeue"
    fileprivate let fontBold = "HelveticaNeue-Bold"
    
    /// Header label
    fileprivate lazy var headerLabel: UILabel = {
        let label = UILabel()
        label.text = "Override Interactive"
        label.textAlignment = .center
        label.textColor = UIColor.black
        return label
    }()
    
    /// New game label
    fileprivate lazy var newGameLabel: UILabel = {
        let label = UILabel()
        label.text = "New"
        label.textAlignment = .center
        label.textColor = UIColor.red
        label.transform = CGAffineTransform(rotationAngle: CGFloat(M_PI_4))
        return label
    }()
    
    /// Close button
    fileprivate lazy var closeButton: UIButton = {
        let button = UIButton()
        button.setTitle("X", for: .normal)
        button.setTitleColor(UIColor.gray, for: .normal)
        button.backgroundColor = UIColor.white
        button.layer.borderColor = UIColor.gray.cgColor
        button.layer.borderWidth = 2
        let iPad = UIDevice.current.userInterfaceIdiom == .pad
        button.layer.cornerRadius = (iPad ? 15 : 11.5)
        button.addTarget(self, action: #selector(dismiss), for: .touchDown)
        return button
    }()
    
    /// Image and store url
    fileprivate var imageName = ""
    fileprivate var appID = ""
    fileprivate var isNewGame = false
    
    /// Interval counter
    private var intervalCounter = 0
    
    /// Removed ads
    private var removedAds = false
    
    /// TV gestures
    #if os(tvOS)
    fileprivate var pressedMainGesture: UITapGestureRecognizer?
    fileprivate var pressedMenuGesture: UITapGestureRecognizer?
    #endif
    
    // MARK: - Init
    
    /// Private singleton init
    private init() { }
    
    /// Show custom ad
    ///
    /// - parameter selectedAd: Show ad for inventory identifier, if set to nil will loop through inventory.
    /// - parameter interval: The interval when to show the ad, e.g when set to 4 ad will be shown every 4th time. Defaults to 0.
    public func show(selectedAd: Inventory? = nil, withInterval interval: Int = 0) {
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
        
        let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "NoAppNameFound"
        let appNameNoWhiteSpaces = appName.replacingOccurrences(of: " ", with: "")
        let appNameNoWhiteSpacesAndDash = appNameNoWhiteSpaces.replacingOccurrences(of: "-", with: "")
        
        if let _ = Inventory.all[adInInventory].imageName.range(of: appNameNoWhiteSpacesAndDash, options: .caseInsensitive) {
            adInInventory += 1
            Inventory.current += 1
        }
        
        if adInInventory >= Inventory.all.count {
            adInInventory = 0
            Inventory.current = 0
        }
        
        guard let validAd = createAd(selectedAd: adInInventory) else { return }
        
         // Gestures
        #if os(iOS)
            let downloadTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(download))
            downloadTapGestureRecognizer.delaysTouchesBegan = true
            imageView.addGestureRecognizer(downloadTapGestureRecognizer)
            adView.addSubview(closeButton)
        #endif
        #if os(tvOS)
            let view = UIApplication.shared.keyWindow?.rootViewController?.view // does not work if adView is used
            
            pressedMainGesture = UITapGestureRecognizer(target: self, action: #selector(download))
            pressedMainGesture?.allowedPressTypes = [NSNumber(value: UIPressType.select.rawValue)]
            view?.addGestureRecognizer(pressedMainGesture!)
            
            pressedMenuGesture = UITapGestureRecognizer(target: self, action: #selector(dismiss))
            pressedMenuGesture?.allowedPressTypes = [NSNumber(value: UIPressType.menu.rawValue)]
            view?.addGestureRecognizer(pressedMenuGesture!)
        #endif
        
        validAd.layer.zPosition = 5000
        let rootViewController = UIApplication.shared.keyWindow?.rootViewController
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

// MARK: - Download / Dismiss

extension SwiftyAdsCustom {

    /// Handle download (tvOS only)
    @objc fileprivate func download() {
        dismiss()
        
        #if os(iOS)
            AppStoreViewController.shared.open(forAppID: appID)
        #endif
        
        #if os(tvOS)
            if let url = URL(string: getAppStoreURL(forAppID: appID)) {
                UIApplication.shared.openURL(url)
            }
        #endif
    }
    
    /// Handle close (tvOS only)
    @objc fileprivate func dismiss() {
        removeFromSuperview()
        delegate?.adDidClose()
    }
}

// MARK: - Ad Management

private extension SwiftyAdsCustom {
    
    /// Create ad
    ///
    /// - parameter selectedAd: The int for the selected ad in the inventory.
    /// - returns: Optional UIView.
    func createAd(selectedAd: Int) -> UIView? {
        
        // Set ad properties
        imageName = Inventory.all[selectedAd].imageName
        appID = Inventory.all[selectedAd].appID
        isNewGame = Inventory.all[selectedAd].isNewGame
        
        // Remove previous ad just incase
        removeFromSuperview()
        
        // Image
        imageView.image = UIImage(named: imageName)
        adView.addSubview(imageView)
        
        // Labels
        adView.addSubview(headerLabel)
        newGameLabel.isHidden = !isNewGame
        adView.addSubview(newGameLabel)
      
        // Set up for orientation
        setupForOrientation()
        
        // Delegate
        delegate?.adDidOpen()
        
        return adView
    }
    
    /// Remove custom ad
    func removeFromSuperview() {
        for gestureRecognizer in imageView.gestureRecognizers ?? [] {
            imageView.removeGestureRecognizer(gestureRecognizer)
        }
        
        #if os(tvOS)
            let view = UIApplication.shared.keyWindow?.rootViewController?.view
            
            if let pressedMainGesture = pressedMainGesture {
                view?.removeGestureRecognizer(pressedMainGesture)
                self.pressedMainGesture = nil
            }
            if let pressedMenuGesture = pressedMenuGesture {
                view?.removeGestureRecognizer(pressedMenuGesture)
                self.pressedMenuGesture = nil
            }
        #endif
        
        closeButton.removeFromSuperview()
        imageView.removeFromSuperview()
        adView.removeFromSuperview()
    }
}

// MARK: - Set up for orientation

private extension SwiftyAdsCustom {
    
    /// Setup for orientation
    func setupForOrientation() {
        guard let rootViewController = UIApplication.shared.keyWindow?.rootViewController else { return }
        
        /// View
        adView.frame = rootViewController.view.frame
        
        /// Image view
        #if os(iOS)
            if UIScreen.main.bounds.height < UIScreen.main.bounds.width { // check if in landscape, works at startup
                imageView.frame = CGRect(x: 0, y: 0, width: adView.frame.width / 1.2, height: adView.frame.height / 1.1)
            } else {
                let iPad = UIDevice.current.userInterfaceIdiom == .pad
                let height = iPad ? adView.frame.height / 2 : adView.frame.height / 2.5
                imageView.frame = CGRect(x: 0, y: 0, width: adView.frame.width / 1.05, height: height)
            }
        #endif
        
        #if os(tvOS)
            imageView.frame = CGRect(x: 0, y: 0, width: adView.frame.width / 1.2, height: adView.frame.height / 1.1)
        #endif
        
        imageView.center = rootViewController.view.center
        
        /// Labels
        let headerFontSize = imageView.frame.height / 13
        headerLabel.font = UIFont(name: font, size: headerFontSize)
        headerLabel.frame = CGRect(x: 0, y: 0, width: adView.frame.width, height: adView.frame.height)
        headerLabel.center = CGPoint(x: 0 + (adView.frame.width / 2), y: imageView.frame.minY + headerFontSize / 1.1)
        
        newGameLabel.font = UIFont(name: fontBold, size: imageView.frame.height / 17)
        newGameLabel.frame = CGRect(x: 0, y: 0, width: adView.frame.width, height: adView.frame.height)
        newGameLabel.center = CGPoint(x: imageView.frame.maxX - (headerFontSize / 1.1), y: imageView.frame.minY + headerFontSize / 1.05)
        
        /// Buttons
        let iPad = UIDevice.current.userInterfaceIdiom == .pad
        let closeButtonSize: CGFloat = iPad ? 30 : 22
        closeButton.frame = CGRect(x: 0, y: 0, width: closeButtonSize, height: closeButtonSize)
        closeButton.center = CGPoint(x: imageView.frame.minX + (closeButtonSize / 1.5), y: imageView.frame.minY + (closeButtonSize / 1.5))
    }
}

// MARK: - SKStoreProductViewController

#if os(iOS)
private class AppStoreViewController: NSObject {
    
    // MARK: - Static Properties
    
    /// Shared instance
    fileprivate static let shared = AppStoreViewController()
    
    // MARK: - Methods
    
    /// Open app store controller for app ID
    fileprivate func open(forAppID appID: String) {
        let storeViewController = SKStoreProductViewController()
        storeViewController.delegate = self
        
        let parameters = [SKStoreProductParameterITunesItemIdentifier: appID]
        storeViewController.loadProduct(withParameters: parameters) { (result, error) in
            if let error = error {
                print(error.localizedDescription)
                return
            }
        }
        
        /// Present, call outside loadProductsWithParemeter so there is no delay. VC has own loading indicator
        let rootViewController = UIApplication.shared.keyWindow?.rootViewController
        rootViewController?.present(storeViewController, animated: true, completion: nil)
    }
}

/// SKStoreProductViewControllerDelegate
extension AppStoreViewController: SKStoreProductViewControllerDelegate {
    
    func productViewControllerDidFinish(_ viewController: SKStoreProductViewController) {
        viewController.dismiss(animated: true, completion: nil)
    }
}
#endif
