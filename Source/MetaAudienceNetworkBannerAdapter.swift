//
//  MetaAudienceNetworkBannerAdapter.swift
//  ChartboostHeliumAdapterMetaAudienceNetwork
//
//  Created by Vu Chau on 8/31/22.
//

import Foundation
import HeliumSdk
import FBAudienceNetwork

/// Closure for notifying Helium of an ad impression event
var onBannerLoaded: (() -> Void)?

/// Closure for notifying Helium of an ad load failure event
var onBannerFailedToLoad: ((_ error: NSError) -> Void)?

/// Closure for notifying Helium of an ad impression event
var onBannerImpressed: (() -> Void)?

/// Closure for notifying Helium of an ad click event
var onBannerClicked: (() -> Void)?

/// Meta Audience Network adapter's banner-specific API implementations
extension MetaAudienceNetworkAdapter {
    /// Attempt to load a banner ad.
    /// - Parameters:
    ///   - request: The relevant data associated with the current ad load call.
    ///   - partnerAdDelegate: Delegate for ad lifecycle notification purposes.
    ///   - viewController: The ViewController for ad presentation purposes.
    ///   - completion: Handler to notify Helium of task completion.
    func loadBannerAd(request: AdLoadRequest,
                      partnerAdDelegate: PartnerAdDelegate,
                      viewController: UIViewController?,
                      completion: @escaping (Result<PartnerAd, Error>) -> Void) {
        /// Because Meta Audience Network is bidding-only, validate the bid payload and fail early if it is empty.
        guard let bidPayload = request.adm, !bidPayload.isEmpty else {
            completion(.failure(error(.loadFailure(placement: request.partnerPlacement),
                                      description: "\(partnerDisplayName) failed to load the \(request.format) ad because the ad markup is nil/empty.",
                                      error: nil)))
            
            return
        }
        
        let ad = FBAdView.init(placementID: request.partnerPlacement,
                               adSize: getMetaAudienceNetworkBannerAdSize(size: request.size),
                               rootViewController: viewController)
        ad.delegate = self
        ad.frame = getFrame(size: request.size)
        ad.loadAd(withBidPayload: bidPayload)
        
        let partnerAd = PartnerAd(ad: ad, details: [:], request: request)
        
        onBannerLoaded = {
            completion(.success(partnerAd))
        }
        
        onBannerFailedToLoad = { error in
            completion(.failure(self.error(.loadFailure(placement: request.partnerPlacement),
                                           description: "\(self.partnerDisplayName) failed to load the \(request.format) ad.",
                                           error: error)))
        }
        
        onBannerImpressed = {
            self.log(.didTrackImpression(partnerAd))
            partnerAdDelegate.didTrackImpression(partnerAd)
        }
        
        onBannerClicked = {
            self.log(.didClick(partnerAd, partnerError: nil))
            partnerAdDelegate.didClick(partnerAd)
        }
    }
    
    /// Attempt to destroy the current banner ad.
    /// - Parameters:
    ///   - partnerAd: The PartnerAd instance containing the ad to be invalidated.
    ///   - completion: Handler to notify Helium of task completion.
    func destroyBannerAd(partnerAd: PartnerAd, completion: @escaping (Result<PartnerAd, Error>) -> Void) {
        if let ad = partnerAd.ad as? FBAdView {
            ad.delegate = nil
            completion(.success(partnerAd))
        } else {
            completion(.failure(error(.invalidateFailure(placement: partnerAd.request.heliumPlacement),
                                      description: "\(partnerDisplayName) failed to invalidate the \(partnerAd.request.format) ad. Ad is already nil or not a FBAdView.",
                                      error: nil)))
        }
    }
    
    /// Map Helium's banner sizes to the Meta Audience Network SDK's supported sizes.
    /// - Parameter size: The Helium's banner size.
    /// - Returns: The corresponding Meta Audience Network banner size.
    func getMetaAudienceNetworkBannerAdSize(size: CGSize?) -> FBAdSize {
        let height = size?.height ?? 50
        
        switch height {
        case 50..<89:
            return kFBAdSizeHeight50Banner
        case 90..<249:
            return kFBAdSizeHeight90Banner
        case _ where height >= 250:
            return kFBAdSizeHeight250Rectangle
        default:
            return kFBAdSizeHeight50Banner
        }
    }
    
    /// Create a frame for the corresponding Helium banner size.
    /// - Parameter size: The Helium's banner size.
    /// - Returns: The corresponding CGRect.
    func getFrame(size: CGSize?) -> CGRect {
        let height = size?.height ?? 50
        
        switch height {
        case 50..<89:
            return CGRect(x: 0, y: 0, width: 320, height: 50)
        case 90..<249:
            return CGRect(x: 0, y: 0, width: 728, height: 90)
        case _ where height >= 250:
            return CGRect(x: 0, y: 0, width: 320, height: 250)
        default:
            return CGRect(x: 0, y: 0, width: 320, height: 50)
        }
    }
    
    // MARK: - FBAdViewDelegate
    
    func adViewDidLoad(adView: FBAdView) {
        if let onBannerLoaded = onBannerLoaded {
            onBannerLoaded()
        }
    }
    
    func didFailWithError(adView: FBAdView, error: NSError) {
        if let onBannerFailedToLoad = onBannerFailedToLoad {
            onBannerFailedToLoad(error)
        }
    }
    
    func adViewWillLogImpression(adView: FBAdView) {
        if let onBannerImpressed = onBannerImpressed {
            onBannerImpressed()
        }
    }
    
    func adViewDidClick(adView: FBAdView) {
        if let onBannerClicked = onBannerClicked {
            onBannerClicked()
        }
    }
}
