
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

import StoreKit

/// Get app store url for app ID
fileprivate func getAppStoreURL(forAppID id: String) -> String {
    #if os(iOS)
        return "itms-apps://itunes.apple.com/app/id\(id)"
    #endif
    #if os(tvOS)
        return "com.apple.TVAppStore://itunes.apple.com/app/id\(id)"
    #endif
}

/// String Replacing Occurrences
private extension String {
    var lowerCasedNoSpacesAndHyphens: String {
        let noSpaces = replacingOccurrences(of: " ", with: "")
        return noSpaces.replacingOccurrences(of: "-", with: "").lowercased()
    }
}

/// Contraints Helper
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

/// Main View Spacing
private let mainViewSpacing: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 50 : 10

/**
 SwiftyAdsCustom
 
 Singleton class used for creating custom full screen ads from an inventory.
 */
public final class SwiftyAdsCustom: NSObject {
    
    // MARK: - Static Properties
    
    public static let shared = SwiftyAdsCustom()
    
    // MARK: - Properties
    
    /// Custom ad
    public struct Ad {
        let imageName: String
        let appID: String
        let color: Color
        let isFree: Bool
    }
    
    /// Color
    enum Color: String {
        case white
        case blue
        case red
        case yellow
        case green
    }
    
    /// Colors
    fileprivate var colors: [String: UIColor] = [
        Color.white.rawValue:   .white,
        Color.blue.rawValue:    UIColor(red:0.06, green:0.71, blue:0.85, alpha:1.0),
        Color.red.rawValue:     UIColor(red:0.52, green:0.14, blue:0.29, alpha:1.0),
        Color.yellow.rawValue:  UIColor(red:0.96, green:0.99, blue:0.06, alpha:1.0),
        Color.green.rawValue:   UIColor(red:0.16, green:0.69, blue:0.46, alpha:1.0)
    ]
    
    /// Delegate
    public weak var delegate: SwiftyAdsDelegate?
    
    /// Is showing
    public var isShowing = false
    
    /// Remove ads
    public var isRemoved = false
    
    /// Interval counter
    private var intervalCounter = 0
    
    /// Current ad
    fileprivate var current = 0
    
    #if os(tvOS)
    /// Ad view
    private var adView: AdView?
    #endif
    
    /// All ads
    public var inventory = [Ad]()
    
    /// Setup
    public func setup() {
        SwiftyAdsCustom.shared.inventory = [
            SwiftyAdsCustom.Ad(imageName: "AdVertigus", appID: "1051292772", color: .green, isFree: true),
            SwiftyAdsCustom.Ad(imageName: "AdAngryFlappies", appID: "991933749", color: .blue, isFree: false)
        ]
    }
    
    /// Show custom ad
    ///
    /// - parameter newestAd: If set to true will show first ad in inventory. Defaults to false.
    /// - parameter random: If set to true will pick random ad from inventory. Defaults to false. Will not work if newestAd is set to true.
    /// - parameter interval: The interval when to show the ad, e.g when set to 4 ad will be shown every 4th time. Defaults to nil.
    public func show(random: Bool = false, withInterval interval: Int? = nil) {
        guard !isRemoved && !inventory.isEmpty else { return }
        guard let rootViewController = UIApplication.shared.keyWindow?.rootViewController else { return }
        
        if let interval = interval {
            intervalCounter += 1
            guard intervalCounter >= interval else { return }
            intervalCounter = 0
        }
        
        var adInInventory = random ? Int(arc4random_uniform(UInt32(inventory.count))) : current
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
        
        // Set ad properties
        let selectedColor = inventory[adInInventory].color
        let adColor: UIColor
        if let color = colors[selectedColor.rawValue] {
            adColor = color.withAlphaComponent(0.9)
        } else {
            adColor = UIColor.white.withAlphaComponent(0.9)
        }
        
        guard let image = UIImage(named: inventory[adInInventory].imageName) else { return }
        let appID = inventory[adInInventory].appID
        let isFree = inventory[adInInventory].isFree
        
        let frame = CGRect(x: 0, y: 0, width: 0, height: 0) // 0, see constraints below
        #if os(iOS)
            let adView = AdView(frame: frame, color: adColor, image: image, appID: appID, isFree: isFree, isNew: adInInventory == 0)
            #endif
        #if os(tvOS)
            adView = AdView(frame: frame, color: adColor, image: image, appID: appID, isFree: isFree, isNew: adInInventory == 0)
            guard let adView = adView else { return }
        #endif
        rootViewController.view?.addSubview(adView)
        rootViewController.view?.addConstraints(withFormat: "V:|-\(mainViewSpacing)-[v0]-\(mainViewSpacing)-|", views: adView)
        rootViewController.view?.addConstraints(withFormat: "H:|-\(mainViewSpacing)-[v0]-\(mainViewSpacing)-|", views: adView)
        
        delegate?.adDidOpen()
        isShowing = true
        current += 1
    }
    
