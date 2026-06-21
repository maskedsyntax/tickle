import Foundation
import Combine
import SwiftData
import WatchConnectivity

@MainActor
final class WatchSyncService: NSObject, ObservableObject {
    static let shared = WatchSyncService()
    private var container: ModelContainer?
    #if os(iOS)
    private var phoneStore: CounterStore?
    #endif

    #if os(iOS)
    func attach(container: ModelContainer, phoneStore: CounterStore? = nil) {
        self.container = container
        self.phoneStore = phoneStore
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
        if phoneStore != nil { publishSnapshot() }
    }
    #else
    func attach(container: ModelContainer) {
        self.container = container
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }
    #endif

    #if os(iOS)
    func publishSnapshot() {
        guard let phoneStore, WCSession.default.activationState == .activated else { return }
        let descriptor = FetchDescriptor<Counter>(predicate: #Predicate { !$0.isArchived }, sortBy: [SortDescriptor(\.sortOrder)])
        guard let counters = try? phoneStore.context.fetch(descriptor) else { return }
        let payload: [[String: Any]] = counters.map {
            ["id": $0.id, "title": $0.title, "emoji": $0.emoji ?? "", "color": $0.colorHex,
             "count": $0.currentCount, "goal": $0.goalValue as Any, "order": $0.sortOrder]
        }
        try? WCSession.default.updateApplicationContext(["counters": payload])
    }
    #endif

    func incrementFromWatch(_ counter: Counter) {
        counter.currentCount += 1
        try? container?.mainContext.save()
        let operation: [String: Any] = ["operationID": UUID().uuidString, "counterID": counter.id, "delta": 1]
        WCSession.default.transferUserInfo(operation)
    }

    private func applySnapshot(_ payload: [[String: Any]]) {
        guard let context = container?.mainContext else { return }
        let existing = (try? context.fetch(FetchDescriptor<Counter>())) ?? []
        let byID = Dictionary(uniqueKeysWithValues: existing.map { ($0.id, $0) })
        let incomingIDs = Set(payload.compactMap { $0["id"] as? String })
        for item in payload {
            guard let id = item["id"] as? String, let title = item["title"] as? String else { continue }
            let counter = byID[id] ?? Counter(id: id, title: title, colorHex: item["color"] as? String ?? "#3498DB")
            counter.title = title; counter.emoji = item["emoji"] as? String; counter.colorHex = item["color"] as? String ?? counter.colorHex
            counter.currentCount = item["count"] as? Int ?? 0; counter.goalValue = item["goal"] as? Int; counter.sortOrder = item["order"] as? Int ?? 0
            counter.isArchived = false
            if byID[id] == nil { context.insert(counter) }
        }
        for counter in existing where !incomingIDs.contains(counter.id) { context.delete(counter) }
        try? context.save()
    }

    #if os(iOS)
    private func applyOperation(_ info: [String: Any]) {
        guard let id = info["operationID"] as? String,
              let counterID = info["counterID"] as? String,
              let delta = info["delta"] as? Int,
              let phoneStore else { return }
        let key = "processed_watch_operations"
        var processed = UserDefaults.standard.stringArray(forKey: key) ?? []
        guard !processed.contains(id) else { return }
        if let counter = try? phoneStore.counter(id: counterID) {
            try? phoneStore.change(counter, by: delta)
            processed.append(id)
            UserDefaults.standard.set(Array(processed.suffix(500)), forKey: key)
            publishSnapshot()
        }
    }
    #endif
}

extension WatchSyncService: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        #if os(iOS)
        Task { @MainActor in if phoneStore != nil { publishSnapshot() } }
        #endif
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        guard let payload = applicationContext["counters"] as? [[String: Any]] else { return }
        Task { @MainActor in applySnapshot(payload) }
    }

    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        #if os(iOS)
        Task { @MainActor in applyOperation(userInfo) }
        #endif
    }

    #if os(iOS)
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
    nonisolated func sessionDidDeactivate(_ session: WCSession) { session.activate() }
    #endif
}
