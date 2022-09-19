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

/// The Helium Meta Audience Network adapter
final class MetaAudienceNetworkAdapter: ModularPartnerAdapter {
    /// Get the version of the Meta Audience Network SDK.
    let partnerSDKVersion = FB_AD_SDK_VERSION
    
    /// Get the version of the mediation adapter. To determine the version, use the following scheme to indicate compatibility:
    /// [Helium SDK Major Version].[Partner SDK Major Version].[Partner SDK Minor Version].[Partner SDK Patch Version].[Adapter Version]
    ///
    /// For example, if this adapter is compatible with Helium SDK 4.x.y and partner SDK 1.0.0, and this is its initial release, then its version should be 4.1.0.0.0.
    let adapterVersion = "4.6.9.0.0"
    
    /// Get the internal name of the partner.
    let partnerIdentifier = "facebook"
    
    /// Get the external/official name of the partner.
    let partnerDisplayName = "Meta Audience Network"
    
    /// CCPA signal representing limited data usage in the case consent has not been given.
    let limitedDataUsageVal = "LDU"
    
    /// Storage of adapter instances.  Keyed by the request identifier.
    var adAdapters: [String: PartnerAdAdapter] = [:]
    
    /// Override this method to initialize the Meta Audience Network SDK so that it's ready to request and display ads.
    /// - Parameters:
    ///   - configuration: The necessary initialization data provided by Helium.
    ///   - completion: Handler to notify Helium of task completion.
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
    
    /// Override this method to compute and return a bid token for the bid request.
    /// - Parameters:
    ///   - request: The necessary data associated with the current bid request.
    ///   - completion: Handler to notify Helium of task completion.
    func fetchBidderInformation(request: PreBidRequest, completion: @escaping ([String : String]) -> Void) {
        log(.fetchBidderInfoStarted(request))
        
        let bidderToken = FBAdSettings.bidderToken
        log(bidderToken.isEmpty ? .fetchBidderInfoFailed(request, error: error(.fetchBidderInfoFailure(request))) : .fetchBidderInfoSucceeded(request))
        
        completion(["buyeruid": bidderToken])
    }
    
    /// Override this method to notify your partner SDK of GDPR applicability as determined by the Helium SDK.
    /// - Parameter applies: true if GDPR applies, false otherwise.
    func setGDPRApplies(_ applies: Bool) {
        /// NO-OP. Meta Audience Network automatically handles GDPR.
    }
    
    /// Override this method to notify your partner SDK of the GDPR consent status as determined by the Helium SDK.
    /// - Parameter status: The user's current GDPR consent status.
    func setGDPRConsentStatus(_ status: GDPRConsentStatus) {
        /// NO-OP. Meta Audience Network automatically handles GDPR.
    }
    
    /// Override this method to notify your partner SDK of the COPPA subjectivity as determined by the Helium SDK.
    /// - Parameter isSubject: True if the user is subject to COPPA, false otherwise.
    func setUserSubjectToCOPPA(_ isSubject: Bool) {
        FBAdSettings.isMixedAudience = isSubject
    }
    
    /// Override this method to notify your partner SDK of the CCPA privacy String as supplied by the Helium SDK.
    /// - Parameters:
    ///   - hasGivenConsent: True if the user has given CCPA consent, false otherwise.
    ///   - privacyString: The CCPA privacy String.
    func setCCPAConsent(hasGivenConsent: Bool, privacyString: String?) {
        /// If CCPA consent has been given, send an empty Array. Otherwise, the Array must contain the String "LDU".
        /// By setting country and state to values of 0, this instructs Meta Audience Network  to perform the geolocation themselves.
        /// https://developers.facebook.com/docs/audience-network/support/faq/ccpa
        FBAdSettings.setDataProcessingOptions(hasGivenConsent ? [] : [limitedDataUsageVal], country: 0, state: 0)
    }
    
    func makeAdAdapter(request: PartnerAdLoadRequest, partnerAdDelegate: PartnerAdDelegate) throws -> PartnerAdAdapter {
        MetaAudienceNetworkAdAdapter(adapter: self, request: request, partnerAdDelegate: partnerAdDelegate)
    }
}
