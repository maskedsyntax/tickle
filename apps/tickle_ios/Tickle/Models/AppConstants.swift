import Foundation

enum AppConstants {
    static let appBundleID = "com.maskedsyntax.tickle.tickleMobile"
    static let appGroupID = "group.com.maskedsyntax.tickle.tickleMobile"
    static let cloudContainerID = "iCloud.com.maskedsyntax.tickle.tickleMobile"
    static let revenueCatAPIKey = "appl_OirRxRzfnYdCuTbyacGlXCRdhlD"
    static let proEntitlementID = "tickle_pro"
    static let sharedStoreName = "Tickle.store"
    static let sharedDefaults = UserDefaults(suiteName: appGroupID) ?? .standard
}
