// Copyright 2022-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import AdSupport
import AppTrackingTransparency
import ChartboostMediationSDK
import FBAudienceNetwork
import Foundation
import UIKit

/// The Chartboost Mediation Meta Audience Network adapter.
final class MetaAudienceNetworkAdapter: PartnerAdapter {
    
    /// The version of the partner SDK.
    var partnerSDKVersion: String {
        MetaAudienceNetworkAdapterConfiguration.partnerSDKVersion
    }

    /// The version of the adapter.
    /// It should have either 5 or 6 digits separated by periods, where the first digit is Chartboost Mediation SDK's major version, the last digit is the adapter's build version, and intermediate digits are the partner SDK's version.
    /// Format: `<Chartboost Mediation major version>.<Partner major version>.<Partner minor version>.<Partner patch version>.<Partner build version>.<Adapter build version>` where `.<Partner build version>` is optional.
    var adapterVersion: String {
        MetaAudienceNetworkAdapterConfiguration.adapterVersion
    }

    /// The partner's unique identifier.
    var partnerID: String {
        MetaAudienceNetworkAdapterConfiguration.partnerID
    }

    /// The human-friendly partner name.
    var partnerDisplayName: String {
        MetaAudienceNetworkAdapterConfiguration.partnerDisplayName
    }

    /// The designated initializer for the adapter.
    /// Chartboost Mediation SDK will use this constructor to create instances of conforming types.
    /// - parameter storage: An object that exposes storage managed by the Chartboost Mediation SDK to the adapter.
    /// It includes a list of created `PartnerAd` instances. You may ignore this parameter if you don't need it.
    init(storage: PartnerAdapterStorage) {}
    
    /// Does any setup needed before beginning to load ads.
    /// - parameter configuration: Configuration data for the adapter to set up.
    /// - parameter completion: Closure to be performed by the adapter when it's done setting up. It should include an error indicating the cause for failure or `nil` if the operation finished successfully.
    func setUp(with configuration: PartnerConfiguration, completion: @escaping (Result<PartnerDetails, Error>) -> Void) {
        log(.setUpStarted)
        
        // Apply App Tracking Transparency setting
        // Documentation at: https://developers.facebook.com/docs/app-events/guides/advertising-tracking-enabled
        let isTrackingEnabled: Bool
        if #available(iOS 14, *) {
            // ATT only available in iOS 14+
            isTrackingEnabled = ATTrackingManager.trackingAuthorizationStatus == .authorized
        }
        else {
            isTrackingEnabled = ASIdentifierManager.shared().isAdvertisingTrackingEnabled
        }
        FBAdSettings.setAdvertiserTrackingEnabled(isTrackingEnabled)
        log(.privacyUpdated(setting: "advertiserTrackingEnabled", value: isTrackingEnabled))
        
        let settings = FBAdInitSettings(
            placementIDs: MetaAudienceNetworkAdapterConfiguration.placementIDs,
            mediationService: "Chartboost"
        )

