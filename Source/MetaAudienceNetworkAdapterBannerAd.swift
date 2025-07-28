// Copyright 2022-2025 Chartboost, Inc.
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
    func load(with viewController: UIViewController?, completion: @escaping (Error?) -> Void) {
        log(.loadStarted)

        // Because Meta Audience Network is bidding-only, validate the bid payload and fail early if it is empty.
        guard let bidPayload = request.adm, !bidPayload.isEmpty else {
            let error = error(.loadFailureInvalidAdMarkup)
            log(.loadFailed(error))
            completion(error)
            return
        }

        // Fail if we cannot fit a fixed size banner in the requested size.
        guard
            let requestedSize = request.bannerSize,
            let fittingSize = BannerSize.largestStandardFixedSizeThatFits(in: requestedSize),
            let fbSize = fittingSize.fbAdSize
        else {
            let error = error(.loadFailureInvalidBannerSize)
            log(.loadFailed(error))
            completion(error)
            return
        }

        size = PartnerBannerSize(size: fittingSize.size, type: .fixed)
        loadCompletion = completion

        let ad = FBAdView(
            placementID: request.partnerPlacement,
            adSize: fbSize,
            rootViewController: viewController
        )
        self.ad = ad
        ad.delegate = self
        ad.frame = CGRect(origin: .zero, size: fbSize.size)
        DispatchQueue.main.async {
            ad.loadAd(withBidPayload: bidPayload)
        }
    }
}

// MARK: - FBAdViewDelegate

extension MetaAudienceNetworkAdapterBannerAd: FBAdViewDelegate {
    func adViewDidLoad(_ adView: FBAdView) {
        log(.loadSucceeded)
        loadCompletion?(nil) ?? log(.loadResultIgnored)
        loadCompletion = nil
    }

    func adView(_ adView: FBAdView, didFailWithError error: Error) {
        log(.loadFailed(error))
        loadCompletion?(error) ?? log(.loadResultIgnored)
        loadCompletion = nil
    }

    func adViewWillLogImpression(_ adView: FBAdView) {
        log(.didTrackImpression)
        delegate?.didTrackImpression(self) ?? log(.delegateUnavailable)
    }

    func adViewDidClick(_ adView: FBAdView) {
        log(.didClick(error: nil))
        delegate?.didClick(self) ?? log(.delegateUnavailable)
    }
}

extension BannerSize {
    fileprivate var fbAdSize: FBAdSize? {
        switch self {
        case .standard:
            kFBAdSizeHeight50Banner
        case .medium:
            kFBAdSizeHeight250Rectangle
        case .leaderboard:
            kFBAdSizeHeight90Banner
        default:
            nil
        }
    }
}