    #if os(tvOS)
    /// Download
    public func download() {
        adView?.download()
        adView = nil
        isShowing = false
    }
    
    /// Dismiss
    public func dismiss() {
        adView?.remove()
        adView = nil
        isShowing = false
    }
    #endif
    
    @available(*, deprecated: 6.1, message: "Use isRemoved = true instead")
    func remove() {
        isRemoved = true
    }
}

/// App Store Product View Controller
#if os(iOS)
    extension SwiftyAdsCustom: SKStoreProductViewControllerDelegate {
        
        /// Open app store controller for app ID
        ///
        /// - parameter appID: The app ID string for the app to present.
        func openAppStore(forAppID appID: String) {
            guard let rootViewController = UIApplication.shared.keyWindow?.rootViewController else { return }
            
            let viewController = SKStoreProductViewController()
            viewController.delegate = self
            
            let parameters = [SKStoreProductParameterITunesItemIdentifier: appID]
            viewController.loadProduct(withParameters: parameters) { (result, error) in
                if let error = error {
                    print(error.localizedDescription)
                    viewController.dismiss(animated: true)
                    return
                }
            }
            
            /// Present
            /// Called outside loadProductsWithParemeter so there is no delay. VC has own loading indicator
            rootViewController.present(viewController, animated: true)
        }
        
        /// SKStoreProductViewControllerDelegate
        
        /// Product view controller did finish
        public func productViewControllerDidFinish(_ viewController: SKStoreProductViewController) {
            viewController.dismiss(animated: true)
        }
    }
#endif

// MARK: - Custom Ad

/**
 CustomAd
 
 A UIView class to create a custom ad.
 */
class AdView: UIView {

    // MARK: - Properties
    
