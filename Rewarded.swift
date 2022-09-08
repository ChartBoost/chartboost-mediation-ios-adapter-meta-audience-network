//
//  Rewarded.swift
//  ChartboostHeliumAdapterMetaAudienceNetwork
//
//  Created by Vu Chau on 8/31/22.
//

import Foundation
import FBAudienceNetwork
import HeliumSdk

/// Collection of rewarded-sepcific API implementations
extension Adapter: FBRewardedVideoAdDelegate {
    /// Attempt to load a rewarded ad.
    /// - Parameters:
    ///   - request: The relevant data associated with the current ad load call.
    ///   - completion: Handler to notify Helium of task completion.
    func loadRewardedAd(request: AdLoadRequest, completion: @escaping (Result<PartnerAd, Error>) -> Void) {
        /// Because Meta Audience Network is bidding-only, validate the bid payload and fail early if it is empty.
        guard let bidPayload = request.adm, !bidPayload.isEmpty else {
            completion(.failure(error(.loadFailure(placement: request.partnerPlacement), description: "The ad markup is nil/empty.")))
            return
        }
        
        let ad = FBRewardedVideoAd.init(placementID: request.partnerPlacement)
        ad.delegate = self
        ad.load(withBidPayload: bidPayload)
        
        partnerAd = PartnerAd(ad: ad, details: [:], request: request)
        
        loadCompletion = { result in
            completion(result)
        }
    }
    
    /// Attempt to show the currently loaded rewarded ad.
    /// - Parameters:
    ///   - viewController: The ViewController for ad presentation purposes.
    ///   - completion: Handler to notify Helium of task completion.
    func showRewardedAd(viewController: UIViewController, completion: @escaping (Result<PartnerAd, Error>) -> Void) {
        if let ad = partnerAd.ad as? FBRewardedVideoAd {
            if (ad.isAdValid) {
                ad.show(fromRootViewController: viewController)
                completion(.success(partnerAd))
            } else {
                completion(.failure(error(.showFailure(placement: request.partnerPlacement), description: "The ad is invalid.")))
            }
        } else {
            completion(.failure(error(.showFailure(placement: request.partnerPlacement), description: "Ad instance is nil/not a FBRewardedVideoAd.")))
        }
    }
    
    /// Attempt to destroy the current rewarded ad.
    /// - Parameters:
    ///   - completion: Handler to notify Helium of task completion.
    func destroyRewardedAd(completion: @escaping (Result<PartnerAd, Error>) -> Void) {
        if let ad = partnerAd.ad as? FBRewardedVideoAd {
            ad.delegate = nil
            completion(.success(partnerAd))
        } else {
            completion(.failure(error(.invalidateFailure(placement: request.heliumPlacement), description: "Ad instance is nil/not a FBRewardedVideoAd.")))
        }
    }
    
    // MARK: - FBRewardedVideoAdDelegate
    
    func rewardedVideoAdDidLoad(_ rewardedVideoAd: FBRewardedVideoAd) {
        loadCompletion?(.success(partnerAd))
    }
    
    func didFailWithError(rewardedVideoAd: FBRewardedVideoAd, error: NSError) {
        loadCompletion?(.failure(self.error(.loadFailure(placement: request.partnerPlacement), error: error)))
    }
    
    func rewardedVideoAdDidClick(_ rewardedVideoAd: FBRewardedVideoAd) {
        partnerAdDelegate?.didClick(partnerAd)
    }
    
    func rewardedVideoAdDidClose(_ rewardedVideoAd: FBRewardedVideoAd) {
        partnerAdDelegate?.didDismiss(partnerAd, error: nil)
    }
    
    func rewardedVideoAdWillClose(_ rewardedVideoAd: FBRewardedVideoAd) {
        /// NO-OP
    }
    
    func rewardedVideoAdWillLogImpression(_ rewardedVideoAd: FBRewardedVideoAd) {
        partnerAdDelegate?.didTrackImpression(partnerAd)
    }
    
    func rewardedVideoAdVideoComplete(_ rewardedVideoAd: FBRewardedVideoAd) {
        partnerAdDelegate?.didReward(partnerAd, reward: Reward(amount: 0, label: ""))
    }
    
    func rewardedVideoAdServerRewardDidSucceed(_ rewardedVideoAd: FBRewardedVideoAd) {
        /// NO-OP
    }
    
    func rewardedVideoAdServerRewardDidFail(_ rewardedVideoAd: FBRewardedVideoAd) {
        /// NO-OP
    }
}
