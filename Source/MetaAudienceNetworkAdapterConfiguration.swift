//
//  MetaAudienceNetworkAdapterConfiguration.swift
//  ChartboostHeliumAdapterMetaAudienceNetwork
//
//  Created by Vu Chau on 8/31/22.
//

import Foundation
import FBAudienceNetwork

/// A list of externally configurable properties pertaining to the partner SDK that can be retrieved and set by publishers.
@objc public class MetaAudienceNetworkAdapterConfiguration: NSObject {
    
    /// Flag that can optionally be set to enable Meta Audience Network's test mode. Make sure to disable test mode in production.
    /// Disabled by default.
    @objc public static var testMode: Bool = false {
        didSet {
            if testMode {
                FBAdSettings.addTestDevice(FBAdSettings.testDeviceHash())
            } else {
                FBAdSettings.clearTestDevices()
            }
            print("Meta Audience Network SDK test mode set to \(testMode)")
        }
    }
    
    /// Flag that can optionally be set to enable Meta Audience Network's verbose logging.
    /// Disabled by default.
    @objc public static var verboseLogging: Bool = false {
        didSet {
            FBAdSettings.setLogLevel(verboseLogging ? .verbose : .log)
            print("Meta Audience Network SDK verbose logging set to \(verboseLogging)")
        }
    }
}
