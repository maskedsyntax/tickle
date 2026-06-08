import WidgetKit
import SwiftUI
import AppIntents

let appGroupId = "group.com.maskedsyntax.tickle.tickleMobile"

// Counter model matching the JSON shared from the app.
struct CounterData: Codable, Identifiable {
    let id: String
    let title: String
    let emoji: String
    let colorHex: String
    let currentCount: Int
    let goalValue: Int?
}

// Reads every counter the app shared into the App Group.
// Falls back to the legacy top-3 key for older app builds.
func loadAllCounters() -> [CounterData] {
    let defaults = UserDefaults(suiteName: appGroupId)
    guard let jsonString = defaults?.string(forKey: "all_counters")
            ?? defaults?.string(forKey: "top_counters"),
          let data = jsonString.data(using: .utf8) else {
        return []
    }
    return (try? JSONDecoder().decode([CounterData].self, from: data)) ?? []
}

// How many rows fit each widget size. Capped at 3.
func maxRows(for family: WidgetFamily) -> Int {
    switch family {
    case .systemSmall: return 2
    default: return 3
    }
}

// Widgets are a Tickle Pro feature; the app writes this flag into the App Group.
func isProUnlocked() -> Bool {
    UserDefaults(suiteName: appGroupId)?.bool(forKey: "is_pro") ?? false
}

struct TickleEntry: TimelineEntry {
    let date: Date
    let counters: [CounterData]
}

// MARK: - Widget configuration (pick which counters to show)

struct CounterEntity: AppEntity, Identifiable {
    let id: String
    let title: String
    let emoji: String

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Counter"
    static var defaultQuery = CounterQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(emoji.isEmpty ? title : "\(emoji)  \(title)")")
    }
}

struct CounterQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [CounterEntity] {
        loadAllCounters()
            .filter { identifiers.contains($0.id) }
            .map { CounterEntity(id: $0.id, title: $0.title, emoji: $0.emoji) }
    }

    func suggestedEntities() async throws -> [CounterEntity] {
        loadAllCounters().map { CounterEntity(id: $0.id, title: $0.title, emoji: $0.emoji) }
    }
}

struct SelectCountersIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Choose Counters"
    static var description = IntentDescription("Pick which counters appear in this widget.")

    @Parameter(title: "Counters")
    var counters: [CounterEntity]?

    init() {}
}

// MARK: - Timeline provider

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> TickleEntry {
        TickleEntry(date: Date(), counters: Provider.sample)
    }

    func snapshot(for configuration: SelectCountersIntent, in context: Context) async -> TickleEntry {
        TickleEntry(date: Date(), counters: resolve(configuration))
    }

    func timeline(for configuration: SelectCountersIntent, in context: Context) async -> Timeline<TickleEntry> {
        let entry = TickleEntry(date: Date(), counters: resolve(configuration))
        return Timeline(entries: [entry], policy: .atEnd)
    }

    // Selected counters (in the chosen order) with fresh values; defaults to all.
    private func resolve(_ configuration: SelectCountersIntent) -> [CounterData] {
        let all = loadAllCounters()
        guard let selected = configuration.counters, !selected.isEmpty else {
            return all
        }
        let byId = Dictionary(all.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        return selected.compactMap { byId[$0.id] }
    }

    static let sample = [
        CounterData(id: "1", title: "Water", emoji: "💧", colorHex: "0xFF4A90E2", currentCount: 3, goalValue: 8),
    ]
}

// MARK: - Widget

@main
struct TickleWidget: Widget {
    let kind: String = "TickleWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: SelectCountersIntent.self,
            provider: Provider()
        ) { entry in
            TickleWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Counters")
        .description("View and tap your counters. Long-press to choose which ones to show.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - View

struct TickleWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    var entry: TickleEntry

    var body: some View {
        content
            .containerBackground(.fill.tertiary, for: .widget)
    }

    @ViewBuilder
    private var content: some View {
        if !isProUnlocked() {
            lockedView
        } else if entry.counters.isEmpty {
            emptyView
        } else {
            VStack(spacing: 8) {
                ForEach(entry.counters.prefix(maxRows(for: family))) { counter in
                    CounterRow(counter: counter)
                }
            }
        }
    }

    // Shown to non-Pro users. Tapping opens the app to upgrade.
    private var lockedView: some View {
        VStack(spacing: 6) {
            Image(systemName: "lock.fill")
                .font(.title2)
                .foregroundColor(.secondary)
            Text("Tickle Pro")
                .font(.subheadline)
                .fontWeight(.semibold)
            Text("Unlock widgets in the app")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(8)
        .widgetURL(URL(string: "tickle://pro"))
    }

    private var emptyView: some View {
        VStack(spacing: 4) {
            Image(systemName: "plus.circle.dashed")
                .font(.title2)
                .foregroundColor(.gray)
            Text("Open Tickle to add a counter.")
                .font(.footnote)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
    }
}

struct CounterRow: View {
    let counter: CounterData

    var body: some View {
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

            Button(intent: IncrementIntent(counterId: counter.id)) {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(Color(hex: counter.colorHex))
                    .font(.title2)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Color from hex

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
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
