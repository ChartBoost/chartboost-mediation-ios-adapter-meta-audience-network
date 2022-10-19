//
//  MetaAudienceNetworkAdapter.swift
//  ChartboostHeliumAdapterMetaAudienceNetwork
//
//  Created by Vu Chau on 8/31/22.
//

import Foundation
import HeliumSdk
import UIKit
import FBAudienceNetwork

/// The Helium Meta Audience Network adapter.
final class MetaAudienceNetworkAdapter: PartnerAdapter {
    
    /// The version of the partner SDK.
    let partnerSDKVersion = FB_AD_SDK_VERSION
    
    /// The version of the adapter.
    /// The first digit is Helium SDK's major version. The last digit is the build version of the adapter. The intermediate digits correspond to the partner SDK version.
    let adapterVersion = "4.6.9.0.0"
    
    /// The partner's unique identifier.
    let partnerIdentifier = "facebook"
    
    /// The human-friendly partner name.
    let partnerDisplayName = "Meta Audience Network"
    
    /// The designated initializer for the adapter.
    /// Helium SDK will use this constructor to create instances of conforming types.
    /// - parameter storage: An object that exposes storage managed by the Helium SDK to the adapter.
    /// It includes a list of created `PartnerAd` instances. You may ignore this parameter if you don't need it.
    init(storage: PartnerAdapterStorage) {}
    
    /// Does any setup needed before beginning to load ads.
    /// - parameter configuration: Configuration data for the adapter to set up.
    /// - parameter completion: Closure to be performed by the adapter when it's done setting up. It should include an error indicating the cause for failure or `nil` if the operation finished successfully.
    func setUp(with configuration: PartnerConfiguration, completion: @escaping (Error?) -> Void) {
        log(.setUpStarted)
        let settings = FBAdInitSettings(placementIDs: [], mediationService: "Helium")
        
        FBAudienceNetworkAds.initialize(with: settings) { result in
            if (result.isSuccess) {
                self.log(.setUpSucceded)
                completion(nil)
            } else {
                let error = self.error(.setUpFailure, description: result.message)
                self.log(.setUpFailed(error))
                
                completion(error)
            }
        }
    }
    
    /// Fetches bidding tokens needed for the partner to participate in an auction.
    /// - parameter request: Information about the ad load request.
    /// - parameter completion: Closure to be performed with the fetched info.
    func fetchBidderInformation(request: PreBidRequest, completion: @escaping ([String : String]?) -> Void) {
        log(.fetchBidderInfoStarted(request))
        
        let bidderToken = FBAdSettings.bidderToken
        if bidderToken.isEmpty {
            log(.fetchBidderInfoFailed(request, error: error(.fetchBidderInfoFailure(request))))
        } else {
            log(.fetchBidderInfoSucceeded(request))
        }
        completion(["buyeruid": bidderToken])
    }
    
    /// Indicates if GDPR applies or not and the user's GDPR consent status.
    /// - parameter applies: `true` if GDPR applies, `false` if not, `nil` if the publisher has not provided this information.
    /// - parameter status: One of the `GDPRConsentStatus` values depending on the user's preference.
    func setGDPR(applies: Bool?, status: GDPRConsentStatus) {
        /// NO-OP. Meta Audience Network automatically handles GDPR.
    }
    
    /// Indicates if the user is subject to COPPA or not.
    /// - parameter isSubject: `true` if the user is subject, `false` otherwise.
    func setUserSubjectToCOPPA(_ isSubject: Bool) {
        FBAdSettings.isMixedAudience = isSubject
        log(.privacyUpdated(setting: "'isMixedAudience'", value: isSubject))
    }
    
    /// Indicates the CCPA status both as a boolean and as an IAB US privacy string.
    /// - parameter hasGivenConsent: A boolean indicating if the user has given consent.
    /// - parameter privacyString: An IAB-compliant string indicating the CCPA status.
    func setCCPAConsent(hasGivenConsent: Bool, privacyString: String?) {
        /// If CCPA consent has been given, send an empty Array. Otherwise, the Array must contain the String "LDU".
        /// By setting country and state to values of 0, this instructs Meta Audience Network  to perform the geolocation themselves.
        /// https://developers.facebook.com/docs/audience-network/support/faq/ccpa
        let dataProcessingOptions = hasGivenConsent ? [] : [String.limitedDataUsage]
        FBAdSettings.setDataProcessingOptions(dataProcessingOptions, country: 0, state: 0)
        log(.privacyUpdated(setting: "dataProcessingOptions", value: dataProcessingOptions))
    }
    
    /// Creates a new ad object in charge of communicating with a single partner SDK ad instance.
    /// Helium SDK calls this method to create a new ad for each new load request. Ad instances are never reused.
    /// Helium SDK takes care of storing and disposing of ad instances so you don't need to.
    /// `invalidate()` is called on ads before disposing of them in case partners need to perform any custom logic before the object gets destroyed.
    /// If, for some reason, a new ad cannot be provided, an error should be thrown.
    /// - parameter request: Information about the ad load request.
    /// - parameter delegate: The delegate that will receive ad life-cycle notifications.
    func makeAd(request: PartnerAdLoadRequest, delegate: PartnerAdDelegate) throws -> PartnerAd {
        switch request.format {
        case .interstitial:
            return MetaAudienceNetworkAdapterInterstitialAd(adapter: self, request: request, delegate: delegate)
        case .rewarded:
            return MetaAudienceNetworkAdapterRewardedAd(adapter: self, request: request, delegate: delegate)
        case .banner:
            return MetaAudienceNetworkAdapterBannerAd(adapter: self, request: request, delegate: delegate)
        }
    }
}

private extension String {
    /// CCPA signal representing limited data usage in the case consent has not been given.
    static let limitedDataUsage = "LDU"
}
