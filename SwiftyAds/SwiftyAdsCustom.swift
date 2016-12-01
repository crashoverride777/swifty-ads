
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

//    v6.1.1

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
public final class SwiftyAdsCustom: NSObject {
    
    // MARK: - Static Properties
    public static let shared = SwiftyAdsCustom()
    
    // MARK: - Properties
    
    /// Color
    enum Color: String {
        case white
        case blue
        case red
        case yellow
        case green
    }
    
    /// Custom ad
    public struct Ad {
        let imageName: String
        let appID: String
        let color: Color
    }
    
    /// Delegate
    public weak var delegate: SwiftyAdsDelegate?
    
    /// Is showing
    public var isShowing = false
    
    /// All ads
    public var inventory = [Ad]()
    
    /// Is iPad
    fileprivate var isPad: Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }
    
    /// App ID
    fileprivate var appID: String?
    
    /// Interval counter
    private var intervalCounter = 0
    
    /// Removed ads
    private var isRemoved = false
    
    /// Current ad
    fileprivate var current = 0
    
    /// Colors
    fileprivate var colors: [String: UIColor] = [
        Color.white.rawValue:   .white,
        Color.blue.rawValue:    UIColor(red:0.06, green:0.71, blue:0.85, alpha:1.0),
        Color.red.rawValue:     UIColor(red:0.52, green:0.14, blue:0.29, alpha:1.0),
        Color.yellow.rawValue:  UIColor(red:0.96, green:0.99, blue:0.06, alpha:1.0),
        Color.green.rawValue:   UIColor(red:0.16, green:0.69, blue:0.46, alpha:1.0)
    ]
    
    /// View
    fileprivate let adView = UIView()
    
    /// Image view
    fileprivate lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.isUserInteractionEnabled = true
        return view
    }()
    
    /// Header label
    fileprivate lazy var headerLabel: UILabel = {
        let label = UILabel()
        label.text = "Override Interactive"
        #if os(iOS)
            let fontSize: CGFloat = self.isPad ? 35 : 25
        #endif
        #if os(tvOS)
            let fontSize: CGFloat = 62
        #endif
        label.font = UIFont(name: "HelveticaNeue", size: fontSize)
        label.textAlignment = .center
        label.textColor = .black
        return label
    }()
    
    /// New game label
    fileprivate lazy var newGameLabel: UILabel = {
        let label = UILabel()
        label.text = "New"
        #if os(iOS)
            let fontSize: CGFloat = self.isPad ? 32 : 22
        #endif
        #if os(tvOS)
            let fontSize: CGFloat = 35
        #endif
        label.font = UIFont(name: "HelveticaNeue-Bold", size: fontSize)
        label.textAlignment = .center
        label.textColor = UIColor.red
        label.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 4)
        return label
    }()
    
    /// Close button
    fileprivate lazy var closeButton: UIButton = {
        let button = UIButton()
        button.setTitle("X", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .red
        button.layer.borderColor = UIColor.white.cgColor
        button.layer.borderWidth = 1
        button.layer.cornerRadius = self.isPad ? 15 : 11.5
        button.addTarget(self, action: #selector(dismiss), for: .primaryActionTriggered)
        return button
    }()
    
    // MARK: - Init
    
    /// Private singleton init
    private override init() { }
    
    /// Show custom ad
    ///
    /// - parameter newestAd: If set to true will show first ad in inventory. Defaults to false.
    /// - parameter random: If set to true will pick random ad from inventory. Defaults to false. Will not work if newestAd is set to true.
    /// - parameter interval: The interval when to show the ad, e.g when set to 4 ad will be shown every 4th time. Defaults to nil.
    public func show(newest: Bool = false, random: Bool = false, withInterval interval: Int? = nil) {
        guard !isRemoved && !inventory.isEmpty else { return }
        guard let rootViewController = UIApplication.shared.keyWindow?.rootViewController else { return }
        
        if let interval = interval {
            intervalCounter += 1
            guard intervalCounter >= interval else { return }
            intervalCounter = 0
        }
        
        var adInInventory: Int
        if newest {
            adInInventory = 0
        } else if random {
            let range = UInt32(inventory.count)
            adInInventory = Int(arc4random_uniform(range))
        } else {
            adInInventory = current
        }
        
        if adInInventory >= inventory.count {
            adInInventory = 0
            current = 0
        }
        
        let noAppNameFound = "NoAppNameFound"
        let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String ?? noAppNameFound
        let adName = inventory[adInInventory].imageName
        
        if adName.lowerCasedNoSpacesAndHyphens.contains(appName.lowerCasedNoSpacesAndHyphens) || appName == noAppNameFound {
            if adInInventory < inventory.count - 1 {
                adInInventory += 1
                current += 1
            } else {
                adInInventory = 0
                current = 0
            }
        }
        
        guard let validAd = createAd(selectedAd: adInInventory) else { return }
        rootViewController.view?.addSubview(validAd)
        addConstraints()
        delegate?.adDidOpen()
        
        current += 1
        isShowing = true
    }
    
    /// Remove (e.g in app purchases)
    public func remove() {
        isRemoved = true
        removeFromSuperview()
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
        let selectedColor = inventory[selectedAd].color
        let imageName = inventory[selectedAd].imageName
        appID = inventory[selectedAd].appID
        
        // Remove previous ad just incase
        removeFromSuperview()
        
        // AdView
        adView.layer.zPosition = 5000
        if let color = colors[selectedColor.rawValue] {
            adView.backgroundColor = color.withAlphaComponent(0.9)
        } else {
            adView.backgroundColor = UIColor.white.withAlphaComponent(0.9)
        }
        
        // Image
        imageView.image = UIImage(named: imageName)
        imageView.contentMode = .scaleAspectFit
        adView.addSubview(imageView)
        
        // Labels
        adView.addSubview(headerLabel)
        
        adView.addSubview(newGameLabel)
        newGameLabel.isHidden = selectedAd != 0
        
        // Button
        adView.addSubview(closeButton)
        
        #if os(iOS)
            // Gestures
            let downloadTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(download))
            downloadTapGestureRecognizer.delaysTouchesBegan = true
            imageView.addGestureRecognizer(downloadTapGestureRecognizer)
        #endif
        #if os(tvOS)
            closeButton.isHidden = true
        #endif
        
        return adView
    }
}

