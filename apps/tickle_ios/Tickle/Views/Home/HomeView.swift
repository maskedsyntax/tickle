import SwiftUI
import SwiftData

struct HomeView: View {
    @EnvironmentObject private var store: CounterStore
    @EnvironmentObject private var settings: SettingsStore
    @Environment(\.editMode) private var editMode
    @Query(filter: #Predicate<Counter> { !$0.isArchived }, sort: \Counter.sortOrder) private var counters: [Counter]
    @State private var showingCreate = false
    @State private var editingCounter: Counter?
    @State private var deletingCounter: Counter?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                // Premium Ambient Background
                AmbientBackgroundView()
                
                Group {
                    if counters.isEmpty {
                        emptyState
                    } else {
                        counterGrid
                    }
                }
            }
            .navigationTitle("Counters")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !counters.isEmpty {
                        EditButton()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingCreate = true
                    } label: {
                        Label("New Counter", systemImage: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showingCreate) {
                CounterEditorSheet(draft: CounterDraft(), title: "New Counter") { draft in
                    _ = try store.create(title: draft.title, emoji: draft.emoji, colorHex: draft.colorHex, goal: Int(draft.goal))
                }
            }
            .sheet(item: $editingCounter) { counter in
                CounterEditorSheet(
                    draft: CounterDraft(
                        title: counter.title,
                        emoji: counter.emoji ?? "drop.fill",
                        colorHex: counter.colorHex,
                        goal: counter.goalValue.map(String.init) ?? ""
                    ),
                    title: "Edit Counter"
                ) { draft in
                    try store.update(counter, title: draft.title, emoji: draft.emoji, colorHex: draft.colorHex, goal: Int(draft.goal))
                }
            }
            .confirmationDialog(
                "Delete this counter and its history?",
                isPresented: Binding(
                    get: { deletingCounter != nil },
                    set: { if !$0 { deletingCounter = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Delete Counter", role: .destructive) {
                    perform {
                        if let deletingCounter {
                            try store.delete(deletingCounter)
                        }
                        deletingCounter = nil
                    }
                }
                Button("Cancel", role: .cancel) {
                    deletingCounter = nil
                }
            }
            .alert(
                "Something went wrong",
                isPresented: Binding(
                    get: { errorMessage != nil },
                    set: { if !$0 { errorMessage = nil } }
                )
            ) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private var counterGrid: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 20) {
                ForEach(counters) { counter in
                    let isEditing = editMode?.wrappedValue.isEditing ?? false
                    
                    Group {
                        if isEditing {
                            gridItemContent(for: counter)
                                .onTapGesture {
                                    editingCounter = counter
                                }
                        } else {
                            NavigationLink(value: counter) {
                                gridItemContent(for: counter)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(16)
        }
        .scrollContentBackground(.hidden)
        .navigationDestination(for: Counter.self) { counter in
            CounterDetailView(counter: counter)
        }
    }

    private func gridItemContent(for counter: Counter) -> some View {
        let themeColor = Color(hex: counter.colorHex)
        let isEditing = editMode?.wrappedValue.isEditing ?? false
        
        return VStack(alignment: .leading, spacing: 8) {
            // Card Part
            ZStack(alignment: .topTrailing) {
                // Background Gradient
                LinearGradient(
                    colors: [themeColor, themeColor.darker(by: 12)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // Crescent Circle Overlay (visual depth)
                Circle()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 130, height: 130)
                    .offset(x: 35, y: 15)
                
                // Count and Unit Text
                VStack(alignment: .leading, spacing: 1) {
                    Spacer()
                    Text("\(counter.currentCount)")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(unitLabel(for: counter))
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.85))
                }
                .padding(14)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                
                // Category Icon at top-right (styled as a premium glassmorphic badge)
                if let emoji = counter.emoji {
                    Group {
                        if isEmoji(emoji) {
                            Text(emoji)
                                .font(.system(size: 14))
                        } else {
                            Image(systemName: emoji)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(Color.white.opacity(0.18)))
                    .overlay(Circle().stroke(Color.white.opacity(0.25), lineWidth: 1))
                    .shadow(color: Color.black.opacity(0.08), radius: 3, x: 0, y: 1.5)
                    .padding([.top, .trailing], 12)
                }
                
                // Edit/Delete overlays when editing
                if isEditing {
                    HStack(spacing: 0) {
                        Button {
                            deletingCounter = counter
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.red)
                                .background(Circle().fill(.white))
                        }
                        .padding(8)
                        
                        Spacer()
                        
                        Button {
                            editingCounter = counter
                        } label: {
                            Image(systemName: "pencil.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.blue)
                                .background(Circle().fill(.white))
                        }
                        .padding(8)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                }
            }
            .frame(height: 110)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: themeColor.opacity(0.25), radius: 6, x: 0, y: 3)
            .scaleEffect(isEditing ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isEditing)
            
            // Labels under card
            VStack(alignment: .leading, spacing: 2) {
                Text(counter.title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(subtitleLabel(for: counter))
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 4)
        }
        .contentShape(Rectangle())
    }

    private func unitLabel(for counter: Counter) -> String {
        let title = counter.title.lowercased()
        let count = counter.currentCount
        if title.contains("water") || title.contains("drink") {
            return count == 1 ? "glass" : "glasses"
        } else if title.contains("gym") || title.contains("workout") || title.contains("rep") || title.contains("pushup") || title.contains("situp") {
            return count == 1 ? "rep" : "reps"
        } else if title.contains("coffee") || title.contains("tea") || title.contains("caffeine") {
            return count == 1 ? "cup" : "cups"
        } else if title.contains("study") || title.contains("read") || title.contains("book") {
            return count == 1 ? "session" : "sessions"
        } else if title.contains("day") || title.contains("sober") || title.contains("streak") || title.contains("habit") {
            return count == 1 ? "day" : "days"
        } else {
            return count == 1 ? "tap" : "taps"
        }
    }

    private func subtitleLabel(for counter: Counter) -> String {
        if let lastLog = counter.logs?.sorted(by: { $0.timestamp > $1.timestamp }).first {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .full
            let timeStr = formatter.localizedString(for: lastLog.timestamp, relativeTo: Date())
            return "Last tap: \(timeStr)"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return "Started on \(formatter.string(from: counter.createdAt))"
        }
    }

    private func isEmoji(_ str: String) -> Bool {
        return str.count <= 2
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Counters", systemImage: "number.circle")
        } description: {
            Text("Create a counter and start counting in one tap.")
        } actions: {
            Button("Create Counter") {
                showingCreate = true
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private func perform(_ action: () throws -> Void) {
        do {
            try action()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct AmbientBackgroundView: View {
    @State private var animateOrbs = false
    
    var body: some View {
        ZStack {
            // Base background gradient
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color(.systemGroupedBackground)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Soft Ambient Glowing Orbs
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.08))
                    .frame(width: 320, height: 320)
                    .blur(radius: 60)
                    .offset(x: animateOrbs ? -40 : -120, y: animateOrbs ? -130 : -200)
                
                Circle()
                    .fill(Color.purple.opacity(0.08))
                    .frame(width: 380, height: 380)
                    .blur(radius: 70)
                    .offset(x: animateOrbs ? 120 : 60, y: animateOrbs ? 160 : 80)
                
                Circle()
                    .fill(Color.pink.opacity(0.06))
                    .frame(width: 280, height: 280)
                    .blur(radius: 50)
                    .offset(x: animateOrbs ? -100 : -20, y: animateOrbs ? 100 : 180)
            }
            .ignoresSafeArea()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 8.0).repeatForever(autoreverses: true)) {
                animateOrbs.toggle()
            }
        }
    }
}
