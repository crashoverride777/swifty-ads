
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

//    v6.0.3

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

/// String helper
private extension String {
    var lowerCasedNoSpacesAndHyphens: String {
        let noSpaces = replacingOccurrences(of: " ", with: "")
        return noSpaces.replacingOccurrences(of: "-", with: "").lowercased()
    }
}

/**
 SwiftyAdsCustom
 
 Singleton class used for creating custom full screen ads.
 */
final class SwiftyAdsCustom {
    
    // MARK: - Static Properties
    public static let shared = SwiftyAdsCustom()
    
    // MARK: - Properties
    
    /// Custom ad
    struct Inventory {
        let imageName: String
        let appID: String
        let isNewGame: Bool
        
        /// All ads
        static var all = [Inventory]()
        
        /// Tracking
        fileprivate static var current = 0
    }
    
    /// Delegate
    public weak var delegate: SwiftyAdsDelegate?
    
    /// Is showing
    public var isShowing = false
    
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
    private var isRemovedAds = false
    
    // MARK: - Init
    
    /// Private singleton init
    private init() { }
    
    /// Show custom ad
    ///
    /// - parameter newestAd: If set to true will show first ad in inventory. Defaults to false.
    /// - parameter random: If set to true will pick random ad from inventory. Defaults to false. Will not work if newestAd is set to true.
    /// - parameter interval: The interval when to show the ad, e.g when set to 4 ad will be shown every 4th time. Defaults to 0.
    public func show(newest: Bool = false, random: Bool = false, withInterval interval: Int = 0) {
        guard !isRemovedAds && !Inventory.all.isEmpty else { return }
        guard let rootViewController = UIApplication.shared.keyWindow?.rootViewController else { return }
        
        if interval != 0 {
            intervalCounter += 1
            guard intervalCounter >= interval else { return }
            intervalCounter = 0
        }
        
        var adInInventory: Int
        if newest {
            adInInventory = 0
        } else if random {
            let range = UInt32(Inventory.all.count)
            adInInventory = Int(arc4random_uniform(range))
        } else {
            adInInventory = Inventory.current
        }
        
        if adInInventory >= Inventory.all.count {
            adInInventory = 0
            Inventory.current = 0
        }
        
        let noAppNameFound = "NoAppNameFound"
        let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String ?? noAppNameFound
        let adName = Inventory.all[adInInventory].imageName
        
        if adName.lowerCasedNoSpacesAndHyphens.contains(appName.lowerCasedNoSpacesAndHyphens) || appName == noAppNameFound {
            if adInInventory < Inventory.all.count - 1 {
                adInInventory += 1
                Inventory.current += 1
            } else {
                adInInventory = 0
                Inventory.current = 0
            }
        }
        
        guard let validAd = createAd(selectedAd: adInInventory) else { return }
        
         // Gestures
        #if os(iOS)
            let downloadTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(download))
            downloadTapGestureRecognizer.delaysTouchesBegan = true
            imageView.addGestureRecognizer(downloadTapGestureRecognizer)
            adView.addSubview(closeButton)
        #endif
        
        validAd.layer.zPosition = 5000
        rootViewController.view?.addSubview(validAd)
        
        Inventory.current += 1
        isShowing = true
    }
    
    /// Remove (e.g in app purchases)
    public func remove() {
        isRemovedAds = true
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
    @objc public func download() {
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
    @objc public func dismiss() {
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
        isShowing = false
        for gestureRecognizer in imageView.gestureRecognizers ?? [] {
            imageView.removeGestureRecognizer(gestureRecognizer)
        }
       
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
        
        let iPad = UIDevice.current.userInterfaceIdiom == .pad
        
        /// View
        adView.frame = rootViewController.view.frame
        
        /// Image view
        #if os(iOS)
            if UIScreen.main.bounds.height < UIScreen.main.bounds.width { // check if in landscape, works at startup
                let height = iPad ? adView.frame.height / 1.4 : adView.frame.height / 1.1
                imageView.frame = CGRect(x: 0, y: 0, width: adView.frame.width / 1.2, height: height)
            } else {
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
        guard let rootViewController = UIApplication.shared.keyWindow?.rootViewController else { return }
        
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
        rootViewController.present(storeViewController, animated: true, completion: nil)
    }
}

/// SKStoreProductViewControllerDelegate
extension AppStoreViewController: SKStoreProductViewControllerDelegate {
    
    func productViewControllerDidFinish(_ viewController: SKStoreProductViewController) {
        viewController.dismiss(animated: true, completion: nil)
    }
}
#endif
