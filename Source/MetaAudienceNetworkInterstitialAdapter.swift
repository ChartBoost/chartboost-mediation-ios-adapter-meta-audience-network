//
//  MetaAudienceNetworkInterstitialAdapter.swift
//  ChartboostHeliumAdapterMetaAudienceNetwork
//
//  Created by Vu Chau on 8/31/22.
//

import Foundation
import HeliumSdk
import FBAudienceNetwork

/// Closure for notifying Helium of an ad load event
var onInterstitialLoaded: (() -> Void)?

/// Closure for notifying Helium of an ad load failure event
var onInterstitialFailedToLoad: ((_ error: NSError) -> Void)?

/// Closure for notifying Helium of an ad impression event
var onInterstitialImpressed: (() -> Void)?

/// Closure for notifying Helium of an ad click event
var onInterstitialClicked: (() -> Void)?

/// Closure for notifying Helium of an ad dismiss event
var onInterstitialDismissed: (() -> Void)?

/// Meta Audience Network adapter's interstitial-specific API implementations
extension MetaAudienceNetworkAdapter {
    /// Attempt to load an interstitial ad.
    /// - Parameters:
    ///   - request: The relevant data associated with the current ad load call.
    ///   - partnerAdDelegate: Delegate for ad lifecycle notification purposes.
    ///   - completion: Handler to notify Helium of task completion.
    func loadInterstitialAd(request: AdLoadRequest, partnerAdDelegate: PartnerAdDelegate, completion: @escaping (Result<PartnerAd, Error>) -> Void) {
        /// Because Meta Audience Network is bidding-only, validate the bid payload and fail early if it is empty.
        guard let bidPayload = request.adm, !bidPayload.isEmpty else {
            completion(.failure(error(.loadFailure(placement: request.partnerPlacement),
                                      description: "\(partnerDisplayName) failed to load the \(request.format) ad because the ad markup is nil/empty.",
                                      error: nil)))
            return
        }
        
        /// Since fullscreen ads require a load-show paradigm, persist the delegate so it can be retrieved at show time.
        delegates[request.heliumPlacement] = partnerAdDelegate
        
        let ad = FBInterstitialAd.init(placementID: request.partnerPlacement)
        ad.delegate = self
        ad.load(withBidPayload: bidPayload)
        
        onInterstitialLoaded = {
            completion(.success(PartnerAd(ad: ad, details: [:], request: request)))
        }
        
        onInterstitialFailedToLoad = { error in
            completion(.failure(self.error(.loadFailure(placement: request.partnerPlacement),
                                           description: "\(self.partnerDisplayName) failed to load the \(request.format) ad.",
                                           error: error)))
        }
        
    }
    
    /// Attempt to show the currently loaded interstitial ad.
    /// - Parameters:
    ///   - partnerAd: The PartnerAd instance containing the ad to be shown.
    ///   - completion: Handler to notify Helium of task completion.
    func showInterstitialAd(partnerAd: PartnerAd,
                            viewController: UIViewController,
                            completion: @escaping (Result<PartnerAd, Error>) -> Void) {
        let delegate = delegates[partnerAd.request.heliumPlacement]
        
        if let ad = partnerAd.ad as? FBInterstitialAd {
            if (ad.isAdValid) {
                ad.show(fromRootViewController: viewController)
                
                onInterstitialImpressed = {
                    self.log(.didTrackImpression(partnerAd))
                    delegate?.didTrackImpression(partnerAd) ?? self.log("Unable to notify didTrackImpression for the \(self.partnerDisplayName) adapter. Delegate is nil.")
                    completion(.success(partnerAd))
                }
                
                onInterstitialClicked = {
                    self.log(.didClick(partnerAd, partnerError: nil))
                    delegate?.didClick(partnerAd) ?? self.log("Unable to notify didClick for the \(self.partnerDisplayName) adapter. Delegate is nil.")
                }
                
                onInterstitialDismissed = {
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
                                      description: "\(partnerDisplayName) failed to show the \(partnerAd.request.format) ad. Ad instance is nil or not a FBInterstitialAd.",
                                      error: nil)))
        }
    }
    
    /// Attempt to destroy the current interstitial ad.
    /// - Parameters:
    ///   - partnerAd: The PartnerAd instance containing the ad to be invalidated.
    ///   - completion: Handler to notify Helium of task completion.
    func destroyInterstitialAd(partnerAd: PartnerAd,
                               completion: @escaping (Result<PartnerAd, Error>) -> Void) {
        if let ad = partnerAd.ad as? FBInterstitialAd {
            delegates.removeAll()
            ad.delegate = nil
            completion(.success(partnerAd))
        } else {
            completion(.failure(error(.invalidateFailure(placement: partnerAd.request.heliumPlacement),
                                      description: "\(partnerDisplayName) failed to invalidate the \(partnerAd.request.format) ad. Ad instance is nil or not a FBInterstitialAd.",
                                      error: nil)))
        }
    }
    
    // MARK: - FBInterstitialAdDelegate
    
    func interstitialAdDidLoad(interstitialAd: FBInterstitialAd) {
        if let onInterstitialLoaded = onInterstitialLoaded {
            onInterstitialLoaded()
        }
        
    }
    
    func didFailWithError(interstitialAd: FBInterstitialAd, error: NSError) {
        if let onInterstitialFailedToLoad = onInterstitialFailedToLoad {
            onInterstitialFailedToLoad(error)
        }
    }
    
    func interstitialAdDidClick(interstitialAd: FBInterstitialAd) {
        if let onInterstitialClicked = onInterstitialClicked {
            onInterstitialClicked()
        }
    }
    
    func interstitialAdDidClose(interstitialAd: FBInterstitialAd) {
        if let onInterstitialDismissed = onInterstitialDismissed {
            onInterstitialDismissed()
        }
    }
    
    func interstitialAdWillClose(interstitialAd: FBInterstitialAd) {
        /// NO-OP
    }
    
    func interstitialAdWillLogImpression(interstitialAd: FBInterstitialAd) {
        if let onInterstitialImpressed = onInterstitialImpressed {
            onInterstitialImpressed()
        }
    }
}
