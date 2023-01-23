// Copyright 2022-2023 Chartboost, Inc.
// 
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

//
//  MetaAudienceNetworkAdapterBannerAd.swift
//  ChartboostHeliumAdapterMetaAudienceNetwork
//
//  Created by Vu Chau on 8/31/22.
//

import Foundation
import FBAudienceNetwork
import HeliumSdk

/// The Helium Meta Audience Network adapter banner ad.
final class MetaAudienceNetworkAdapterBannerAd: MetaAudienceNetworkAdapterAd, PartnerAd {
    
    /// The Meta Audience Network SDK ad instance.
    private var ad: FBAdView?
    
    /// The partner ad view to display inline. E.g. a banner view.
    /// Should be nil for full-screen ads.
    var inlineView: UIView? { ad }
    
    /// Loads an ad.
    /// - parameter viewController: The view controller on which the ad will be presented on. Needed on load for some banners.
    /// - parameter completion: Closure to be performed once the ad has been loaded.
    func load(with viewController: UIViewController?, completion: @escaping (Result<PartnerEventDetails, Error>) -> Void) {
        log(.loadStarted)
        
        /// Because Meta Audience Network is bidding-only, validate the bid payload and fail early if it is empty.
        guard let bidPayload = request.adm, !bidPayload.isEmpty else {
            let error = error(.loadFailureInvalidAdMarkup)
            log(.loadFailed(error))
            return completion(.failure(error))
        }
        
        loadCompletion = completion
        
        let adSize = metaAudienceNetworkBannerAdSize(with: request.size)
        let ad = FBAdView(
            placementID: request.partnerPlacement,
            adSize: adSize,
            rootViewController: viewController
        )
        self.ad = ad
        ad.delegate = self
        ad.frame = CGRect(origin: .zero, size: adSize.size)
        DispatchQueue.main.async {
            ad.loadAd(withBidPayload: bidPayload)
        }
    }
    
    /// Shows a loaded ad.
    /// It will never get called for banner ads. You may leave the implementation blank for that ad format.
    /// - parameter viewController: The view controller on which the ad will be presented on.
    /// - parameter completion: Closure to be performed once the ad has been shown.
    func show(with viewController: UIViewController, completion: @escaping (Result<PartnerEventDetails, Error>) -> Void) {
        // no-op
    }
    
    /// Map Helium's banner sizes to the Meta Audience Network SDK's supported sizes.
    /// - Parameter size: The Helium's banner size.
    /// - Returns: The corresponding Meta Audience Network banner size.
    private func metaAudienceNetworkBannerAdSize(with size: CGSize?) -> FBAdSize {
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
}

// MARK: - FBAdViewDelegate

extension MetaAudienceNetworkAdapterBannerAd: FBAdViewDelegate {
    
    func adViewDidLoad(_ adView: FBAdView) {
        log(.loadSucceeded)
        loadCompletion?(.success([:])) ?? log(.loadResultIgnored)
        loadCompletion = nil
    }
    
    func adView(_ adView: FBAdView, didFailWithError error: Error) {
        log(.loadFailed(error))
        loadCompletion?(.failure(error)) ?? log(.loadResultIgnored)
        loadCompletion = nil
    }
    
    func adViewWillLogImpression(_ adView: FBAdView) {
        log(.didTrackImpression)
        delegate?.didTrackImpression(self, details: [:]) ?? log(.delegateUnavailable)
    }
    
    func adViewDidClick(_ adView: FBAdView) {
        log(.didClick(error: nil))
        delegate?.didClick(self, details: [:]) ?? log(.delegateUnavailable)
    }
}
