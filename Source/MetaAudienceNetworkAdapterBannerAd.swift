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
        guard let loadedSize = BannerSize.largestStandardFixedSizeThatFits(in: request.bannerSize ?? .standard) else {
            let error = error(.loadFailureInvalidBannerSize)
            log(.loadFailed(error))
            return completion(.failure(error))
        }
        
        let partnerSize = fbAdSize(from: loadedSize)
        size = PartnerBannerSize(size: loadedSize.size, type: .fixed)
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
    
    private func fbAdSize(from size: BannerSize) -> FBAdSize {
        switch size {
        case .standard:
            kFBAdSizeHeight50Banner
        case .medium:
            kFBAdSizeHeight250Rectangle
        case .leaderboard:
            kFBAdSizeHeight90Banner
        default:
            // largestStandardFixedSizeThatFits currently only returns .standard, .medium, or .leaderboard,
            // but if that changes then just default to .standard until this code gets updated.
            kFBAdSizeHeight50Banner
        }
    }

    private func fixedBannerSize(for requestedSize: BannerSize?) -> (size: CGSize, partnerSize: FBAdSize)? {
        // Return a default value if no size is specified
        guard let requestedSize else {

            return (BannerSize.standard.size, kFBAdSizeHeight50Banner)
        }

        // If we can find a size that fits, return that.
        if let size = BannerSize.largestStandardFixedSizeThatFits(in: requestedSize) {
            switch size {
            case .standard:
                return (BannerSize.standard.size, kFBAdSizeHeight50Banner)
            case .medium:
                return (BannerSize.medium.size, kFBAdSizeHeight250Rectangle)
            case .leaderboard:
                return (BannerSize.leaderboard.size, kFBAdSizeHeight90Banner)
            default:
                // largestStandardFixedSizeThatFits currently only returns .standard, .medium, or .leaderboard,
                // but if that changes then just default to .standard until this code gets updated.
                return (BannerSize.standard.size, kFBAdSizeHeight50Banner)
            }
        } else {
            // largestStandardFixedSizeThatFits has returned nil to indicate it couldn't find a fit.
            return nil
        }
    }
}
