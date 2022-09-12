//
//  MetaAudienceNetworkAdapterConfiguration.swift
//  ChartboostHeliumAdapterMetaAudienceNetwork
//
//  Created by Vu Chau on 8/31/22.
//

import Foundation
import FBAudienceNetwork

/// A list of externally configurable properties pertaining to the partner SDK that can be retrieved and set by publishers.
public class MetaAudienceNetworkAdapterConfiguration {
    /// Flag that can optionally be set to enable Meta Audience Network's test mode. Make sure to disable test mode in production.
    /// Disabled by default.
    private static var _testMode = false
    public static var testMode: Bool {
        get {
            return _testMode
        }
        set {
            _testMode = newValue
            
            if (_testMode) {
                FBAdSettings.addTestDevice(FBAdSettings.testDeviceHash())
            } else {
                FBAdSettings.clearTestDevices()
            }
            
            print("The Meta Audience Network SDK's test mode is \(_testMode ? "enabled" : "disabled").")
        }
    }
    
    /// Flag that can optionally be set to enable Meta Audience Network's verbose logging.
    /// Disabled by default.
    private static var _verboseLogging = false
    public static var verboseLogging: Bool {
        get {
            return _verboseLogging
        }
        set {
            _verboseLogging = newValue
            
            if (_verboseLogging) {
                FBAdSettings.setLogLevel(FBAdLogLevel.verbose)
            } else {
                FBAdSettings.setLogLevel(FBAdLogLevel.log)
            }
            
            print("The Meta Audience Network SDK's verbose logging is \(_verboseLogging ? "enabled" : "disabled").")
        }
    }
}
