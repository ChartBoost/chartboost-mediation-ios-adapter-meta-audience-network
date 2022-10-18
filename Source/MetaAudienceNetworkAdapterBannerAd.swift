//
//  MetaAudienceNetworkAdapterBannerAd.swift
//  ChartboostHeliumAdapterMetaAudienceNetwork
//
//  Created by Vu Chau on 8/31/22.
//

import Foundation
import FBAudienceNetwork
import HeliumSdk

/// The Helium Meta Audience Network adapter banner ad.
final class MetaAudienceNetworkAdapterBannerAd: MetaAudienceNetworkAdapterAd, PartnerAd {
    
    /// The Meta Audience Network SDK ad instance.
    private var ad: FBAdView?
    
    /// The partner ad view to display inline. E.g. a banner view.
    /// Should be nil for full-screen ads.
    var inlineView: UIView? { ad }
    
    /// Loads an ad.
    /// - parameter viewController: The view controller on which the ad will be presented on. Needed on load for some banners.
    /// - parameter completion: Closure to be performed once the ad has been loaded.
    func load(with viewController: UIViewController?, completion: @escaping (Result<PartnerEventDetails, Error>) -> Void) {
        log(.loadStarted)
        
        /// Because Meta Audience Network is bidding-only, validate the bid payload and fail early if it is empty.
        guard let bidPayload = request.adm, !bidPayload.isEmpty else {
            let error = error(.noBidPayload)
            log(.loadFailed(error))
            return completion(.failure(error))
        }
        
        loadCompletion = completion
        
        let ad = FBAdView(
            placementID: request.partnerPlacement,
            adSize: getMetaAudienceNetworkBannerAdSize(size: request.size),
            rootViewController: viewController
        )
        self.ad = ad
        ad.delegate = self
        ad.frame = getFrame(size: request.size)
        ad.loadAd(withBidPayload: bidPayload)
    }
    
    /// Shows a loaded ad.
    /// It will never get called for banner ads. You may leave the implementation blank for that ad format.
    /// - parameter viewController: The view controller on which the ad will be presented on.
    /// - parameter completion: Closure to be performed once the ad has been shown.
    func show(with viewController: UIViewController, completion: @escaping (Result<PartnerEventDetails, Error>) -> Void) {
        // no-op
    }
    
    /// Map Helium's banner sizes to the Meta Audience Network SDK's supported sizes.
    /// - Parameter size: The Helium's banner size.
    /// - Returns: The corresponding Meta Audience Network banner size.
    private func getMetaAudienceNetworkBannerAdSize(size: CGSize?) -> FBAdSize {
        let height = size?.height ?? 50
        
        switch height {
        case 50...89:
            return kFBAdSizeHeight50Banner
        case 90...249:
            return kFBAdSizeHeight90Banner
        case 250...:
            return kFBAdSizeHeight250Rectangle
        default:
            return kFBAdSizeHeight50Banner
        }
    }
    
    /// Create a frame for the corresponding Helium banner size.
    /// - Parameter size: The Helium's banner size.
    /// - Returns: The corresponding CGRect.
    private func getFrame(size: CGSize?) -> CGRect {
        let height = size?.height ?? 50
        
        switch height {
        case 50...89:
            return CGRect(x: 0, y: 0, width: 320, height: 50)
        case 90...249:
            return CGRect(x: 0, y: 0, width: 728, height: 90)
        case 250...:
            return CGRect(x: 0, y: 0, width: 320, height: 250)
        default:
            return CGRect(x: 0, y: 0, width: 320, height: 50)
        }
    }
}

// MARK: - FBAdViewDelegate

extension MetaAudienceNetworkAdapterBannerAd: FBAdViewDelegate {
    
    func adViewDidLoad(_ adView: FBAdView) {
        log(.loadSucceeded)
        loadCompletion?(.success([:])) ?? log(.loadResultIgnored)
        loadCompletion = nil
    }
    
    func didFailWithError(adView: FBAdView, partnerError: NSError) {
        let error = error(.loadFailure, error: partnerError)
        log(.loadFailed(error))
        loadCompletion?(.failure(error)) ?? log(.loadResultIgnored)
        loadCompletion = nil
    }
    
    func adViewWillLogImpression(_ adView: FBAdView) {
        log(.didTrackImpression)
        delegate?.didTrackImpression(self, details: [:]) ?? log(.delegateUnavailable)
    }
    
    func adViewDidClick(_ adView: FBAdView) {
        log(.didClick(error: nil))
        delegate?.didClick(self, details: [:]) ?? log(.delegateUnavailable)
    }
}
