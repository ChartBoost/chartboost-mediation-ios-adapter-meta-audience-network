//
//  MetaAudienceNetworkAdAdapter.swift
//  ChartboostHeliumAdapterMetaAudienceNetwork
//
//  Created by Vu Chau on 8/31/22.
//

import Foundation
import FBAudienceNetwork
import HeliumSdk
import UIKit

final class MetaAudienceNetworkAdAdapter: NSObject, PartnerLogger, PartnerErrorFactory {
    /// The current adapter instance
    let adapter: PartnerAdapter
    
    /// The current AdLoadRequest containing data relevant to the curent ad request
    let request: AdLoadRequest
    
    /// A PartnerAd object with a placeholder (nil) ad object.
    lazy var partnerAd = PartnerAd(ad: nil, details: [:], request: request)
    
    /// The partner ad delegate to send ad life-cycle events to.
    weak var partnerAdDelegate: PartnerAdDelegate?
    
    /// The completion handler to notify Helium of ad load completion result.
    var loadCompletion: ((Result<PartnerAd, Error>) -> Void)?
    
    /// Create a new instance of the adapter.
    /// - Parameters:
    ///   - adapter: The current adapter instance
    ///   - request: The current AdLoadRequest containing data relevant to the curent ad request
    ///   - partnerAdDelegate: The partner ad delegate to notify Helium of ad lifecycle events.
    init(adapter: PartnerAdapter, request: AdLoadRequest, partnerAdDelegate: PartnerAdDelegate) {
        self.adapter = adapter
        self.request = request
        self.partnerAdDelegate = partnerAdDelegate
        
        super.init()
    }
    
    /// Attempt to load an ad.
    /// - Parameters:
    ///   - viewController: The ViewController for ad presentation purposes.
    ///   - completion: The completion handler to notify Helium of ad load completion result.
    func load(viewController: UIViewController?, completion: @escaping (Result<PartnerAd, Error>) -> Void) {
        /// Update the load completion handler so it can be used to notify Helium when the partner fires its load delegate.
        loadCompletion = completion
        
        switch request.format {
        case .banner:
            loadBannerAd(viewController: viewController, request: request)
        case .interstitial:
            loadInterstitialAd(request: request)
        case .rewarded:
            loadRewardedAd(request: request)
        }
        
        loadCompletion = { result in
            do {
                self.log(.loadSucceeded(try result.get()))
            } catch {
                self.log(.loadFailed(self.request, error: error))
            }
            
            self.loadCompletion = nil
            completion(result)
        }
    }
    
    /// Attempt to show the currently loaded ad.
    /// - Parameters:
    ///   - viewController: The ViewController for ad presentation purposes.
    ///   - completion: The completion handler to notify Helium of ad show completion result.
    func show(viewController: UIViewController, completion: @escaping (Result<PartnerAd, Error>) -> Void) {
        switch request.format {
        case .banner:
            /// Banner does not have a separate show mechanism
            log(.showSucceeded(partnerAd))
            completion(.success(partnerAd))
        case .interstitial:
            completion(showInterstitialAd(viewController: viewController))
        case .rewarded:
            completion(showRewardedAd(viewController: viewController))
        }
    }
}
