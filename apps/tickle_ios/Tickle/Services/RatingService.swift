import Foundation
import StoreKit
import UIKit

final class RatingService {
    static let shared = RatingService()
    
    private init() {}
    
    private let firstLaunchDateKey = "rating_service_first_launch_date"
    private let actionCountKey = "rating_service_action_count"
    private let lastPromptedDateKey = "rating_service_last_prompted_date"
    private let lastPromptedActionCountKey = "rating_service_last_prompted_action_count"
    private let promptCountKey = "rating_service_prompt_count"
    
    func trackSignificantAction() {
        // Record first launch date if not already recorded
        if UserDefaults.standard.object(forKey: firstLaunchDateKey) == nil {
            UserDefaults.standard.set(Date(), forKey: firstLaunchDateKey)
        }
        
        var count = UserDefaults.standard.integer(forKey: actionCountKey)
        count += 1
        UserDefaults.standard.set(count, forKey: actionCountKey)
        
        if shouldPrompt(for: count) {
            promptForReview(actionCount: count)
        }
    }
    
    private func shouldPrompt(for count: Int) -> Bool {
        let firstLaunch = UserDefaults.standard.object(forKey: firstLaunchDateKey) as? Date ?? Date()
        let daysSinceInstall = Calendar.current.dateComponents([.day], from: firstLaunch, to: Date()).day ?? 0
        
        // 1. Give the user time to build experience (minimum 3 days since install)
        guard daysSinceInstall >= 3 else { return false }
        
        let promptCount = UserDefaults.standard.integer(forKey: promptCountKey)
        
        // 2. First prompt: Trigger at 30+ actions
        if promptCount == 0 {
            return count >= 30
        }
        
        // 3. Subsequent prompts: limit frequency (Apple limits requests to 3 times per 365 days)
        guard promptCount < 3 else { return false }
        
        if let lastPromptedDate = UserDefaults.standard.object(forKey: lastPromptedDateKey) as? Date {
            let daysSinceLastPrompt = Calendar.current.dateComponents([.day], from: lastPromptedDate, to: Date()).day ?? 0
            let lastPromptedActionCount = UserDefaults.standard.integer(forKey: lastPromptedActionCountKey)
            let actionsSinceLastPrompt = count - lastPromptedActionCount
            
            // Require 60 days and 100 new actions since the last prompt
            return daysSinceLastPrompt >= 60 && actionsSinceLastPrompt >= 100
        }
        
        return false
    }
    
    private func promptForReview(actionCount: Int) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            guard let windowScene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else {
                return
            }
            
            SKStoreReviewController.requestReview(in: windowScene)
            
            // Record state to ensure we respect pacing limits
            UserDefaults.standard.set(Date(), forKey: self.lastPromptedDateKey)
            UserDefaults.standard.set(actionCount, forKey: self.lastPromptedActionCountKey)
            
            let promptCount = UserDefaults.standard.integer(forKey: self.promptCountKey)
            UserDefaults.standard.set(promptCount + 1, forKey: self.promptCountKey)
            
            print("RatingService: SKStoreReviewController.requestReview executed. Total prompts: \(promptCount + 1)")
        }
    }

    func requestManualReview() {
        promptForReview(actionCount: UserDefaults.standard.integer(forKey: actionCountKey))
    }
}