// MARK: - Download / Dismiss

extension SwiftyAdsCustom {
    
    /// Handle download (tvOS only)
    @objc public func download() {
        dismiss()
        guard let appID = appID else { return }
        
        #if os(iOS)
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
    
    /// Remove from superview
    fileprivate func removeFromSuperview() {
        isShowing = false
        for gestureRecognizer in imageView.gestureRecognizers ?? [] {
            imageView.removeGestureRecognizer(gestureRecognizer)
        }
        
        adView.removeFromSuperview()
    }
}

// MARK: - Add Constraints

private extension SwiftyAdsCustom {
    
    func addConstraints() {
        guard let view = UIApplication.shared.keyWindow?.rootViewController?.view else { return }
        
        #if os(iOS)
            if UIDevice.current.orientation.isLandscape {
                setAdViewLandscapeContraints(for: view)
            } else {
                // AdView
                view.addConstraints(withFormat: "V:|-30-[v0]-30-|", views: adView)
                view.addConstraints(withFormat: "H:|-10-[v0]-10-|", views: adView)
            }
        #endif
        
        #if os(tvOS)
            setAdViewLandscapeContraints(for: view)
        #endif
        
        // Image view
        adView.addConstraints(withFormat: "H:|[v0]|", views: imageView)
        adView.addConstraints(withFormat: "V:|[v0]|", views: imageView)
        
        // Header label
        adView.addConstraints(withFormat: "H:|[v0]|", views: headerLabel)
        adView.addConstraints(withFormat: "V:|-15-[v0]", views: headerLabel)
        
        // New game label
        adView.addConstraints(withFormat: "H:[v0]-5-|", views: newGameLabel)
        adView.addConstraints(withFormat: "V:|-20-[v0]", views: newGameLabel)
        
        // Close button
        let closeButtonSize: CGFloat = self.isPad ? 30 : 22
        adView.addConstraints(withFormat: "H:|-5-[v0(\(closeButtonSize))]", views: closeButton)
        adView.addConstraints(withFormat: "V:|-5-[v0(\(closeButtonSize))]", views: closeButton)
    }
    
    func setAdViewLandscapeContraints(for view: UIView) {
        view.addConstraints(withFormat: "V:|-10-[v0]-10-|", views: adView)
        view.addConstraints(withFormat: "H:|-40-[v0]-40-|", views: adView)
    }
}

// MARK: - String Replacing Occurrences

private extension String {
    var lowerCasedNoSpacesAndHyphens: String {
        let noSpaces = replacingOccurrences(of: " ", with: "")
        return noSpaces.replacingOccurrences(of: "-", with: "").lowercased()
    }
}

// MARK: - Contraints Helper 

private extension UIView {
    
    func addConstraints(withFormat format: String, views: UIView...) {
        var viewsDictionary = [String: UIView]()
        for (index, view) in views.enumerated() {
            let key = "v\(index)"
            view.translatesAutoresizingMaskIntoConstraints = false
            viewsDictionary[key] = view
        }
        
        let constraint = NSLayoutConstraint.constraints(withVisualFormat: format, options: NSLayoutFormatOptions(), metrics: nil, views: viewsDictionary)
        addConstraints(constraint)
    }
}

// MARK: - SKStoreProductViewControllerDelegate

#if os(iOS)
    extension SwiftyAdsCustom: SKStoreProductViewControllerDelegate {
        
        public func productViewControllerDidFinish(_ viewController: SKStoreProductViewController) {
            viewController.dismiss(animated: true, completion: nil)
        }
    }
#endif
