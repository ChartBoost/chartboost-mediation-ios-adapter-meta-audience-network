// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
import FBAudienceNetwork
import os.log

/// A list of externally configurable properties pertaining to the partner SDK that can be retrieved and set by publishers.
@objc public class MetaAudienceNetworkAdapterConfiguration: NSObject {

    private static var log = OSLog(subsystem: "com.chartboost.mediation.adapter.facebook", category: "Configuration")

    /// Flag that can optionally be set to enable Meta Audience Network's test mode. Make sure to disable test mode in production.
    /// Disabled by default.
    @objc public static var testMode: Bool = false {
        didSet {
            if testMode {
                FBAdSettings.addTestDevice(FBAdSettings.testDeviceHash())
            } else {
                FBAdSettings.clearTestDevices()
            }
            if #available(iOS 12.0, *) {
                os_log(.debug, log: log, "Meta Audience Network SDK test mode set to %{public}s", testMode ? "true" : "false")
            }
        }
    }
    
    /// Flag that can optionally be set to enable Meta Audience Network's verbose logging.
    /// Disabled by default.
    @objc public static var verboseLogging: Bool = false {
        didSet {
            FBAdSettings.setLogLevel(verboseLogging ? .verbose : .log)
            if #available(iOS 12.0, *) {
                os_log(.debug, log: log, "Meta Audience Network SDK verbose logging set to %{public}s", verboseLogging ? "true" : "false")
            }
        }
    }
}
