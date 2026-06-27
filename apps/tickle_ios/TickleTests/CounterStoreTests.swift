import XCTest
import SwiftData
@testable import Tickle

@MainActor
final class CounterStoreTests: XCTestCase {
    private func makeStore() throws -> CounterStore {
        let schema = Schema([Counter.self, CounterLog.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return CounterStore(container: try ModelContainer(for: schema, configurations: [configuration]))
    }

    func testCounterLifecycleCreatesHistory() throws {
        let store = try makeStore()
        let counter = try store.create(title: "Water", emoji: "💧", colorHex: "#3498DB", goal: 8)
        try store.change(counter, by: 3)
        try store.change(counter, by: -1)
        XCTAssertEqual(counter.currentCount, 2)
        XCTAssertEqual(counter.logs?.count, 2)
        XCTAssertEqual(counter.logs?.reduce(0) { $0 + $1.delta }, 2)

        try store.reset(counter)
        XCTAssertEqual(counter.currentCount, 0)
        let sortedLogs = counter.logs?.sorted(by: { $0.timestamp < $1.timestamp })
        XCTAssertEqual(sortedLogs?.last?.actionTypeName, "reset")
        try store.clearHistory(counter)
        XCTAssertTrue(counter.logs?.isEmpty == true)
    }

    func testDuplicateAndArchive() throws {
        let store = try makeStore()
        let counter = try store.create(title: "Books", emoji: "📚", colorHex: "#9B59B6", goal: 12)
        try store.duplicate(counter)
        let all = try store.context.fetch(FetchDescriptor<Counter>(sortBy: [SortDescriptor(\.sortOrder)]))
        XCTAssertEqual(all.map(\.title), ["Books", "Books Copy"])
        XCTAssertNotEqual(all[0].id, all[1].id)
        try store.setArchived(counter, true)
        XCTAssertTrue(counter.isArchived)
    }
}
