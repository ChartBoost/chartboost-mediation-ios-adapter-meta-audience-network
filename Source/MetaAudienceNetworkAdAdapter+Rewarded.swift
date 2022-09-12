//
//  MetaAudienceNetworkAdAdapter+Rewarded.swift
//  ChartboostHeliumAdapterMetaAudienceNetwork
//
//  Created by Vu Chau on 8/31/22.
//

import Foundation
import FBAudienceNetwork
import HeliumSdk

/// Collection of rewarded-sepcific API implementations
extension MetaAudienceNetworkAdAdapter: FBRewardedVideoAdDelegate {
    /// Attempt to load a rewarded ad.
    /// - Parameters:
    ///   - request: The relevant data associated with the current ad load call.
    func loadRewardedAd(request: PartnerAdLoadRequest) {
        /// Because Meta Audience Network is bidding-only, validate the bid payload and fail early if it is empty.
        guard let bidPayload = request.adm, !bidPayload.isEmpty else {
            loadCompletion?(.failure(self.error(.noBidPayload(request))))
            loadCompletion = nil
            return
        }
        
        let ad = FBRewardedVideoAd.init(placementID: request.partnerPlacement)
        partnerAd = PartnerAd(ad: ad, details: [:], request: request)
        
        ad.delegate = self
        ad.load(withBidPayload: bidPayload)
    }
    
    /// Attempt to show the currently loaded rewarded ad.
    /// - Parameter viewController: The ViewController for ad presentation purposes.
    /// - Returns: A Result<PartnerAd, Error> indicating the success or failure of the show call.
    func showRewardedAd(viewController: UIViewController) -> Result<PartnerAd, Error> {
        if let ad = partnerAd.ad as? FBRewardedVideoAd {
            if (ad.isAdValid) {
                ad.show(fromRootViewController: viewController)
                return .success(partnerAd)
            } else {
                return .failure(error(.showFailure(partnerAd), description: "The ad is invalid."))
            }
        } else {
            return .failure(error(.showFailure(partnerAd), description: "Ad instance is nil/not a FBRewardedVideoAd."))
        }
    }
    
    // MARK: - FBRewardedVideoAdDelegate
    
    func rewardedVideoAdDidLoad(_ rewardedVideoAd: FBRewardedVideoAd) {
        loadCompletion?(.success(partnerAd)) ?? log(.loadResultIgnored)
        loadCompletion = nil
    }
    
    func didFailWithError(rewardedVideoAd: FBRewardedVideoAd, error: NSError) {
        loadCompletion?(.failure(self.error(.loadFailure(request), error: error))) ?? log(.loadResultIgnored)
        loadCompletion = nil
    }
    
    func rewardedVideoAdDidClick(_ rewardedVideoAd: FBRewardedVideoAd) {
        log(.didClick(partnerAd, error: nil))
        partnerAdDelegate?.didClick(partnerAd) ?? log(.delegateUnavailable)
    }
    
    func rewardedVideoAdDidClose(_ rewardedVideoAd: FBRewardedVideoAd) {
        log(.didDismiss(partnerAd, error: nil))
        partnerAdDelegate?.didDismiss(partnerAd, error: nil) ?? log(.delegateUnavailable)
    }
    
    func rewardedVideoAdWillClose(_ rewardedVideoAd: FBRewardedVideoAd) {
        log("rewardedVideoAdWillClose")
    }
    
    func rewardedVideoAdWillLogImpression(_ rewardedVideoAd: FBRewardedVideoAd) {
        log(.didTrackImpression(partnerAd))
        partnerAdDelegate?.didTrackImpression(partnerAd) ?? log(.delegateUnavailable)
    }
    
    func rewardedVideoAdVideoComplete(_ rewardedVideoAd: FBRewardedVideoAd) {
        let reward = Reward(amount: 0, label: "")
        
        log(.didReward(partnerAd, reward: reward))
        partnerAdDelegate?.didReward(partnerAd, reward: reward) ?? log(.delegateUnavailable)
    }
    
    func rewardedVideoAdServerRewardDidSucceed(_ rewardedVideoAd: FBRewardedVideoAd) {
        log("rewardedVideoAdServerRewardDidSucceed")
    }
    
    func rewardedVideoAdServerRewardDidFail(_ rewardedVideoAd: FBRewardedVideoAd) {
        log("rewardedVideoAdServerRewardDidFail")
    }
}
