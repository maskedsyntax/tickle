import XCTest
import SQLite3
import SwiftData
@testable import Tickle

@MainActor
final class LegacyMigrationTests: XCTestCase {
    func testMigrationPreservesIDsAndIsIdempotent() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("sqlite")
        defer { try? FileManager.default.removeItem(at: url) }
        var db: OpaquePointer?
        XCTAssertEqual(sqlite3_open(url.path, &db), SQLITE_OK)
        defer { sqlite3_close(db) }
        let statements = [
            "CREATE TABLE drift_counters (id TEXT,title TEXT,emoji TEXT,color_hex TEXT,current_count INTEGER,goal_value INTEGER,is_archived INTEGER,created_at INTEGER,sort_order INTEGER)",
            "CREATE TABLE drift_counter_logs (id TEXT,counter_id TEXT,timestamp INTEGER,action_type TEXT,delta INTEGER,resulting_count INTEGER)",
            "INSERT INTO drift_counters VALUES ('counter-1','Water','💧','#3498DB',3,8,0,1700000000000,0)",
            "INSERT INTO drift_counter_logs VALUES ('log-1','counter-1',1700000000000,'increment',3,3)"
        ]
        for statement in statements { XCTAssertEqual(sqlite3_exec(db, statement, nil, nil, nil), SQLITE_OK) }

        let schema = Schema([Counter.self, CounterLog.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let store = CounterStore(container: try ModelContainer(for: schema, configurations: [config]))
        try LegacyMigrationService.migrate(databaseURL: url, using: store)
        try LegacyMigrationService.migrate(databaseURL: url, using: store)

        let counters = try store.context.fetch(FetchDescriptor<Counter>())
        let logs = try store.context.fetch(FetchDescriptor<CounterLog>())
        XCTAssertEqual(counters.count, 1)
        XCTAssertEqual(logs.count, 1)
        XCTAssertEqual(counters.first?.id, "counter-1")
        XCTAssertEqual(counters.first?.currentCount, 3)
        XCTAssertEqual(logs.first?.counterID, "counter-1")
    }
}