    /// Is iPad
    fileprivate var isPad: Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }
    
    /// App ID
    fileprivate var appID: String?
    
    /// Black view
    fileprivate lazy var blackView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        return view
    }()
    
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
            let fontSize: CGFloat = self.isPad ? 30 : 22
        #endif
        #if os(tvOS)
            let fontSize: CGFloat = 35
        #endif
        label.font = UIFont(name: "HelveticaNeue-Bold", size: fontSize)
        label.textAlignment = .center
        label.textColor = .red
        label.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 4)
        return label
    }()
    
    /// New game label
    fileprivate lazy var freeLabel: UILabel = {
        let label = UILabel()
        label.text = "Free"
        #if os(iOS)
            let fontSize: CGFloat = self.isPad ? 30 : 22
        #endif
        #if os(tvOS)
            let fontSize: CGFloat = 35
        #endif
        label.font = UIFont(name: "HelveticaNeue", size: fontSize)
        label.textAlignment = .center
        label.textColor = .black
        label.transform = CGAffineTransform(rotationAngle: -CGFloat.pi / 4)
        return label
    }()
    
    /// Close button
    fileprivate lazy var closeButton: UIButton = {
        let button = UIButton()
        button.setTitle("X", for: .normal)
        button.titleLabel?.font = UIFont(name: "HelveticaNeue-Bold", size: 18)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .red
        button.layer.borderColor = UIColor.white.cgColor
        button.layer.borderWidth = 1
        button.layer.cornerRadius = self.isPad ? 15 : 11.5
        button.addTarget(self, action: #selector(remove), for: .primaryActionTriggered)
        button.addTarget(self, action: #selector(animateCloseButton(_:)), for: .touchDown)
        button.addTarget(self, action: #selector(resetCloseButton(_:)), for: .touchUpOutside)
        button.addTarget(self, action: #selector(resetCloseButton(_:)), for: .touchCancel)
        return button
    }()
    
    /// Download Area
    fileprivate lazy var downloadArea: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(download), for: .primaryActionTriggered)
        button.addTarget(self, action: #selector(loadBlackView), for: .touchDown)
        button.addTarget(self, action: #selector(removeBlackView), for: .touchUpOutside)
        button.addTarget(self, action: #selector(removeBlackView), for: .touchCancel)
        return button
    }()
    
    /// Download button
    fileprivate lazy var downloadButton: UIButton = {
        let button = UIButton()
        button.setTitle("Download", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(red:0.06, green:0.32, blue:0.99, alpha:1.0)
        button.layer.borderColor = button.backgroundColor?.cgColor
        button.layer.borderWidth = 1
        button.layer.cornerRadius = self.isPad ? 6: 5
        button.addTarget(self, action: #selector(download), for: .primaryActionTriggered)
        
        return button
    }()
    
    // MARK: - Deinit
    
    deinit {
        SwiftyAdsCustom.shared.isShowing = false
        SwiftyAdsCustom.shared.delegate?.adDidClose()
        print("Deinit custom ad")
    }
    
    // MARK: - Init
    
    /// Private singleton init
    init(frame: CGRect, color: UIColor, image: UIImage, appID: String, isFree: Bool, isNew: Bool) {
        self.appID = appID
        super.init(frame: frame)
      
        // AdView
        layer.zPosition = 5000
        backgroundColor = color.withAlphaComponent(0.9)
        
        // Image
        imageView.image = image
        imageView.contentMode = .scaleAspectFit
        addSubview(imageView)
        
        // Labels
        addSubview(headerLabel)
        addSubview(freeLabel)
        freeLabel.isHidden = !isFree
        addSubview(newGameLabel)
        newGameLabel.isHidden = !isNew
        
        // Button
        addSubview(downloadButton)
        addSubview(closeButton)
        addSubview(downloadArea)
        
        #if os(tvOS)
            closeButton.isHidden = true
        #endif
        
        addConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Constraints
    private func addConstraints() {
        // Image view
        addConstraints(withFormat: "H:|[v0]|", views: imageView)
        addConstraints(withFormat: "V:|[v0]|", views: imageView)
        
        // Header label
        addConstraints(withFormat: "H:|[v0]|", views: headerLabel)
        addConstraints(withFormat: "V:|-15-[v0]", views: headerLabel)
        
        // New game label
        addConstraints(withFormat: "H:[v0]-2-|", views: newGameLabel)
        addConstraints(withFormat: "V:|-15-[v0]", views: newGameLabel)
        
        // Free label
        addConstraints(withFormat: "H:[v0]-2-|", views: freeLabel)
        addConstraints(withFormat: "V:[v0]-15-|", views: freeLabel)
        
        // Close button
        let closeButtonSize: CGFloat = self.isPad ? 30 : 22
        addConstraints(withFormat: "H:|-5-[v0(\(closeButtonSize))]", views: closeButton)
        addConstraints(withFormat: "V:|-5-[v0(\(closeButtonSize))]", views: closeButton)
        
        // Download area
        addConstraints(withFormat: "H:|-20-[v0]-20-|", views: downloadArea)
        addConstraints(withFormat: "V:|-20-[v0]-20-|", views: downloadArea)
        
        // Download button
        #if os(iOS)
            let downloadButtonSize: CGSize = self.isPad ? CGSize(width: 250, height: 45) : CGSize(width: 200, height: 45)
        #endif
        #if os(tvOS)
            let downloadButtonSize: CGSize = CGSize(width: 350, height: 65)
        #endif
        addConstraints(withFormat: "V:[v0(\(downloadButtonSize.height))]-20-|", views: downloadButton)
        addConstraints(withFormat: "H:[v0(\(downloadButtonSize.width))]", views: downloadButton)
        
        let xConstraint = NSLayoutConstraint(item: downloadButton, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0)
        addConstraint(xConstraint)
    }
}

// MARK: - Black View

extension AdView {
    
    @objc fileprivate func loadBlackView() {
        blackView.removeFromSuperview()
        UIApplication.shared.keyWindow?.addSubview(blackView)
        UIApplication.shared.keyWindow?.addConstraints(withFormat: "V:|-\(mainViewSpacing)-[v0]-\(mainViewSpacing)-|", views: blackView)
        UIApplication.shared.keyWindow?.addConstraints(withFormat: "H:|-\(mainViewSpacing)-[v0]-\(mainViewSpacing)-|", views: blackView)
    }
    
    @objc fileprivate func removeBlackView() {
        blackView.removeFromSuperview()
    }
}

// MARK: - Close Button Animation

extension AdView {
    
    @objc fileprivate func animateCloseButton(_ sender: UIButton) {
        sender.backgroundColor = UIColor.black.withAlphaComponent(0.5)
    }
    
    @objc fileprivate func resetCloseButton(_ sender: UIButton) {
        sender.backgroundColor = .red
    }
}

// MARK: - Download / Remove

extension AdView {
    
    /// Download
    @objc fileprivate func download() {
        remove()
        
        guard let appID = appID else { return }
        #if os(iOS)
            SwiftyAdsCustom.shared.openAppStore(forAppID: appID)
        #endif
        
        #if os(tvOS)
            if let url = URL(string: getAppStoreURL(forAppID: appID)) {
                UIApplication.shared.open(url, options: [:])
            }
        #endif
    }
    
    /// Remove from superview
    @objc fileprivate func remove() {
        blackView.removeFromSuperview()
        removeFromSuperview()
    }
}
