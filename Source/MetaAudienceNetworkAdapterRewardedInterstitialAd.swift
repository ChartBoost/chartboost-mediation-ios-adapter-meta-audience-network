// Copyright 2022-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import ChartboostMediationSDK
import FBAudienceNetwork
import Foundation

/// The Chartboost Mediation Meta Audience Network adapter rewarded interstitial ad.
final class MetaAudienceNetworkAdapterRewardedInterstitialAd: MetaAudienceNetworkAdapterAd, PartnerFullscreenAd {
    
    /// The Meta Audience Network SDK ad instance.
    private var ad: FBRewardedInterstitialAd?

    /// Loads an ad.
    /// - parameter viewController: The view controller on which the ad will be presented on. Needed on load for some banners.
    /// - parameter completion: Closure to be performed once the ad has been loaded.
    func load(with viewController: UIViewController?, completion: @escaping (Result<PartnerDetails, Error>) -> Void) {
        log(.loadStarted)
        
        /// Because Meta Audience Network is bidding-only, validate the bid payload and fail early if it is empty.
        guard let bidPayload = request.adm, !bidPayload.isEmpty else {
            let error = error(.loadFailureInvalidAdMarkup)
            log(.loadFailed(error))
            return completion(.failure(error))
        }
        
        loadCompletion = completion
        
        let ad = FBRewardedInterstitialAd(placementID: request.partnerPlacement)
        self.ad = ad
        ad.delegate = self
        DispatchQueue.main.async {
            ad.load(withBidPayload: bidPayload)
        }
    }
    
    /// Shows a loaded ad.
    /// Chartboost Mediation SDK will always call this method from the main thread.
    /// - parameter viewController: The view controller on which the ad will be presented on.
    /// - parameter completion: Closure to be performed once the ad has been shown.
    func show(with viewController: UIViewController, completion: @escaping (Result<PartnerDetails, Error>) -> Void) {
        log(.showStarted)
        if let ad = ad, ad.isAdValid {
            ad.show(fromRootViewController: viewController, animated: true)
            log(.showSucceeded)
            completion(.success([:]))
        } else {
            let error = error(.showFailureAdNotReady)
            log(.showFailed(error))
            completion(.failure(error))
        }
    }
}

// MARK: - FBRewardedVideoAdDelegate

extension MetaAudienceNetworkAdapterRewardedInterstitialAd: FBRewardedInterstitialAdDelegate {
    
    func rewardedInterstitialAdDidLoad(_ rewardedInterstitialAd: FBRewardedInterstitialAd) {
        log(.loadSucceeded)
        loadCompletion?(.success([:])) ?? log(.loadResultIgnored)
        loadCompletion = nil
    }
    
    func rewardedInterstitialAd(_ rewardedInterstitialAd: FBRewardedInterstitialAd, didFailWithError error: Error) {
        log(.loadFailed(error))
        loadCompletion?(.failure(error)) ?? log(.loadResultIgnored)
        loadCompletion = nil
    }
    
    func rewardedInterstitialAdDidClick(_ rewardedInterstitialAd: FBRewardedInterstitialAd) {
        log(.didClick(error: nil))
        delegate?.didClick(self, details: [:]) ?? log(.delegateUnavailable)
    }
    
    func rewardedInterstitialAdDidClose(_ rewardedInterstitialAd: FBRewardedInterstitialAd) {
        log(.didDismiss(error: nil))
        delegate?.didDismiss(self, details: [:], error: nil) ?? log(.delegateUnavailable)
    }
    
    func rewardedInterstitialAdWillClose(_ rewardedInterstitialAd: FBRewardedInterstitialAd) {
        log(.delegateCallIgnored)
    }
    
    func rewardedInterstitialAdWillLogImpression(_ rewardedInterstitialAd: FBRewardedInterstitialAd) {
        log(.didTrackImpression)
        delegate?.didTrackImpression(self, details: [:]) ?? log(.delegateUnavailable)
    }
    
    func rewardedInterstitialAdVideoComplete(_ rewardedInterstitialAd: FBRewardedInterstitialAd) {
        log(.didReward)
        delegate?.didReward(self, details: [:]) ?? log(.delegateUnavailable)
    }
}
