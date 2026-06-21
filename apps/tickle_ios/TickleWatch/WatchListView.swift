import SwiftUI
import SwiftData
import WatchKit

struct WatchListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Counter> { !$0.isArchived }, sort: \Counter.sortOrder) private var counters: [Counter]
    
    var body: some View {
        NavigationStack {
            List {
                if counters.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "ellipsis.circle")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("No Counters")
                            .font(.headline)
                        Text("Add them on your iPhone")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(counters) { counter in
                        Button(action: {
                            increment(counter)
                        }) {
                            HStack {
                                if let emoji = counter.emoji, isEmoji(emoji) {
                                    Text(emoji)
                                        .font(.title3)
                                } else {
                                    Image(systemName: counter.emoji ?? "number")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(Color(hex: counter.colorHex))
                                }
                                VStack(alignment: .leading) {
                                    Text(counter.title)
                                        .font(.body)
                                        .fontWeight(.semibold)
                                        .lineLimit(1)
                                    if let goal = counter.goalValue {
                                        Text("Goal: \(counter.currentCount)/\(goal)")
                                            .font(.footnote)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                Spacer()
                                Text("\(counter.currentCount)")
                                    .font(.system(.title3, design: .rounded))
                                    .fontWeight(.bold)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Tickle")
        }
    }
    
    private func increment(_ counter: Counter) {
        #if os(watchOS)
        WKInterfaceDevice.current().play(.click)
        #endif
        
        WatchSyncService.shared.incrementFromWatch(counter)
    }

    private func isEmoji(_ str: String) -> Bool {
        return str.count <= 2
    }
}
