import AppIntents
import Foundation
import WidgetKit

// Increment a counter directly from the widget.
//
// iOS runs an interactive widget's `perform()` inside the widget-extension
// process, so this does the work in pure Swift against the shared App Group:
//   1. bump the displayed count in `top_counters` for instant widget feedback
//   2. record a pending +1 in `pending_increments` for the app to reconcile
//      into the database the next time it launches/resumes
// No Flutter engine is involved (that only exists in the app's process).
@available(iOS 17.0, *)
struct IncrementIntent: AppIntent {
    static var title: LocalizedStringResource = "Increment Counter"
    static var description = IntentDescription("Increments the selected counter.")

    @Parameter(title: "Counter ID")
    var counterId: String

    init() {}

    init(counterId: String) {
        self.counterId = counterId
    }

    func perform() async throws -> some IntentResult {
        let appGroup = "group.com.maskedsyntax.tickle.tickleMobile"
        guard let defaults = UserDefaults(suiteName: appGroup) else {
            return .result()
        }

        // 1. Bump the displayed count so the widget updates immediately.
        //    Mirror the change into both the full list (iOS widget) and the
        //    legacy top-3 list (Android / older builds) when present.
        for key in ["all_counters", "top_counters"] {
            guard let jsonString = defaults.string(forKey: key),
                  let data = jsonString.data(using: .utf8),
                  var counters = (try? JSONSerialization.jsonObject(with: data)) as? [[String: Any]]
            else { continue }
            for i in counters.indices where counters[i]["id"] as? String == counterId {
                let current = counters[i]["currentCount"] as? Int ?? 0
                counters[i]["currentCount"] = current + 1
            }
            if let newData = try? JSONSerialization.data(withJSONObject: counters),
               let newString = String(data: newData, encoding: .utf8) {
                defaults.set(newString, forKey: key)
            }
        }

        // 2. Accumulate a pending delta for the app to apply to the database.
        var pending: [String: Int] = [:]
        if let pendingString = defaults.string(forKey: "pending_increments"),
           let pendingData = pendingString.data(using: .utf8),
           let parsed = (try? JSONSerialization.jsonObject(with: pendingData)) as? [String: Any] {
            for (key, value) in parsed {
                pending[key] = (value as? Int) ?? 0
            }
        }
        pending[counterId, default: 0] += 1
        if let pendingData = try? JSONSerialization.data(withJSONObject: pending),
           let pendingString = String(data: pendingData, encoding: .utf8) {
            defaults.set(pendingString, forKey: "pending_increments")
        }

        // 3. Ask WidgetKit to redraw with the updated count.
        WidgetCenter.shared.reloadAllTimelines()

        return .result()
    }
}
