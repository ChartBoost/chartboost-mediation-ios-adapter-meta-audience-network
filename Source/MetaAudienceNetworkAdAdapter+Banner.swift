//
//  MetaAudienceNetworkAdAdapter+Banner.swift
//  ChartboostHeliumAdapterMetaAudienceNetwork
//
//  Created by Vu Chau on 8/31/22.
//

import Foundation
import FBAudienceNetwork
import HeliumSdk

/// Collection of banner-sepcific API implementations
extension MetaAudienceNetworkAdAdapter: FBAdViewDelegate {
    /// Attempt to load a banner ad.
    /// - Parameters:
    ///   - viewController: The ViewController for ad presentation purposes.
    ///   - request: The relevant data associated with the current ad load call.
    func loadBannerAd(viewController: UIViewController?, request: AdLoadRequest) {
        /// Because Meta Audience Network is bidding-only, validate the bid payload and fail early if it is empty.
        guard let bidPayload = request.adm, !bidPayload.isEmpty else {
            loadCompletion?(.failure(self.error(.noBidPayload(placement: request.partnerPlacement))))
            return
        }
        
        let ad = FBAdView.init(placementID: request.partnerPlacement, adSize: getMetaAudienceNetworkBannerAdSize(size: request.size), rootViewController: viewController)
        partnerAd = PartnerAd(ad: ad, details: [:], request: request)
        
        ad.delegate = self
        ad.frame = getFrame(size: request.size)
        ad.loadAd(withBidPayload: bidPayload)
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
    
    // MARK: - FBAdViewDelegate
    
    func adViewDidLoad(_ adView: FBAdView) {
        loadCompletion?(.success(partnerAd)) ?? log(.loadIgnored)
    }
    
    func didFailWithError(adView: FBAdView, error: NSError) {
        loadCompletion?(.failure(self.error(.loadFailure(placement: request.partnerPlacement), error: error))) ?? log(.loadIgnored)
    }
    
    func adViewWillLogImpression(_ adView: FBAdView) {
        partnerAdDelegate?.didTrackImpression(partnerAd) ?? log(.delegateUnavailable)
    }
    
    func adViewDidClick(_ adView: FBAdView) {
        partnerAdDelegate?.didClick(partnerAd) ?? log(.delegateUnavailable)
    }
}
