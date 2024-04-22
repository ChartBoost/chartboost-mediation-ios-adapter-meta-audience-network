// Copyright 2022-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import ChartboostMediationSDK
import FBAudienceNetwork
import Foundation

/// The Chartboost Mediation Meta Audience Network adapter banner ad.
final class MetaAudienceNetworkAdapterBannerAd: MetaAudienceNetworkAdapterAd, PartnerBannerAd {
    /// The partner banner ad view to display.
    var view: UIView? { ad }

    /// The loaded partner ad banner size.
    var size: PartnerBannerSize?

    /// The Meta Audience Network SDK ad instance.
    private var ad: FBAdView?

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

        // Fail if we cannot fit a fixed size banner in the requested size.
        guard let (loadedSize, partnerSize) = fixedBannerSize(for: request.bannerSize) else {
            let error = error(.loadFailureInvalidBannerSize)
            log(.loadFailed(error))
            return completion(.failure(error))
        }
        
        size = PartnerBannerSize(size: loadedSize, type: .fixed)
        loadCompletion = completion

        let ad = FBAdView(
            placementID: request.partnerPlacement,
            adSize: partnerSize,
            rootViewController: viewController
        )
        self.ad = ad
        ad.delegate = self
        ad.frame = CGRect(origin: .zero, size: partnerSize.size)
        DispatchQueue.main.async {
            ad.loadAd(withBidPayload: bidPayload)
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

// MARK: - Helpers
extension MetaAudienceNetworkAdapterBannerAd {
    private func fixedBannerSize(for requestedSize: BannerSize?) -> (size: CGSize, partnerSize: FBAdSize)? {
        guard let requestedSize else {
            return (IABStandardAdSize, kFBAdSizeHeight50Banner)
        }
        let sizes: [(size: CGSize, partnerSize: FBAdSize)] = [
            (size: IABLeaderboardAdSize, partnerSize: kFBAdSizeHeight90Banner),
            (size: IABMediumAdSize, partnerSize: kFBAdSizeHeight250Rectangle),
            (size: IABStandardAdSize, partnerSize: kFBAdSizeHeight50Banner)
        ]
        // Find the largest size that can fit in the requested size.
        for (size, partnerSize) in sizes {
            // If height is 0, the pub has requested an ad of any height, so only the width matters.
            if requestedSize.size.width >= size.width &&
                (size.height == 0 || requestedSize.size.height >= size.height) {
                return (size, partnerSize)
            }
        }
        // The requested size cannot fit any fixed size banners.
        return nil
    }
}
