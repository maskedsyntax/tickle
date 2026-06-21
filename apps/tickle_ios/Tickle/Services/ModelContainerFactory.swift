import Foundation
import SwiftData

enum ModelContainerFactory {
    static let schema = Schema([Counter.self, CounterLog.self])

    static func make(cloudSyncEnabled: Bool = true) throws -> ModelContainer {
        guard let groupURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: AppConstants.appGroupID
        ) else {
            throw ContainerError.appGroupUnavailable
        }

        let storeURL = groupURL.appendingPathComponent(AppConstants.sharedStoreName)
        let cloudDatabase: ModelConfiguration.CloudKitDatabase = cloudSyncEnabled
            ? .private(AppConstants.cloudContainerID)
            : .none
        let configuration = ModelConfiguration(
            schema: schema,
            url: storeURL,
            cloudKitDatabase: cloudDatabase
        )
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    enum ContainerError: LocalizedError {
        case appGroupUnavailable

        var errorDescription: String? {
            "The shared App Group container is unavailable. Check signing entitlements."
        }
    }
}
