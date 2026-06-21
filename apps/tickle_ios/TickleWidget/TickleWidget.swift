import WidgetKit
import SwiftUI
import SwiftData
import AppIntents

struct CounterEntity: AppEntity, Identifiable {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Counter")
    static var defaultQuery = CounterEntityQuery()
    let id: String
    let title: String
    let emoji: String
    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "\(emoji) \(title)") }
}

struct CounterEntityQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [CounterEntity] {
        try available().filter { identifiers.contains($0.id) }
    }
    func suggestedEntities() async throws -> [CounterEntity] { try available() }

    private func available() throws -> [CounterEntity] {
        let container = try ModelContainerFactory.make(cloudSyncEnabled: AppConstants.sharedDefaults.bool(forKey: "is_pro"))
        let context = ModelContext(container)
        let counters = try context.fetch(FetchDescriptor<Counter>(predicate: #Predicate { !$0.isArchived },
                                                                  sortBy: [SortDescriptor(\.sortOrder)]))
        let defaults = AppConstants.sharedDefaults
        let isPro = defaults.bool(forKey: "is_pro")
        let primaryID = defaults.string(forKey: "primary_widget_counter_id") ?? counters.first?.id
        return counters.filter { isPro || $0.id == primaryID }
            .map { CounterEntity(id: $0.id, title: $0.title, emoji: $0.emoji ?? "🔢") }
    }
}

struct SelectCounterIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Choose Counter"
    static var description = IntentDescription("Choose the counter shown by Tickle.")
    @Parameter(title: "Counter") var counter: CounterEntity?
}

struct CounterEntry: TimelineEntry {
    let date: Date
    let title: String
    let emoji: String
    let count: Int
    let goal: Int?
    let counterID: String?
    let isLocked: Bool
}

struct CounterProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> CounterEntry { sample }
    func snapshot(for configuration: SelectCounterIntent, in context: Context) async -> CounterEntry {
        (try? entry(for: configuration, family: context.family)) ?? sample
    }
    func timeline(for configuration: SelectCounterIntent, in context: Context) async -> Timeline<CounterEntry> {
        Timeline(entries: [(try? entry(for: configuration, family: context.family)) ?? sample], policy: .after(Date().addingTimeInterval(15 * 60)))
    }

    private var sample: CounterEntry {
        CounterEntry(date: Date(), title: "Water", emoji: "💧", count: 3, goal: 8, counterID: nil, isLocked: false)
    }
    private func entry(for configuration: SelectCounterIntent, family: WidgetFamily) throws -> CounterEntry {
        let container = try ModelContainerFactory.make(cloudSyncEnabled: AppConstants.sharedDefaults.bool(forKey: "is_pro"))
        let context = ModelContext(container)
        let counters = try context.fetch(FetchDescriptor<Counter>(predicate: #Predicate { !$0.isArchived },
                                                                  sortBy: [SortDescriptor(\.sortOrder)]))
        guard let first = counters.first else {
            return CounterEntry(date: Date(), title: "Open Tickle to add a counter", emoji: "🔢", count: 0,
                                goal: nil, counterID: nil, isLocked: false)
        }
        let defaults = AppConstants.sharedDefaults
        if defaults.string(forKey: "primary_widget_counter_id") == nil {
            defaults.set(first.id, forKey: "primary_widget_counter_id")
        }
        let primaryID = defaults.string(forKey: "primary_widget_counter_id") ?? first.id
        let requestedID = configuration.counter?.id ?? primaryID
        let isPro = defaults.bool(forKey: "is_pro")
        let usesPrimaryFallback = !isPro && requestedID != primaryID
        let locked = !isPro && (family == .systemMedium || family == .accessoryRectangular)
        let selected = counters.first(where: { $0.id == (usesPrimaryFallback ? primaryID : requestedID) }) ?? first
        return CounterEntry(date: Date(), title: selected.title, emoji: selected.emoji ?? "🔢",
                            count: selected.currentCount, goal: selected.goalValue, counterID: selected.id, isLocked: locked)
    }
}

struct TickleWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: CounterEntry

    var body: some View {
        if entry.isLocked {
            Label("Unlock this widget family in Tickle Pro", systemImage: "lock.fill")
                .font(.caption.bold()).multilineTextAlignment(.center)
                .containerBackground(for: .widget) { Color(.systemBackground) }
        } else {
            Group { switch family {
        case .accessoryCircular:
            Gauge(value: progress) { WidgetIconView(icon: entry.emoji) } currentValueLabel: { Text("\(entry.count)").font(.headline) }
                .gaugeStyle(.accessoryCircular)
        case .accessoryRectangular:
            HStack { WidgetIconView(icon: entry.emoji); VStack(alignment: .leading) { Text(entry.title).font(.headline); Text("\(entry.count)").font(.title3.bold()) } }
        default:
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    WidgetIconView(icon: entry.emoji).font(.title2); Spacer()
                    if let id = entry.counterID {
                        Button(intent: IncrementIntent(counterID: id)) { Image(systemName: "plus").font(.headline).padding(7) }
                            .buttonStyle(.borderedProminent).buttonBorderShape(.circle)
                    }
                }
                Spacer()
                Text(entry.title).font(.caption.bold()).foregroundStyle(.secondary).lineLimit(1)
                HStack(alignment: .firstTextBaseline) {
                    Text("\(entry.count)").font(.system(size: family == .systemMedium ? 40 : 30, weight: .bold, design: .rounded))
                    if let goal = entry.goal { Text("/ \(goal)").foregroundStyle(.secondary) }
                }
            }
            } }
            .containerBackground(for: .widget) { Color(.systemBackground) }
        }
    }

    private var progress: Double {
        guard let goal = entry.goal, goal > 0 else { return 0 }
        return min(Double(entry.count) / Double(goal), 1)
    }
}

@main
struct TickleWidget: Widget {
    let kind = "TickleWidget"
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: SelectCounterIntent.self, provider: CounterProvider()) { entry in
            TickleWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Tickle Counter")
        .description("View and increment a counter instantly.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular])
    }
}

struct WidgetIconView: View {
    let icon: String
    
    var body: some View {
        Group {
            if isEmoji(icon) {
                Text(icon)
            } else {
                Image(systemName: icon)
            }
        }
    }
    
    private func isEmoji(_ str: String) -> Bool {
        return str.count <= 2
    }
}
