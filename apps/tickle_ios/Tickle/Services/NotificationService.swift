import Foundation
import UserNotifications

final class NotificationService {
    static let shared = NotificationService()
    
    private init() {}
    
    func requestPermissions(completion: @escaping @MainActor (Bool) -> Void = { _ in }) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permissions granted.")
                self.resetReengagementNotification()
            } else if let error = error {
                print("Notification permission error: \(error)")
            }
            Task { @MainActor in completion(granted) }
        }
    }
    
    func scheduleDailyReminder(for counterId: String, title: String, hour: Int, minute: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Time to check in!"
        content.body = "Don't forget to update your counter: \(title)."
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "daily_\(counterId)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling reminder for \(counterId): \(error)")
            }
        }
    }
    
    func cancelDailyReminder(for counterId: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily_\(counterId)"])
    }
    
    /// Resets the 48-hour inactivity reminder.
    /// Call this on app launch and whenever any counter is incremented/decremented/created.
    func resetReengagementNotification() {
        let identifier = "reengagement_inactive_reminder"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        
        let content = UNMutableNotificationContent()
        content.title = "Keep it going! 🔥"
        content.body = "You haven't updated your counters in a couple of days. Take 2 seconds to check in now!"
        content.sound = .default
        
        // 48 hours = 172800 seconds
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 172800, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling re-engagement notification: \(error)")
            }
        }
    }
}
