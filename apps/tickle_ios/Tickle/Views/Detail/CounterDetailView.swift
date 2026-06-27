import SwiftUI
import SwiftData
import Charts

struct CounterDetailView: View {
    @EnvironmentObject private var store: CounterStore
    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var purchases: PurchaseService
    @Environment(\.dismiss) private var dismiss
    @Bindable var counter: Counter
    @State private var rangeDays = 7
    @State private var showingEdit = false
    @State private var showingReset = false
    @State private var showingClear = false
    @State private var showingReminder = false
    @State private var reminderDate = Date()
    @State private var errorMessage: String?
    @State private var showingPaywall = false

    private var logs: [CounterLog] { (counter.logs ?? []).sorted { $0.timestamp > $1.timestamp } }
    private var positiveDays: [Date: Int] {
        Dictionary(grouping: logs.filter { $0.delta > 0 }) { Calendar.current.startOfDay(for: $0.timestamp) }
            .mapValues { $0.reduce(0) { $0 + $1.delta } }
    }
    private var chartData: [DailyTotal] {
        (0..<rangeDays).reversed().compactMap { offset in
            Calendar.current.date(byAdding: .day, value: -offset, to: Date()).map {
                let day = Calendar.current.startOfDay(for: $0)
                return DailyTotal(date: day, count: positiveDays[day] ?? 0)
            }
        }
    }
    private var currentStreak: Int { streak(startingToday: true) }
    private var longestStreak: Int {
        let days = positiveDays.keys.sorted()
        guard !days.isEmpty else { return 0 }
        var longest = 1, run = 1
        for pair in zip(days, days.dropFirst()) {
            if Calendar.current.dateComponents([.day], from: pair.0, to: pair.1).day == 1 { run += 1 }
            else { run = 1 }
            longest = max(longest, run)
        }
        return longest
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                hero
                controls
                stats
                heatmap
                activityChart
                history
            }.padding()
        }
        .background(AmbientBackgroundView())
        .navigationTitle(counter.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button { showingEdit = true } label: { Label("Edit Counter", systemImage: "pencil") }
                    Button {
                        if purchases.isPro { showingReminder = true }
                        else { showingPaywall = true }
                    } label: { Label("Daily Reminder", systemImage: "bell") }
                    Button {
                        perform { try store.duplicate(counter) }
                    } label: { Label("Duplicate Counter", systemImage: "plus.square.on.square") }
                    Button {
                        perform {
                            try store.setArchived(counter, true)
                            dismiss()
                        }
                    } label: { Label("Archive Counter", systemImage: "archivebox") }
                    Button { showingReset = true } label: { Label("Reset Count", systemImage: "arrow.counterclockwise") }
                    Button(role: .destructive) { showingClear = true } label: { Label("Clear History", systemImage: "trash") }
                } label: { Image(systemName: "ellipsis.circle") }
            }
        }
        .sheet(isPresented: $showingEdit) {
            CounterEditorSheet(draft: CounterDraft(title: counter.title, emoji: counter.emoji ?? "number",
                                                    colorHex: counter.colorHex, goal: counter.goalValue.map(String.init) ?? "", imageData: counter.imageData),
                               title: "Edit Counter") { draft in
                try store.update(counter, title: draft.title, emoji: draft.emoji, colorHex: draft.colorHex, goal: Int(draft.goal), imageData: draft.imageData)
            }
        }
        .sheet(isPresented: $showingReminder) { reminderSheet }
        .sheet(isPresented: $showingPaywall) {
            PaywallView(isPresented: $showingPaywall)
        }
        .confirmationDialog("Reset count to zero?", isPresented: $showingReset, titleVisibility: .visible) {
            Button("Reset", role: .destructive) { perform { try store.reset(counter) } }
        }
        .confirmationDialog("Clear all history and reset the count?", isPresented: $showingClear, titleVisibility: .visible) {
            Button("Clear History", role: .destructive) { perform { try store.clearHistory(counter) } }
        }
        .alert("Something went wrong", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("OK") { errorMessage = nil }
        } message: { Text(errorMessage ?? "") }
    }

    private var hero: some View {
        let themeColor = Color(hex: counter.colorHex)
        
        return Button { count(by: 1) } label: {
            VStack(spacing: 14) {
                if let emoji = counter.emoji {
                    Group {
                        if isEmoji(emoji) {
                            Text(emoji).font(.system(size: 36))
                        } else {
                            Image(systemName: emoji)
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(width: 80, height: 80)
                    .background(
                        Circle()
                            .fill(LinearGradient(colors: [themeColor, themeColor.darker(by: 10)], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .shadow(color: themeColor.opacity(0.4), radius: 8, x: 0, y: 4)
                    )
                }
                
                Text("\(counter.currentCount)").font(.system(size: 80, weight: .bold, design: .rounded)).monospacedDigit()
                    .contentTransition(.numericText())
                if let goal = counter.goalValue {
                    ProgressView(value: min(Double(counter.currentCount) / Double(goal), 1))
                        .tint(themeColor)
                    Text("\(counter.currentCount) of \(goal)").font(.subheadline.bold())
                } else { Text("Tap to count").font(.subheadline) }
            }
            .foregroundStyle(.white).frame(maxWidth: .infinity).padding(24)
            .background {
                if let imageData = counter.imageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .overlay(Color.black.opacity(0.4))
                } else {
                    LinearGradient(colors: [Color(hex: counter.colorHex), Color(hex: counter.colorHex).opacity(0.72)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 28))
        }.buttonStyle(.plain).accessibilityLabel("\(counter.title), count \(counter.currentCount)")
            .accessibilityHint("Double tap to increment")
    }

    private var controls: some View {
        HStack(spacing: 18) {
            RapidCountButton(systemName: "minus", tint: .secondary) { count(by: -1) }
                .disabled(counter.currentCount <= 0)
            RapidCountButton(systemName: "plus", tint: Color(hex: counter.colorHex)) { count(by: 1) }
        }
    }

    private var stats: some View {
        HStack {
            stat("\(currentStreak)d", "Current")
            Divider()
            stat("\(longestStreak)d", "Longest")
            Divider()
            stat(String(format: "%.1f", chartData.isEmpty ? 0 : Double(chartData.reduce(0) { $0 + $1.count }) / Double(chartData.count)), "Daily Avg")
        }.frame(maxWidth: .infinity).padding().background(.background, in: RoundedRectangle(cornerRadius: 18))
    }

    private var heatmap: some View {
        let themeColor = Color(hex: counter.colorHex)
        return VStack(alignment: .leading, spacing: 12) {
            Text("Last 8 Weeks").font(.headline)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 5), count: 14), spacing: 5) {
                ForEach((0..<56).reversed(), id: \.self) { offset in
                    let date = Calendar.current.date(byAdding: .day, value: -offset, to: Date())!
                    let value = positiveDays[Calendar.current.startOfDay(for: date)] ?? 0
                    let opacity: Double = value == 0 ? 0.1 : min(0.3 + Double(value) * 0.12, 1.0)
                    let label = "\(date.formatted(date: .abbreviated, time: .omitted)): \(value)"
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(themeColor.opacity(opacity))
                        .aspectRatio(1, contentMode: .fit)
                        .accessibilityLabel(label)
                }
            }
        }.padding().background(.background, in: RoundedRectangle(cornerRadius: 18))
    }

    private var activityChart: some View {
        VStack(alignment: .leading) {
            Picker("Range", selection: $rangeDays) { Text("7 Days").tag(7); Text("30 Days").tag(30) }.pickerStyle(.segmented)
            Chart(chartData) { total in
                BarMark(x: .value("Day", total.date, unit: .day), y: .value("Count", total.count))
                    .foregroundStyle(Color(hex: counter.colorHex)).cornerRadius(3)
            }.frame(height: 180).padding(.top)
        }.padding().background(.background, in: RoundedRectangle(cornerRadius: 18))
    }

    private var history: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("History").font(.headline).padding()
            if logs.isEmpty { Text("No activity yet").foregroundStyle(.secondary).padding([.horizontal, .bottom]) }
            ForEach(logs.prefix(100)) { log in
                Divider()
                HStack {
                    Image(systemName: log.delta >= 0 ? "plus.circle.fill" : "minus.circle.fill")
                        .foregroundStyle(log.delta >= 0 ? .green : .red)
                    Text(log.actionTypeName.capitalized)
                    Spacer()
                    Text(log.delta > 0 ? "+\(log.delta)" : "\(log.delta)").monospacedDigit()
                    Text(log.timestamp, format: .dateTime.month().day().hour().minute()).foregroundStyle(.secondary)
                }.font(.subheadline).padding()
            }
        }.background(.background, in: RoundedRectangle(cornerRadius: 18))
    }

    private var reminderSheet: some View {
        NavigationStack {
            Form {
                DatePicker("Time", selection: $reminderDate, displayedComponents: .hourAndMinute)
                if counter.reminderHour != nil {
                    Button("Remove Reminder", role: .destructive) {
                        NotificationService.shared.cancelDailyReminder(for: counter.id)
                        counter.reminderHour = nil; counter.reminderMinute = nil
                        perform { try store.saveAndReloadWidgets() }; showingReminder = false
                    }
                }
            }.navigationTitle("Daily Reminder").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingReminder = false } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            NotificationService.shared.requestPermissions { granted in
                                guard granted else { errorMessage = "Notifications are disabled. Enable them in Settings."; return }
                                let parts = Calendar.current.dateComponents([.hour, .minute], from: reminderDate)
                                NotificationService.shared.scheduleDailyReminder(for: counter.id, title: counter.title,
                                                                                 hour: parts.hour ?? 9, minute: parts.minute ?? 0)
                                counter.reminderHour = parts.hour; counter.reminderMinute = parts.minute
                                perform { try store.saveAndReloadWidgets() }; showingReminder = false
                            }
                        }
                    }
                }
        }.presentationDetents([.medium])
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack { Text(value).font(.title3.bold()); Text(label).font(.caption).foregroundStyle(.secondary) }.frame(maxWidth: .infinity)
    }
    private func count(by delta: Int) {
        guard delta > 0 || counter.currentCount > 0 else { return }
        settings.impact(); perform { try store.change(counter, by: delta) }
    }
    private func perform(_ action: () throws -> Void) { do { try action() } catch { errorMessage = error.localizedDescription } }
    private func streak(startingToday: Bool) -> Int {
        var date = Calendar.current.startOfDay(for: Date())
        if positiveDays[date] == nil { date = Calendar.current.date(byAdding: .day, value: -1, to: date)! }
        var count = 0
        while positiveDays[date] != nil { count += 1; date = Calendar.current.date(byAdding: .day, value: -1, to: date)! }
        return count
    }

    private struct DailyTotal: Identifiable { var id: Date { date }; let date: Date; let count: Int }
    
    private func isEmoji(_ str: String) -> Bool {
        return str.count <= 2
    }
}

private struct RapidCountButton: View {
    let systemName: String
    let tint: Color
    let action: () -> Void
    @State private var timer: Timer?

    var body: some View {
        Image(systemName: systemName)
            .font(.title.bold())
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(tint, in: RoundedRectangle(cornerRadius: 18))
            .contentShape(Rectangle())
            .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity) {
                // No-op (triggered only when infinity duration is reached)
            } onPressingChanged: { isPressing in
                if isPressing {
                    // Touch down: trigger tap action instantly
                    action()
                    
                    // Start delay timer; if held down for 0.4s, start rapid repeating
                    timer?.invalidate()
                    timer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: false) { _ in
                        timer?.invalidate()
                        timer = Timer.scheduledTimer(withTimeInterval: 0.12, repeats: true) { _ in
                            action()
                        }
                    }
                } else {
                    // Touch up / gesture cancelled: stop timer instantly
                    timer?.invalidate()
                    timer = nil
                }
            }
            .onDisappear {
                timer?.invalidate()
                timer = nil
            }
    }
}
