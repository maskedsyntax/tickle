import AppIntents
import SwiftData
import WidgetKit

struct IncrementIntent: AppIntent {
    static var title: LocalizedStringResource = "Increment Counter"
    static var openAppWhenRun = false
    @Parameter(title: "Counter ID") var counterID: String

    init() { counterID = "" }
    init(counterID: String) { self.counterID = counterID }

    func perform() async throws -> some IntentResult {
        let defaults = AppConstants.sharedDefaults
        let allowedID = defaults.bool(forKey: "is_pro") ? counterID : (defaults.string(forKey: "primary_widget_counter_id") ?? counterID)
        let container = try ModelContainerFactory.make(cloudSyncEnabled: defaults.bool(forKey: "is_pro"))
        let context = ModelContext(container)
        let id = allowedID
        var descriptor = FetchDescriptor<Counter>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        if let counter = try context.fetch(descriptor).first, !counter.isArchived {
            counter.currentCount += 1
            context.insert(CounterLog(actionType: "increment", delta: 1, resultingCount: counter.currentCount, counter: counter))
            try context.save()
            WidgetCenter.shared.reloadAllTimelines()
        }
        return .result()
    }
}
