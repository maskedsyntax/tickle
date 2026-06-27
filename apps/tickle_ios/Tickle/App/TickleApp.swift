import SwiftUI
import SwiftData

@main
struct TickleApp: App {
    private let sharedModelContainer: ModelContainer
    private let startupMigrationError: String?
    @StateObject private var counterStore: CounterStore
    @StateObject private var settingsStore = SettingsStore()
    @StateObject private var purchaseService = PurchaseService()
    @StateObject private var syncStatus = SyncStatusService()

    init() {
        AnalyticsService.shared.initialize()
        do {
            let container = try ModelContainerFactory.make(
                cloudSyncEnabled: AppConstants.sharedDefaults.bool(forKey: "is_pro")
            )
            sharedModelContainer = container
            let store = CounterStore(container: container)
            _counterStore = StateObject(wrappedValue: store)
            do {
                try LegacyMigrationService.runIfNeeded(using: store)
                startupMigrationError = nil
            } catch {
                startupMigrationError = error.localizedDescription
            }
            WatchSyncService.shared.attach(container: container, phoneStore: store)
        } catch {
            fatalError("Could not prepare Tickle data: \(error.localizedDescription)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView(startupMigrationError: startupMigrationError)
                .environmentObject(counterStore)
                .environmentObject(settingsStore)
                .environmentObject(purchaseService)
                .environmentObject(syncStatus)
                .preferredColorScheme(settingsStore.appearance.colorScheme)
                .task { await syncStatus.refresh() }
        }
        .modelContainer(sharedModelContainer)
    }
}
