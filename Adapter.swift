//
//  Adapter.swift
//  ChartboostHeliumAdapterMetaAudienceNetwork
//
//  Created by Vu Chau on 8/31/22.
//

import Foundation
import FBAudienceNetwork
import HeliumSdk

final class Adapter: NSObject, PartnerLogger, PartnerErrorFactory {
    /// The current adapter instance
    let adapter: PartnerAdapter
    
    /// The current AdLoadRequest containing data relevant to the curent ad request
    let request: AdLoadRequest
    
    /// A PartnerAd object with a placeholder (nil) ad object.
    lazy var partnerAd = PartnerAd(ad: nil, details: [:], request: request)
    
    /// The partner ad delegate to send ad life-cycle events to.
    weak var partnerAdDelegate: PartnerAdDelegate?
    
    /// The completion for the ongoing load operation.
    var loadCompletion: ((Result<PartnerAd, Error>) -> Void)?
    
    /// The completion for the ongoing show operation.
    var showCompletion: ((Result<PartnerAd, Error>) -> Void)?
    
    init(adapter: PartnerAdapter, request: AdLoadRequest, partnerAdDelegate: PartnerAdDelegate) {
        self.request = request
        self.partnerAdDelegate = partnerAdDelegate
        super.init()
    }
    
    func load(viewController: UIViewController?, completion: @escaping (Result<PartnerAd, Error>) -> Void) {
        /// Persist the load completion handler for subsequent uses
        loadCompletion = completion
        
        switch request.format {
        case .banner:
            loadBannerAd(request: request,
                         viewController: viewController,
                         completion: { result in
                self.onLoadComplete(result: result, completion: completion)
            })
        case .interstitial:
            loadInterstitialAd(request: request,
                               completion: { result in
                self.onLoadComplete(result: result, completion: completion)
            })
        case .rewarded:
            loadRewardedAd(request: request,
                           completion: { result in
                self.onLoadComplete(result: result, completion: completion)
            })
        }
    }
    
    func show(viewController: UIViewController, completion: @escaping (Result<PartnerAd, Error>) -> Void) {
        /// Persist the show completion handler for subsequent uses
        showCompletion = completion
        
        switch request.format {
        case .banner:
            /// Banner does not have a separate show mechanism
            log(.showSucceeded(partnerAd))
            completion(.success(partnerAd))
        case .interstitial:
            showInterstitialAd(viewController: viewController,
                               completion: { result in
                self.onShowComplete(result: result, completion: completion)
            })
        case .rewarded:
            showRewardedAd(viewController: viewController,
                           completion: { result in
                self.onShowComplete(result: result, completion: completion)
            })
        }
    }
    
    func invalidate(completion: @escaping (Result<PartnerAd, Error>) -> Void) {
        switch request.format {
        case .banner:
            destroyBannerAd { result in
                self.onInvalidateComplete(result: result, completion: completion)
            }
        case .interstitial:
            destroyInterstitialAd { result in
                self.onInvalidateComplete(result: result, completion: completion)
            }
        case .rewarded:
            destroyRewardedAd{ result in
                self.onInvalidateComplete(result: result, completion: completion)
            }
        }
    }
    
    private func onLoadComplete(result: Result<PartnerAd, Error>, completion: @escaping (Result<PartnerAd, Error>) -> Void) {
        do {
            log(.loadSucceeded(try result.get()))
        } catch {
            log(.loadFailed(request, error: error))
        }
        
        completion(result)
    }
    
    private func onShowComplete(result: Result<PartnerAd, Error>, completion: @escaping (Result<PartnerAd, Error>) -> Void) {
        do {
            self.log(.showSucceeded(try result.get()))
        } catch {
            self.log(.showFailed(partnerAd, error: error))
        }
        
        completion(result)
    }
    
    private func onInvalidateComplete(result: Result<PartnerAd, Error>, completion: @escaping (Result<PartnerAd, Error>) -> Void) {
        do {
            self.log(.invalidateSucceeded(try result.get()))
        } catch {
            self.log(.invalidateFailed(partnerAd, error: error))
        }
        
        completion(result)
    }
}
