import SwiftUI
import SwiftData

@main
struct WatchApp: App {
    private let sharedModelContainer: ModelContainer

    init() {
        let schema = Schema([
            Counter.self,
            CounterLog.self,
        ])
        
        do {
            let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, cloudKitDatabase: .none)])
            sharedModelContainer = container
            WatchSyncService.shared.attach(container: container)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            WatchListView()
        }
        .modelContainer(sharedModelContainer)
    }
}
