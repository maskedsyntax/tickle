import Foundation
import SwiftData

@Model
final class Counter {
    var id: String = UUID().uuidString
    var title: String = ""
    var emoji: String?
    var colorHex: String = "#3498DB"
    var currentCount: Int = 0
    var goalValue: Int?
    var isArchived: Bool = false
    var createdAt: Date = Date()
    var sortOrder: Int = 0
    var reminderHour: Int?
    var reminderMinute: Int?
    
    @Relationship(deleteRule: .cascade, inverse: \CounterLog.counter)
    var logs: [CounterLog]?
    
    init(id: String = UUID().uuidString,
         title: String,
         emoji: String? = nil,
         colorHex: String,
         currentCount: Int = 0,
         goalValue: Int? = nil,
         isArchived: Bool = false,
         createdAt: Date = Date(),
         sortOrder: Int = 0,
         reminderHour: Int? = nil,
         reminderMinute: Int? = nil) {
        self.id = id
        self.title = title
        self.emoji = emoji
        self.colorHex = colorHex
        self.currentCount = currentCount
        self.goalValue = goalValue
        self.isArchived = isArchived
        self.createdAt = createdAt
        self.sortOrder = sortOrder
        self.reminderHour = reminderHour
        self.reminderMinute = reminderMinute
        self.logs = []
    }
}
