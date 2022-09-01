//
//  MetaAudienceNetworkRewardedAdapter.swift
//  ChartboostHeliumAdapterMetaAudienceNetwork
//
//  Created by Vu Chau on 8/31/22.
//

import Foundation
import HeliumSdk
import FBAudienceNetwork

/// Closure for notifying Helium of an ad load event
var onRewardedAdLoaded: (() -> Void)?

/// Closure for notifying Helium of an ad load failure event
var onRewardedAdFailedToLoad: ((_ error: NSError) -> Void)?

/// Closure for notifying Helium of an ad click event
var onRewardedAdClicked: (() -> Void)?

/// Closure for notifying Helium of an ad dismiss event
var onRewardedAdDismissed: (() -> Void)?

/// Closure for notifying Helium of an ad impression event
var onRewardedAdImpressed: (() -> Void)?

/// Closure for notifying Helium of an ad completion event
var onRewardedAdCompleted: (() -> Void)?

/// Meta Audience Network adapter's rewarded-specific API implementations
extension MetaAudienceNetworkAdapter {
    /// Attempt to load a rewarded ad.
    /// - Parameters:
    ///   - request: The relevant data associated with the current ad load call.
    ///   - partnerAdDelegate: Delegate for ad lifecycle notification purposes.
    ///   - completion: Handler to notify Helium of task completion.
    func loadRewardedAd(request: AdLoadRequest,
                        partnerAdDelegate: PartnerAdDelegate,
                        completion: @escaping (Result<PartnerAd, Error>) -> Void) {
        /// Because Meta Audience Network is bidding-only, validate the bid payload and fail early if it is empty.
        guard let bidPayload = request.adm, !bidPayload.isEmpty else {
            completion(.failure(error(.loadFailure(placement: request.partnerPlacement),
                                      description: "\(partnerDisplayName) failed to load the \(request.format) ad because the ad markup is nil/empty.",
                                      error: nil)))
            return
        }
        
        /// Since fullscreen ads require a load-show paradigm, persist the delegate so it can be retrieved at show time.
        delegates[request.heliumPlacement] = partnerAdDelegate
        
        let ad = FBRewardedVideoAd.init(placementID: request.partnerPlacement)
        ad.delegate = self
        ad.load(withBidPayload: bidPayload)
        
        onRewardedAdLoaded = {
            completion(.success(PartnerAd(ad: ad, details: [:], request: request)))
        }
        
        onRewardedAdFailedToLoad = { error in
            completion(.failure(self.error(.loadFailure(placement: request.partnerPlacement),
                                           description: "\(self.partnerDisplayName) failed to load the \(request.format) ad.",
                                           error: error)))
        }
    }
    
    /// Attempt to show the currently loaded rewarded ad.
    /// - Parameters:
    ///   - partnerAd: The PartnerAd instance containing the ad to be shown.
    ///   - viewController: The ViewController for ad presentation purposes.
    ///   - completion: Handler to notify Helium of task completion.
    func showRewardedAd(partnerAd: PartnerAd,
                        viewController: UIViewController,
                        completion: @escaping (Result<PartnerAd, Error>) -> Void) {
        let delegate = delegates[partnerAd.request.heliumPlacement]
        
        if let ad = partnerAd.ad as? FBRewardedVideoAd {
            if (ad.isAdValid) {
                ad.show(fromRootViewController: viewController)
                
                onRewardedAdImpressed = {
                    self.log(.didTrackImpression(partnerAd))
                    delegate?.didTrackImpression(partnerAd) ?? self.log("Unable to notify didTrackImpression for the \(self.partnerDisplayName) adapter. Delegate is nil.")
                    completion(.success(partnerAd))
                }
                
                onRewardedAdClicked = {
                    self.log(.didClick(partnerAd, partnerError: nil))
                    delegate?.didClick(partnerAd) ?? self.log("Unable to notify didClick for the \(self.partnerDisplayName) adapter. Delegate is nil.")
                }
                
                onRewardedAdCompleted = {
                    let reward = Reward(amount: 0, label: "")
                    self.log(.didReward(partnerAd, reward: reward))
                    delegate?.didReward(partnerAd, reward: reward) ?? self.log("Unable to notify didReward for the \(self.partnerDisplayName) adapter. Delegate is nil.")
                }
                
                onRewardedAdDismissed = {
                    self.log(.didDismiss(partnerAd, partnerError: nil))
                    delegate?.didDismiss(partnerAd, error: nil) ?? self.log("Unable to notify didDismiss for the \(self.partnerDisplayName) adapter. Delegate is nil.")
                }
            } else {
                completion(.failure(error(.showFailure(placement: partnerAd.request.partnerPlacement),
                                          description: "\(partnerDisplayName) failed to show the \(partnerAd.request.format) ad because the ad is invalid.",
                                          error: nil)))
            }
        } else {
            completion(.failure(error(.showFailure(placement: partnerAd.request.partnerPlacement),
                                      description: "\(partnerDisplayName) failed to show the \(partnerAd.request.format) ad. Ad instance is nil or not a FBRewardedVideoAd.",
                                      error: nil)))
        }
    }
    
