import Foundation
import SQLite3
import SwiftData

@MainActor
enum LegacyMigrationService {
    static let markerKey = "legacy_sqlite_migration_v1_complete"

    static func runIfNeeded(using store: CounterStore, defaults: UserDefaults = .standard) throws {
        guard !defaults.bool(forKey: markerKey) else { return }
        let source = try FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        ).appendingPathComponent("tickle.sqlite")
        guard FileManager.default.fileExists(atPath: source.path) else {
            defaults.set(true, forKey: markerKey)
            return
        }

        try migrate(databaseURL: source, using: store)
        try reconcileLegacyWidgetIncrements(using: store)
        defaults.set(true, forKey: markerKey)
        defaults.set(true, forKey: "has_completed_onboarding")
    }

    private static func reconcileLegacyWidgetIncrements(using store: CounterStore) throws {
        let shared = AppConstants.sharedDefaults
        guard let raw = shared.string(forKey: "pending_increments"),
              let data = raw.data(using: .utf8),
              let pending = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
        for (counterID, value) in pending {
            let delta = (value as? NSNumber)?.intValue ?? 0
            if delta != 0, let counter = try store.counter(id: counterID) { try store.change(counter, by: delta) }
        }
        shared.removeObject(forKey: "pending_increments")
    }

    static func migrate(databaseURL source: URL, using store: CounterStore) throws {
        var database: OpaquePointer?
        guard sqlite3_open_v2(source.path, &database, SQLITE_OPEN_READONLY, nil) == SQLITE_OK,
              let database else { throw MigrationError.openFailed }
        defer { sqlite3_close(database) }

        let counters = try readCounters(database)
        let logs = try readLogs(database)
        let existingCounters = try store.context.fetch(FetchDescriptor<Counter>())
        let existingLogs = try store.context.fetch(FetchDescriptor<CounterLog>())
        var countersByID = Dictionary(uniqueKeysWithValues: existingCounters.map { ($0.id, $0) })
        let existingLogIDs = Set(existingLogs.map(\.id))

        for row in counters where countersByID[row.id] == nil {
            let counter = Counter(id: row.id, title: row.title, emoji: row.emoji, colorHex: row.colorHex,
                                  currentCount: row.currentCount, goalValue: row.goalValue,
                                  isArchived: row.isArchived, createdAt: row.createdAt, sortOrder: row.sortOrder)
            store.context.insert(counter)
            countersByID[row.id] = counter
        }
        for row in logs where !existingLogIDs.contains(row.id) {
            guard let counter = countersByID[row.counterID] else { continue }
            store.context.insert(CounterLog(id: row.id, timestamp: row.timestamp, actionType: row.action,
                                           delta: row.delta, resultingCount: row.resultingCount,
                                           counter: counter, counterID: row.counterID))
        }
        try store.context.save()
        let savedCounterIDs = Set(try store.context.fetch(FetchDescriptor<Counter>()).map(\.id))
        let savedLogIDs = Set(try store.context.fetch(FetchDescriptor<CounterLog>()).map(\.id))
        guard savedCounterIDs.isSuperset(of: counters.map(\.id)),
              savedLogIDs.isSuperset(of: logs.filter { countersByID[$0.counterID] != nil }.map(\.id)) else {
            throw MigrationError.verificationFailed
        }
    }

    private struct CounterRow {
        let id, title, colorHex: String
        let emoji: String?
        let currentCount: Int
        let goalValue: Int?
        let isArchived: Bool
        let createdAt: Date
        let sortOrder: Int
    }
    private struct LogRow {
        let id, counterID, action: String
        let timestamp: Date
        let delta, resultingCount: Int
    }

    private static func readCounters(_ db: OpaquePointer) throws -> [CounterRow] {
        let sql = "SELECT id,title,emoji,color_hex,current_count,goal_value,is_archived,created_at,sort_order FROM drift_counters"
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else { throw MigrationError.invalidSchema }
        defer { sqlite3_finalize(statement) }
        var rows: [CounterRow] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            rows.append(CounterRow(
                id: text(statement, 0), title: text(statement, 1), colorHex: text(statement, 3),
                emoji: optionalText(statement, 2), currentCount: Int(sqlite3_column_int64(statement, 4)),
                goalValue: optionalInt(statement, 5), isArchived: sqlite3_column_int(statement, 6) != 0,
                createdAt: date(statement, 7), sortOrder: Int(sqlite3_column_int64(statement, 8))))
        }
        return rows
    }

    private static func readLogs(_ db: OpaquePointer) throws -> [LogRow] {
        let sql = "SELECT id,counter_id,timestamp,action_type,delta,resulting_count FROM drift_counter_logs"
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else { throw MigrationError.invalidSchema }
        defer { sqlite3_finalize(statement) }
        var rows: [LogRow] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            rows.append(LogRow(id: text(statement, 0), counterID: text(statement, 1), action: text(statement, 3),
                               timestamp: date(statement, 2), delta: Int(sqlite3_column_int64(statement, 4)),
                               resultingCount: Int(sqlite3_column_int64(statement, 5))))
        }
        return rows
    }

    private static func text(_ statement: OpaquePointer?, _ index: Int32) -> String {
        guard let value = sqlite3_column_text(statement, index) else { return "" }
        return String(cString: value)
    }
    private static func optionalText(_ statement: OpaquePointer?, _ index: Int32) -> String? {
        sqlite3_column_type(statement, index) == SQLITE_NULL ? nil : text(statement, index)
    }
    private static func optionalInt(_ statement: OpaquePointer?, _ index: Int32) -> Int? {
        sqlite3_column_type(statement, index) == SQLITE_NULL ? nil : Int(sqlite3_column_int64(statement, index))
    }
    private static func date(_ statement: OpaquePointer?, _ index: Int32) -> Date {
        let raw = Double(sqlite3_column_int64(statement, index))
        let seconds = raw > 10_000_000_000 ? raw / 1000 : raw
        return Date(timeIntervalSince1970: seconds)
    }

    enum MigrationError: LocalizedError {
        case openFailed, invalidSchema, verificationFailed
        var errorDescription: String? {
            switch self {
            case .openFailed: "The previous Tickle database could not be opened."
            case .invalidSchema: "The previous Tickle database has an unsupported schema."
            case .verificationFailed: "The migrated data could not be verified. The original database was left untouched."
            }
        }
    }
}
