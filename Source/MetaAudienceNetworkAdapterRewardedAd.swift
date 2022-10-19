//
//  MetaAudienceNetworkAdapterRewardedAd.swift
//  ChartboostHeliumAdapterMetaAudienceNetwork
//
//  Created by Vu Chau on 8/31/22.
//

import Foundation
import FBAudienceNetwork
import HeliumSdk

/// The Helium Meta Audience Network adapter rewarded ad.
final class MetaAudienceNetworkAdapterRewardedAd: MetaAudienceNetworkAdapterAd, PartnerAd {
    
    /// The Meta Audience Network SDK ad instance.
    private var ad: FBRewardedVideoAd?
    
    /// The partner ad view to display inline. E.g. a banner view.
    /// Should be nil for full-screen ads.
    var inlineView: UIView? { nil }
    
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
        
        let ad = FBRewardedVideoAd(placementID: request.partnerPlacement)
        self.ad = ad
        ad.delegate = self
        ad.load(withBidPayload: bidPayload)
    }
    
    /// Shows a loaded ad.
    /// It will never get called for banner ads. You may leave the implementation blank for that ad format.
    /// - parameter viewController: The view controller on which the ad will be presented on.
    /// - parameter completion: Closure to be performed once the ad has been shown.
    func show(with viewController: UIViewController, completion: @escaping (Result<PartnerEventDetails, Error>) -> Void) {
        log(.showStarted)
        if let ad = ad {
            if (ad.isAdValid) {
                ad.show(fromRootViewController: viewController)
                log(.showSucceeded)
                completion(.success([:]))
            } else {
                let error = error(.showFailure, description: "Ad is invalid.")
                log(.showFailed(error))
                completion(.failure(error))
            }
        } else {
            let error = error(.noAdReadyToShow)
            log(.showFailed(error))
            completion(.failure(error))
        }
    }
}

// MARK: - FBRewardedVideoAdDelegate

extension MetaAudienceNetworkAdapterRewardedAd: FBRewardedVideoAdDelegate {
    
    func rewardedVideoAdDidLoad(_ rewardedVideoAd: FBRewardedVideoAd) {
        log(.loadSucceeded)
        loadCompletion?(.success([:])) ?? log(.loadResultIgnored)
        loadCompletion = nil
    }
    
    func didFailWithError(rewardedVideoAd: FBRewardedVideoAd, partnerError: NSError) {
        let error = error(.loadFailure, error: partnerError)
        log(.loadFailed(error))
        loadCompletion?(.failure(error)) ?? log(.loadResultIgnored)
        loadCompletion = nil
    }
    
    func rewardedVideoAdDidClick(_ rewardedVideoAd: FBRewardedVideoAd) {
        log(.didClick(error: nil))
        delegate?.didClick(self, details: [:]) ?? log(.delegateUnavailable)
    }
    
    func rewardedVideoAdDidClose(_ rewardedVideoAd: FBRewardedVideoAd) {
        log(.didDismiss(error: nil))
        delegate?.didDismiss(self, details: [:], error: nil) ?? log(.delegateUnavailable)
    }
    
    func rewardedVideoAdWillClose(_ rewardedVideoAd: FBRewardedVideoAd) {
        log(.delegateCallIgnored)
    }
    
    func rewardedVideoAdWillLogImpression(_ rewardedVideoAd: FBRewardedVideoAd) {
        log(.didTrackImpression)
        delegate?.didTrackImpression(self, details: [:]) ?? log(.delegateUnavailable)
    }
    
    func rewardedVideoAdVideoComplete(_ rewardedVideoAd: FBRewardedVideoAd) {
        log(.didReward)
        delegate?.didReward(self, details: [:]) ?? log(.delegateUnavailable)
    }
    
    func rewardedVideoAdServerRewardDidSucceed(_ rewardedVideoAd: FBRewardedVideoAd) {
        log(.delegateCallIgnored)
    }
    
    func rewardedVideoAdServerRewardDidFail(_ rewardedVideoAd: FBRewardedVideoAd) {
        log(.delegateCallIgnored)
    }
}
