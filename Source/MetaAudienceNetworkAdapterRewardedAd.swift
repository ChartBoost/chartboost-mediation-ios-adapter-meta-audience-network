// Copyright 2022-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import ChartboostMediationSDK
import FBAudienceNetwork
import Foundation

/// The Chartboost Mediation Meta Audience Network adapter rewarded ad.
final class MetaAudienceNetworkAdapterRewardedAd: MetaAudienceNetworkAdapterAd, PartnerFullscreenAd {
    /// The Meta Audience Network SDK ad instance.
    private var ad: FBRewardedVideoAd?

    /// Loads an ad.
    /// - parameter viewController: The view controller on which the ad will be presented on. Needed on load for some banners.
    /// - parameter completion: Closure to be performed once the ad has been loaded.
    func load(with viewController: UIViewController?, completion: @escaping (Error?) -> Void) {
        log(.loadStarted)

        // Because Meta Audience Network is bidding-only, validate the bid payload and fail early if it is empty.
        guard let bidPayload = request.adm, !bidPayload.isEmpty else {
            let error = error(.loadFailureInvalidAdMarkup)
            log(.loadFailed(error))
            completion(error)
            return
        }

        loadCompletion = completion

        let ad = FBRewardedVideoAd(placementID: request.partnerPlacement)
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
    func show(with viewController: UIViewController, completion: @escaping (Error?) -> Void) {
        log(.showStarted)
        if let ad {
            if ad.isAdValid {
                ad.show(fromRootViewController: viewController)
                log(.showSucceeded)
                completion(nil)
            } else {
                let error = error(.showFailureUnknown, description: "Ad is invalid.")
                log(.showFailed(error))
                completion(error)
            }
        } else {
            let error = error(.showFailureAdNotReady)
            log(.showFailed(error))
            completion(error)
        }
    }
}

// MARK: - FBRewardedVideoAdDelegate

extension MetaAudienceNetworkAdapterRewardedAd: FBRewardedVideoAdDelegate {
    func rewardedVideoAdDidLoad(_ rewardedVideoAd: FBRewardedVideoAd) {
        log(.loadSucceeded)
        loadCompletion?(nil) ?? log(.loadResultIgnored)
        loadCompletion = nil
    }

    func rewardedVideoAd(_ rewardedVideoAd: FBRewardedVideoAd, didFailWithError error: Error) {
        log(.loadFailed(error))
        loadCompletion?(error) ?? log(.loadResultIgnored)
        loadCompletion = nil
    }

    func rewardedVideoAdDidClick(_ rewardedVideoAd: FBRewardedVideoAd) {
        log(.didClick(error: nil))
        delegate?.didClick(self) ?? log(.delegateUnavailable)
    }

    func rewardedVideoAdDidClose(_ rewardedVideoAd: FBRewardedVideoAd) {
        log(.didDismiss(error: nil))
        delegate?.didDismiss(self, error: nil) ?? log(.delegateUnavailable)
    }

    func rewardedVideoAdWillClose(_ rewardedVideoAd: FBRewardedVideoAd) {
        log(.delegateCallIgnored)
    }

    func rewardedVideoAdWillLogImpression(_ rewardedVideoAd: FBRewardedVideoAd) {
        log(.didTrackImpression)
        delegate?.didTrackImpression(self) ?? log(.delegateUnavailable)
    }

    func rewardedVideoAdVideoComplete(_ rewardedVideoAd: FBRewardedVideoAd) {
        log(.didReward)
        delegate?.didReward(self) ?? log(.delegateUnavailable)
    }

    func rewardedVideoAdServerRewardDidSucceed(_ rewardedVideoAd: FBRewardedVideoAd) {
        log(.delegateCallIgnored)
    }

    func rewardedVideoAdServerRewardDidFail(_ rewardedVideoAd: FBRewardedVideoAd) {
        log(.delegateCallIgnored)
    }
}
