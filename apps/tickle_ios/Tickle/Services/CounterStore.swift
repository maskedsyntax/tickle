import Foundation
import SwiftUI
import SwiftData
import WidgetKit

@MainActor
final class CounterStore: ObservableObject {
    let container: ModelContainer
    let context: ModelContext

    init(container: ModelContainer) {
        self.container = container
        self.context = container.mainContext
        self.context.autosaveEnabled = true
    }

    @discardableResult
    func create(title: String, emoji: String?, colorHex: String, goal: Int?) throws -> Counter {
        let descriptor = FetchDescriptor<Counter>()
        let order = (try context.fetch(descriptor).map(\.sortOrder).max() ?? -1) + 1
        let counter = Counter(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            emoji: emoji,
            colorHex: colorHex,
            goalValue: goal.flatMap { $0 > 0 ? $0 : nil },
            sortOrder: order
        )
        context.insert(counter)
        try saveAndReloadWidgets()
        NotificationService.shared.resetReengagementNotification()
        return counter
    }

    func update(_ counter: Counter, title: String, emoji: String?, colorHex: String, goal: Int?) throws {
        counter.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        counter.emoji = emoji
        counter.colorHex = colorHex
        counter.goalValue = goal.flatMap { $0 > 0 ? $0 : nil }
        try saveAndReloadWidgets()
    }

    func change(_ counter: Counter, by delta: Int, action: String? = nil) throws {
        guard delta != 0 else { return }
        let resultingCount = counter.currentCount + delta
        counter.currentCount = resultingCount
        let log = CounterLog(
            actionType: action ?? (delta > 0 ? "increment" : "decrement"),
            delta: delta,
            resultingCount: resultingCount,
            counter: counter
        )
        context.insert(log)
        try saveAndReloadWidgets()
        NotificationService.shared.resetReengagementNotification()
        if delta > 0 { RatingService.shared.trackSignificantAction() }
    }

    func reset(_ counter: Counter) throws {
        guard counter.currentCount != 0 else { return }
        let delta = -counter.currentCount
        try change(counter, by: delta, action: "reset")
    }

    func clearHistory(_ counter: Counter) throws {
        for log in counter.logs ?? [] { context.delete(log) }
        counter.currentCount = 0
        try saveAndReloadWidgets()
    }

    func duplicate(_ counter: Counter) throws {
        _ = try create(
            title: "\(counter.title) Copy",
            emoji: counter.emoji,
            colorHex: counter.colorHex,
            goal: counter.goalValue
        )
    }

    func setArchived(_ counter: Counter, _ archived: Bool) throws {
        counter.isArchived = archived
        try saveAndReloadWidgets()
    }

    func delete(_ counter: Counter) throws {
        NotificationService.shared.cancelDailyReminder(for: counter.id)
        context.delete(counter)
        try saveAndReloadWidgets()
    }

    func move(_ counters: [Counter], from offsets: IndexSet, to destination: Int) throws {
        var reordered = counters
        reordered.move(fromOffsets: offsets, toOffset: destination)
        for (index, counter) in reordered.enumerated() { counter.sortOrder = index }
        try saveAndReloadWidgets()
    }

    func counter(id: String) throws -> Counter? {
        let requestedID = id
        var descriptor = FetchDescriptor<Counter>(predicate: #Predicate { $0.id == requestedID })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    func saveAndReloadWidgets() throws {
        try context.save()
        WidgetCenter.shared.reloadAllTimelines()
        WatchSyncService.shared.publishSnapshot()
    }
}
