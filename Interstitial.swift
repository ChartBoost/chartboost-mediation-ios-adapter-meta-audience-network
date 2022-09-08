//
//  Interstitial.swift
//  ChartboostHeliumAdapterMetaAudienceNetwork
//
//  Created by Vu Chau on 8/31/22.
//

import Foundation
import FBAudienceNetwork
import HeliumSdk

/// Collection of interstitial-sepcific API implementations
extension Adapter: FBInterstitialAdDelegate {
    /// Attempt to load an interstitial ad.
    /// - Parameters:
    ///   - request: The relevant data associated with the current ad load call.
    ///   - completion: Handler to notify Helium of task completion.
    func loadInterstitialAd(request: AdLoadRequest, completion: @escaping (Result<PartnerAd, Error>) -> Void) {
        /// Because Meta Audience Network is bidding-only, validate the bid payload and fail early if it is empty.
        guard let bidPayload = request.adm, !bidPayload.isEmpty else {
            completion(.failure(error(.loadFailure(placement: request.partnerPlacement), description: "The ad markup is nil/empty.")))
            return
        }
        
        let ad = FBInterstitialAd.init(placementID: request.partnerPlacement)
        ad.delegate = self
        ad.load(withBidPayload: bidPayload)
        
        partnerAd = PartnerAd(ad: ad, details: [:], request: request)
        
        loadCompletion = { result in
            completion(result)
        }
    }
    
    /// Attempt to show the currently loaded interstitial ad.
    /// - Parameters:
    ///   - viewController: The ViewController for ad presentation purposes.
    ///   - completion: Handler to notify Helium of task completion.
    func showInterstitialAd(viewController: UIViewController,
                            completion: @escaping (Result<PartnerAd, Error>) -> Void) {
        if let ad = partnerAd.ad as? FBInterstitialAd {
            if (ad.isAdValid) {
                ad.show(fromRootViewController: viewController)
                completion(.success(partnerAd))
            } else {
                completion(.failure(error(.showFailure(placement: partnerAd.request.partnerPlacement), description: "Ad is invalid.")))
            }
        } else {
            completion(.failure(error(.showFailure(placement: partnerAd.request.partnerPlacement), description: "Ad instance is nil/not a FBInterstitialAd.")))
        }
    }
    
    /// Attempt to destroy the current interstitial ad.
    /// - Parameters:
    ///   - completion: Handler to notify Helium of task completion.
    func destroyInterstitialAd(completion: @escaping (Result<PartnerAd, Error>) -> Void) {
        if let ad = partnerAd.ad as? FBInterstitialAd {
            ad.delegate = nil
            completion(.success(partnerAd))
        } else {
            completion(.failure(error(.invalidateFailure(placement: partnerAd.request.heliumPlacement), description: "Ad instance is nil/not a FBInterstitialAd.")))
        }
    }
    
    // MARK: - FBInterstitialAdDelegate
    
    func interstitialAdDidLoad(_ interstitialAd: FBInterstitialAd) {
        loadCompletion?(.success(partnerAd))
    }
    
    func didFailWithError(interstitialAd: FBInterstitialAd, error: NSError) {
        loadCompletion?(.failure(self.error(.loadFailure(placement: request.partnerPlacement), error: error)))
    }
    
    func interstitialAdDidClick(_ interstitialAd: FBInterstitialAd) {
        partnerAdDelegate?.didClick(partnerAd)
    }
    
    func interstitialAdDidClose(_ interstitialAd: FBInterstitialAd) {
        partnerAdDelegate?.didDismiss(partnerAd, error: nil)
    }
    
    func interstitialAdWillClose(_ interstitialAd: FBInterstitialAd) {
        /// NO-OP
    }
    
    func interstitialAdWillLogImpression(_ interstitialAd: FBInterstitialAd) {
        partnerAdDelegate?.didTrackImpression(partnerAd)
    }
}
