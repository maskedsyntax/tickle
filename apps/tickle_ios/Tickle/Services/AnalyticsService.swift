import Foundation
import Sentry

final class AnalyticsService {
    static let shared = AnalyticsService()
    
    private init() {}
    
    func initialize() {
        SentrySDK.start { options in
            options.dsn = "https://e138a49dc04342f0ba060a0f0d2c0b4c@o0.ingest.sentry.io/0" // Setup Sentry DSN
            options.debug = false
            options.enableTracing = true
        }
        trackEvent(name: "App Opened")
    }
    
    func trackEvent(name: String, parameters: [String: Any]? = nil) {
        print("Analytics: \(name) with params: \(String(describing: parameters))")
        let event = Event()
        event.message = SentryMessage(formatted: name)
        event.extra = parameters
        SentrySDK.capture(event: event)
    }
}