    /// Attempt to destroy the current rewarded ad.
    /// - Parameters:
    ///   - partnerAd: The PartnerAd instance containing the ad to be invalidated.
    ///   - completion: Handler to notify Helium of task completion.
    func destroyRewardedAd(partnerAd: PartnerAd,
                           completion: @escaping (Result<PartnerAd, Error>) -> Void) {
        if let ad = partnerAd.ad as? FBRewardedVideoAd {
            delegates.removeAll()
            ad.delegate = nil
            completion(.success(partnerAd))
        } else {
            completion(.failure(error(.invalidateFailure(placement: partnerAd.request.heliumPlacement),
                                      description: "\(partnerDisplayName) failed to invalidate the \(partnerAd.request.format) ad. Ad instance is nil or not a FBRewardedVideoAd.",
                                      error: nil)))
        }
    }
    
    // MARK: - FBRewardedVideoAdDelegate
    
    func rewardedVideoAdDidLoad(rewardedVideoAd: FBRewardedVideoAd) {
        if let onRewardedAdLoaded = onRewardedAdLoaded {
            onRewardedAdLoaded()
        }
    }
    
    func didFailWithError(rewardedVideoAd: FBRewardedVideoAd, error: NSError) {
        if let onRewardedAdFailedToLoad = onRewardedAdFailedToLoad {
            onRewardedAdFailedToLoad(error)
        }
    }
    
    func rewardedVideoAdDidClick(rewardedVideoAd: FBRewardedVideoAd) {
        if let onRewardedAdClicked = onRewardedAdClicked {
            onRewardedAdClicked()
        }
    }
    
    func rewardedVideoAdDidClose(rewardedVideoAd: FBRewardedVideoAd) {
        if let onRewardedAdDismissed = onRewardedAdDismissed {
            onRewardedAdDismissed()
        }
    }
    
    func rewardedVideoAdWillClose(rewardedVideoAd: FBRewardedVideoAd) {
        /// NO-OP
    }
    
    func rewardedVideoAdWillLogImpression(rewardedVideoAd: FBRewardedVideoAd) {
        if let onRewardedAdImpressed = onRewardedAdImpressed {
            onRewardedAdImpressed()
        }
    }
    
    func rewardedVideoAdVideoComplete(rewardedVideoAd: FBRewardedVideoAd) {
        if let onRewardedAdCompleted = onRewardedAdCompleted {
            onRewardedAdCompleted()
        }
    }
    
    func rewardedVideoAdServerRewardDidSucceed(rewardedVideoAd: FBRewardedVideoAd) {
        /// NO-OP
    }
    
    func rewardedVideoAdServerRewardDidFail(rewardedVideoAd: FBRewardedVideoAd) {
        /// NO-OP
    }
}