        FBAudienceNetworkAds.initialize(with: settings) { result in
            if (result.isSuccess) {
                self.log(.setUpSucceded)
                completion(.success([:]))
            } else {
                let error = self.error(.initializationFailureUnknown, description: result.message)
                self.log(.setUpFailed(error))
                completion(.failure(error))
            }
        }
    }
    
    /// Fetches bidding tokens needed for the partner to participate in an auction.
    /// - parameter request: Information about the ad load request.
    /// - parameter completion: Closure to be performed with the fetched info.
    func fetchBidderInformation(request: PartnerAdPreBidRequest, completion: @escaping (Result<[String : String], Error>) -> Void) {
        log(.fetchBidderInfoStarted(request))
        let bidderToken = FBAdSettings.bidderToken
        log(.fetchBidderInfoSucceeded(request))
        completion(.success(bidderToken.isEmpty ? [:] : ["buyeruid": bidderToken]))
    }
    
    /// Indicates if GDPR applies or not and the user's GDPR consent status.
    /// - parameter applies: `true` if GDPR applies, `false` if not, `nil` if the publisher has not provided this information.
    /// - parameter status: One of the `GDPRConsentStatus` values depending on the user's preference.
    func setGDPR(applies: Bool?, status: GDPRConsentStatus) {
        /// NO-OP. Meta Audience Network automatically handles GDPR.
    }
    
    /// Indicates if the user is subject to COPPA or not.
    /// - parameter isChildDirected: `true` if the user is subject to COPPA, `false` otherwise.
    func setCOPPA(isChildDirected: Bool) {
        // See https://developers.facebook.com/docs/audience-network/optimization/best-practices/coppa
        FBAdSettings.isMixedAudience = isChildDirected
        log(.privacyUpdated(setting: "isMixedAudience", value: isChildDirected))
    }
    
    /// Indicates the CCPA status both as a boolean and as an IAB US privacy string.
    /// - parameter hasGivenConsent: A boolean indicating if the user has given consent.
    /// - parameter privacyString: An IAB-compliant string indicating the CCPA status.
    func setCCPA(hasGivenConsent: Bool, privacyString: String) {
        /// If CCPA consent has been given, send an empty Array. Otherwise, the Array must contain the String "LDU".
        /// By setting country and state to values of 0, this instructs Meta Audience Network  to perform the geolocation themselves.
        /// See https://developers.facebook.com/docs/audience-network/optimization/best-practices/ccpa
        let dataProcessingOptions = hasGivenConsent ? [] : [String.limitedDataUsage]
        FBAdSettings.setDataProcessingOptions(dataProcessingOptions, country: 0, state: 0)
        log(.privacyUpdated(setting: "dataProcessingOptions", value: dataProcessingOptions))
    }
    
    /// Creates a new banner ad object in charge of communicating with a single partner SDK ad instance.
    /// Chartboost Mediation SDK calls this method to create a new ad for each new load request. Ad instances are never reused.
    /// Chartboost Mediation SDK takes care of storing and disposing of ad instances so you don't need to.
    /// ``PartnerAd/invalidate()`` is called on ads before disposing of them in case partners need to perform any custom logic before the
    /// object gets destroyed.
    /// If, for some reason, a new ad cannot be provided, an error should be thrown.
    /// Chartboost Mediation SDK will always call this method from the main thread.
    /// - parameter request: Information about the ad load request.
    /// - parameter delegate: The delegate that will receive ad life-cycle notifications.
    func makeBannerAd(request: PartnerAdLoadRequest, delegate: PartnerAdDelegate) throws -> PartnerBannerAd {
        // This partner supports multiple loads for the same partner placement.
        MetaAudienceNetworkAdapterBannerAd(adapter: self, request: request, delegate: delegate)
    }

    /// Creates a new ad object in charge of communicating with a single partner SDK ad instance.
    /// Chartboost Mediation SDK calls this method to create a new ad for each new load request. Ad instances are never reused.
    /// Chartboost Mediation SDK takes care of storing and disposing of ad instances so you don't need to.
    /// ``PartnerAd/invalidate()`` is called on ads before disposing of them in case partners need to perform any custom logic before the
    /// object gets destroyed.
    /// If, for some reason, a new ad cannot be provided, an error should be thrown.
    /// - parameter request: Information about the ad load request.
    /// - parameter delegate: The delegate that will receive ad life-cycle notifications.
    func makeFullscreenAd(request: PartnerAdLoadRequest, delegate: PartnerAdDelegate) throws -> PartnerFullscreenAd {
        // This partner supports multiple loads for the same partner placement.
        switch request.format {
        case PartnerAdFormats.interstitial:
            return MetaAudienceNetworkAdapterInterstitialAd(adapter: self, request: request, delegate: delegate)
        case PartnerAdFormats.rewarded:
            return MetaAudienceNetworkAdapterRewardedAd(adapter: self, request: request, delegate: delegate)
        case PartnerAdFormats.rewardedInterstitial:
            return MetaAudienceNetworkAdapterRewardedInterstitialAd(adapter: self, request: request, delegate: delegate)
        default:
            throw error(.loadFailureUnsupportedAdFormat)
        }
    }
}

private extension String {
    /// CCPA signal representing limited data usage in the case consent has not been given.
    static let limitedDataUsage = "LDU"
}
