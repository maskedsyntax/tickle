import SwiftUI
import SwiftData

struct OnboardingView: View {
    @EnvironmentObject private var store: CounterStore
    var onComplete: () -> Void
    
    @State private var selectedTemplates: Set<String> = ["Water", "Gym"]
    
    struct CounterTemplate {
        let id: String
        let title: String
        let emoji: String
        let colorHex: String
        let goal: Int?
    }
    
    let templates = [
        CounterTemplate(id: "Water", title: "Water Intake", emoji: "💧", colorHex: "#3498db", goal: 8),
        CounterTemplate(id: "Gym", title: "Gym Reps", emoji: "💪", colorHex: "#e74c3c", goal: nil),
        CounterTemplate(id: "Gratitude", title: "Daily Gratitude", emoji: "✨", colorHex: "#f1c40f", goal: 3),
        CounterTemplate(id: "Study", title: "Study Sessions", emoji: "📚", colorHex: "#9b59b6", goal: 4)
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            // Header
            VStack(spacing: 8) {
                Text("Welcome to Tickle")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                
                Text("The fastest, most satisfying way to track anything. Instantly.")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
            }
            
            Spacer()
            
            // Features
            VStack(alignment: .leading, spacing: 20) {
                featureRow(icon: "waveform", color: .pink, title: "Tactile Interaction", desc: "Enjoy satisfying custom sounds and precise haptic feedback on every tap.")
                featureRow(icon: "rectangle.grid.1x2.fill", color: .blue, title: "Interactive Widgets", desc: "Increment counters directly from your Home Screen with a tap.")
                featureRow(icon: "sparkles", color: .yellow, title: "One-Time Purchase", desc: "One counter is free in widgets. Unlock every counter and sync forever.")
            }
            .padding(.horizontal, 30)
            
            Spacer()
            
            // Template selection
            VStack(alignment: .leading, spacing: 10) {
                Text("Select your initial counters:")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 30)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(templates, id: \.id) { template in
                            templateCard(template: template)
                        }
                    }
                    .padding(.horizontal, 30)
                }
            }
            
            Spacer()
            
            // Continue Button
            Button(action: completeOnboarding) {
                Text("Get Started")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: Color.accentColor.opacity(0.3), radius: 10, x: 0, y: 5)
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 25)
        }
    }
    
    private func featureRow(icon: String, color: Color, title: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                Text(desc)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func templateCard(template: CounterTemplate) -> some View {
        let isSelected = selectedTemplates.contains(template.id)
        let primaryColor = Color(hex: template.colorHex)
        
        return Button(action: {
            if isSelected {
                selectedTemplates.remove(template.id)
            } else {
                selectedTemplates.insert(template.id)
            }
            SoundService.shared.playClick()
        }) {
            VStack(alignment: .leading, spacing: 6) {
                Text(template.emoji)
                    .font(.system(size: 22))
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(isSelected ? primaryColor.opacity(0.18) : Color(.systemGray6))
                    )
                
                Text(template.title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                if let goal = template.goal {
                    Text("Goal: \(goal)/day")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                } else {
                    Text("Tally log")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 105, height: 100, alignment: .leading)
            .padding(10)
            .background(isSelected ? Color(.secondarySystemBackground) : Color(.secondarySystemBackground).opacity(0.5))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? primaryColor : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func completeOnboarding() {
        SoundService.shared.playPop()
        
        for template in templates {
            if selectedTemplates.contains(template.id) {
                _ = try? store.create(title: template.title, emoji: template.emoji,
                                      colorHex: template.colorHex, goal: template.goal)
            }
        }
        
        onComplete()
    }
}

