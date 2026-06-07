import WidgetKit
import SwiftUI
#if canImport(AppIntents)
import AppIntents
#endif
import home_widget

// Define the counter model matching our JSON
struct CounterData: Codable, Identifiable {
    let id: String
    let title: String
    let emoji: String
    let colorHex: String
    let currentCount: Int
    let goalValue: Int?
}

struct Provider: TimelineProvider {
    typealias Entry = TickleEntry

    // Set the App Group ID
    let userDefaults = UserDefaults(suiteName: "group.com.maskedsyntax.tickle.tickleMobile")

    func placeholder(in context: Context) -> TickleEntry {
        TickleEntry(date: Date(), counters: [
            CounterData(id: "1", title: "Water", emoji: "💧", colorHex: "0xFF4A90E2", currentCount: 3, goalValue: 8)
        ])
    }

    func getSnapshot(in context: Context, completion: @escaping (TickleEntry) -> Void) {
        completion(TickleEntry(date: Date(), counters: loadCounters()))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<TickleEntry>) -> Void) {
        let entry = TickleEntry(date: Date(), counters: loadCounters())
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
    
    private func loadCounters() -> [CounterData] {
        guard let jsonString = userDefaults?.string(forKey: "top_counters"),
              let jsonData = jsonString.data(using: .utf8) else {
            return []
        }
        
        do {
            let counters = try JSONDecoder().decode([CounterData].self, from: jsonData)
            return counters
        } catch {
            print("Failed to decode counters: \(error)")
            return []
        }
    }
}

struct TickleEntry: TimelineEntry {
    let date: Date
    let counters: [CounterData]
}

struct TickleWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack(spacing: 8) {
            if entry.counters.isEmpty {
                Text("Open Tickle to add a counter.")
                    .font(.footnote)
                    .foregroundColor(.gray)
            } else {
                ForEach(entry.counters.prefix(3)) { counter in
                    HStack {
                        Text(counter.emoji)
                            .font(.title3)
                        
                        Text(counter.title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Text("\(counter.currentCount)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(Color(hex: counter.colorHex))
                        
                        // Increment button (Interactive in iOS 17+)
                        if #available(iOS 17.0, *) {
                            Button(intent: IncrementIntent(counterId: counter.id)) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(Color(hex: counter.colorHex))
                                    .font(.title2)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .modifier(WidgetBackgroundModifier())
    }
}

// Helper to support older iOS background rendering
struct WidgetBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content.containerBackground(.fill.tertiary, for: .widget)
        } else {
            content.background(Color(UIColor.systemBackground))
        }
    }
}

@main
struct TickleWidget: Widget {
    let kind: String = "TickleWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            TickleWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Top Counters")
        .description("Quickly view and tap your top counters.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// Color Hex Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}