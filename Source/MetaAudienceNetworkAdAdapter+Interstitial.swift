//
//  MetaAudienceNetworkAdAdapter+Interstitial.swift
//  ChartboostHeliumAdapterMetaAudienceNetwork
//
//  Created by Vu Chau on 8/31/22.
//

import Foundation
import FBAudienceNetwork
import HeliumSdk

/// Collection of interstitial-sepcific API implementations
extension MetaAudienceNetworkAdAdapter: FBInterstitialAdDelegate {
    /// Attempt to load an interstitial ad.
    /// - Parameters:
    ///   - request: The relevant data associated with the current ad load call.
    func loadInterstitialAd(request: AdLoadRequest) {
        /// Because Meta Audience Network is bidding-only, validate the bid payload and fail early if it is empty.
        guard let bidPayload = request.adm, !bidPayload.isEmpty else {
            loadCompletion?(.failure(self.error(.noBidPayload(placement: request.partnerPlacement))))
            return
        }
        
        let ad = FBInterstitialAd.init(placementID: request.partnerPlacement)
        partnerAd = PartnerAd(ad: ad, details: [:], request: request)
        
        ad.delegate = self
        ad.load(withBidPayload: bidPayload)
    }
    
    /// Attempt to show the currently loaded interstitial ad.
    /// - Parameter viewController: The ViewController for ad presentation purposes.
    /// - Returns: A Result<PartnerAd, Error> indicating the success or failure of the show call.
    func showInterstitialAd(viewController: UIViewController) -> Result<PartnerAd, Error> {
        if let ad = partnerAd.ad as? FBInterstitialAd {
            if (ad.isAdValid) {
                ad.show(fromRootViewController: viewController)
                return .success(partnerAd)
            } else {
                return .failure(error(.showFailure(placement: partnerAd.request.partnerPlacement), description: "Ad is invalid."))
            }
        } else {
            return .failure(error(.showFailure(placement: partnerAd.request.partnerPlacement), description: "Ad instance is nil/not a FBInterstitialAd."))
        }
    }
    
    // MARK: - FBInterstitialAdDelegate
    
    func interstitialAdDidLoad(_ interstitialAd: FBInterstitialAd) {
        loadCompletion?(.success(partnerAd)) ?? log(.loadIgnored)
    }
    
    func didFailWithError(interstitialAd: FBInterstitialAd, error: NSError) {
        loadCompletion?(.failure(self.error(.loadFailure(placement: request.partnerPlacement), error: error))) ?? log(.loadIgnored)
    }
    
    func interstitialAdDidClick(_ interstitialAd: FBInterstitialAd) {
        partnerAdDelegate?.didClick(partnerAd) ?? log(.delegateUnavailable)
    }
    
    func interstitialAdDidClose(_ interstitialAd: FBInterstitialAd) {
        partnerAdDelegate?.didDismiss(partnerAd, error: nil) ?? log(.delegateUnavailable)
    }
    
    func interstitialAdWillClose(_ interstitialAd: FBInterstitialAd) {
        log("interstitialAdWillClose")
    }
    
    func interstitialAdWillLogImpression(_ interstitialAd: FBInterstitialAd) {
        partnerAdDelegate?.didTrackImpression(partnerAd) ?? log(.delegateUnavailable)
    }
}
