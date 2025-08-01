// Copyright 2022-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import ChartboostMediationSDK
import FBAudienceNetwork
import Foundation

/// A list of externally configurable properties pertaining to the partner SDK that can be retrieved and set by publishers.
@objc public class MetaAudienceNetworkAdapterConfiguration: NSObject, PartnerAdapterConfiguration {
    /// The version of the partner SDK.
    @objc public static var partnerSDKVersion: String {
        FB_AD_SDK_VERSION
    }

    /// The version of the adapter.
    /// It should have either 5 or 6 digits separated by periods, where the first digit is Chartboost Mediation SDK's major version, the
    /// last digit is the adapter's build version, and intermediate digits are the partner SDK's version.
    /// Format: `<Chartboost Mediation major version>.<Partner major version>.<Partner minor version>.<Partner patch version>.
    /// <Partner build version>.<Adapter build version>` where `.<Partner build version>` is optional.
    @objc public static let adapterVersion = "5.6.20.0.0"

    /// The partner's unique identifier.
    @objc public static let partnerID = "facebook"

    /// The human-friendly partner name.
    @objc public static let partnerDisplayName = "Meta Audience Network"

    /// Optional list of placement IDs to pass into Meta Audience Network's initialization settings.
    /// Empty by default.
    @objc public static var placementIDs: [String] = [] {
        didSet {
            log("Placement IDs set to \(placementIDs)")
        }
    }

    /// Flag that can optionally be set to enable Meta Audience Network's test mode. Make sure to disable test mode in production.
    /// Disabled by default.
    @objc public static var testMode = false {
        didSet {
            if testMode {
                FBAdSettings.addTestDevice(FBAdSettings.testDeviceHash())
            } else {
                FBAdSettings.clearTestDevices()
            }
            log("Test mode set to \(testMode)")
        }
    }

    /// Flag that can optionally be set to enable Meta Audience Network's verbose logging.
    /// Disabled by default.
    @objc public static var verboseLogging = false {
        didSet {
            FBAdSettings.setLogLevel(verboseLogging ? .verbose : .log)
            log("Verbose logging set to \(verboseLogging)")
        }
    }
}
