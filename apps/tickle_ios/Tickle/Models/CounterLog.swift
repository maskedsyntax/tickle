import Foundation
import SwiftData

@Model
final class CounterLog {
    var id: String = UUID().uuidString
    var counterID: String = ""
    var timestamp: Date = Date()
    var actionTypeName: String = "increment"
    var delta: Int = 0
    var resultingCount: Int = 0
    
    var counter: Counter?
    
    init(id: String = UUID().uuidString,
         timestamp: Date = Date(),
         actionType: String,
         delta: Int,
         resultingCount: Int,
         counter: Counter? = nil,
         counterID: String? = nil) {
        self.id = id
        self.counterID = counterID ?? counter?.id ?? ""
        self.timestamp = timestamp
        self.actionTypeName = actionType
        self.delta = delta
        self.resultingCount = resultingCount
        self.counter = counter
    }
}
