import UIKit
import SwiftyAds
import GoogleMobileAds

final class NativeAdViewController: UIViewController {

    // MARK: - Properties

    private let swityAds: SwiftyAdsType

    // MARK: - Initialization

    init(swityAds: SwiftyAdsType) {
        self.swityAds = swityAds
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - De-Initialization

    deinit {
        print("Deinit NativeAdViewController")
    }

    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        swityAds.loadNativeAd(
            from: self,
            adUnitIdType: .plist,
            loaderOptions: .single,
            onFinishLoading: {
                print("NativeAdViewController ad finished loading")
            },
            onError: { error in
                print("NativeAdViewController ad loading error \(error)")
            },
            onReceive: { [weak self] nativeAd in
                self?.showNativeAd(nativeAd)
            }
        )
    }
}

// MARK: - GADUnifiedNativeAdDelegate

extension NativeAdViewController: NativeAdDelegate {


}

// MARK: - Private Methods

private extension NativeAdViewController {
    func showNativeAd(_ nativeAd: NativeAd) {
        // Create and place ad in view hierarchy.
        let bundle = Bundle(for: NativeAdViewController.self)
        let nibView = bundle.loadNibNamed("NativeAdView", owner: nil, options: nil)?.first

        guard let nativeAdView = nibView as? NativeAdView else {
            fatalError("NativeAdViewController could not create GADNativeAdView from nib")
        }
        nativeAd.delegate = self

        // Add native ad
        view.addSubview(nativeAdView)
        nativeAdView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            nativeAdView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            nativeAdView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            nativeAdView.topAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            nativeAdView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            nativeAdView.leadingAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            nativeAdView.trailingAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16)
        ])
        
        // Set the mediaContent on the GADMediaView to populate it with available
        // video/image asset.
        nativeAdView.mediaView?.mediaContent = nativeAd.mediaContent

        // Populate the native ad view with the native ad assets.
        // The headline is guaranteed to be present in every native ad.
        (nativeAdView.headlineView as? UILabel)?.text = nativeAd.headline

        // These assets are not guaranteed to be present. Check that they are before
        // showing or hiding them.
        (nativeAdView.bodyView as? UILabel)?.text = nativeAd.body
        nativeAdView.bodyView?.isHidden = nativeAd.body == nil

        (nativeAdView.callToActionView as? UIButton)?.setTitle(nativeAd.callToAction, for: .normal)
        nativeAdView.callToActionView?.isHidden = nativeAd.callToAction == nil

        (nativeAdView.iconView as? UIImageView)?.image = nativeAd.icon?.image
        nativeAdView.iconView?.isHidden = nativeAd.icon == nil

        (nativeAdView.starRatingView as? UIImageView)?.image = imageOfStars(from: nativeAd.starRating)
        nativeAdView.starRatingView?.isHidden = nativeAd.starRating == nil

        (nativeAdView.storeView as? UILabel)?.text = nativeAd.store
        nativeAdView.storeView?.isHidden = nativeAd.store == nil

        (nativeAdView.priceView as? UILabel)?.text = nativeAd.price
        nativeAdView.priceView?.isHidden = nativeAd.price == nil

        (nativeAdView.advertiserView as? UILabel)?.text = nativeAd.advertiser
        nativeAdView.advertiserView?.isHidden = nativeAd.advertiser == nil

        // In order for the SDK to process touch events properly, user interaction
        // should be disabled.
        nativeAdView.callToActionView?.isUserInteractionEnabled = false

        // Associate the native ad view with the native ad object. This is
        // required to make the ad clickable.
        // Note: this should always be done after populating the ad views.
        nativeAdView.nativeAd = nativeAd
    }

    func imageOfStars(from starRating: NSDecimalNumber?) -> UIImage? {
        guard let rating = starRating?.doubleValue else {
            return nil
        }
        if rating >= 5 {
            return UIImage(named: "stars_5")
        } else if rating >= 4.5 {
            return UIImage(named: "stars_4_5")
        } else if rating >= 4 {
            return UIImage(named: "stars_4")
        } else if rating >= 3.5 {
            return UIImage(named: "stars_3_5")
        } else {
            return nil
        }
    }
}
