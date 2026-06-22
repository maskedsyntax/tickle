import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject private var store: CounterStore
    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var purchases: PurchaseService
    @EnvironmentObject private var sync: SyncStatusService
    @ObservedObject private var sounds = SoundService.shared
    @Query(filter: #Predicate<Counter> { $0.isArchived }, sort: \Counter.sortOrder) private var archived: [Counter]
    @Query(filter: #Predicate<Counter> { !$0.isArchived }, sort: \Counter.sortOrder) private var active: [Counter]
    @AppStorage("primary_widget_counter_id", store: AppConstants.sharedDefaults) private var primaryWidgetCounterID = ""
    @State private var showingPaywall = false
    @State private var exportDocument: BackupDocument?
    @State private var showingExporter = false
    @State private var showingImporter = false
    @State private var deletingCounter: Counter?
    @State private var message: String?

    var body: some View {
        NavigationStack {
            List {
                proSection
                Section("Appearance") {
                    Picker("Theme", selection: $settings.appearance) {
                        ForEach(SettingsStore.Appearance.allCases) { Text($0.title).tag($0) }
                    }
                    Picker("Haptics", selection: $settings.haptics) {
                        ForEach(SettingsStore.HapticLevel.allCases) { Text($0.title).tag($0) }
                    }.onChange(of: settings.haptics) { _, _ in settings.impact() }
                    Toggle("Sound Effects", isOn: $sounds.isSoundEnabled)
                }
                Section("Data") {
                    Button { prepareExport() } label: { Label("Export JSON Backup", systemImage: "square.and.arrow.up") }
                    Button { showingImporter = true } label: { Label("Import Backup", systemImage: "square.and.arrow.down") }
                }
                Section("Widget") {
                    if active.isEmpty { Text("Create a counter to use the widget.").foregroundStyle(.secondary) }
                    else {
                        Picker("Free Primary Counter", selection: $primaryWidgetCounterID) {
                            ForEach(active) { Text("\($0.emoji ?? "🔢") \($0.title)").tag($0.id) }
                        }
                    }
                    Text(purchases.isPro ? "Pro can choose any counter while configuring a widget." : "Your primary counter is free. Pro unlocks every counter and widget family.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                archivedSection
                Section("About") {
                    Button { RatingService.shared.requestManualReview() } label: { Label("Rate Tickle", systemImage: "star.fill") }
                    LabeledContent("Version", value: version)
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingPaywall) { PaywallView(isPresented: $showingPaywall) }
            .fileExporter(isPresented: $showingExporter, document: exportDocument,
                          contentType: .json, defaultFilename: "tickle-backup-\(Date.now.formatted(.iso8601.year().month().day()))") { result in
                if case .failure(let error) = result { message = error.localizedDescription }
            }
            .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.json]) { result in importBackup(result) }
            .confirmationDialog("Delete this archived counter and its history?", isPresented: Binding(
                get: { deletingCounter != nil }, set: { if !$0 { deletingCounter = nil } }
            ), titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    do { if let deletingCounter { try store.delete(deletingCounter) } } catch { message = error.localizedDescription }
                    deletingCounter = nil
                }
            }
            .alert("Tickle", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
                Button("OK") { message = nil }
            } message: { Text(message ?? "") }
            .onAppear {
                if primaryWidgetCounterID.isEmpty { primaryWidgetCounterID = active.first?.id ?? "" }
            }
        }
    }

    private var proSection: some View {
        Section {
            if purchases.isPro {
                Label("Tickle Pro Unlocked", systemImage: "sparkles")
                    .foregroundStyle(.blue)
                LabeledContent("iCloud Account", value: sync.status.rawValue)
                if purchases.requiresSyncRestart {
                    Text("Close and reopen Tickle once to activate iCloud sync.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Button("Refresh Purchase & Sync Status") { Task { await purchases.refresh(); await sync.refresh() } }
            } else {
                Button { showingPaywall = true } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(red: 0.25, green: 0.5, blue: 1.0), Color(red: 0.35, green: 0.35, blue: 0.95)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 42, height: 42)
                            Image(systemName: "sparkles")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Unlock Tickle Pro")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(.primary)
                            Text("Widgets · iCloud Sync · Reminders · Watch")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 6)
                }
            }
        }
    }

    @ViewBuilder private var archivedSection: some View {
        Section("Archived Counters") {
            if archived.isEmpty { Text("No archived counters").foregroundStyle(.secondary) }
            ForEach(archived) { counter in
                HStack {
                    Text(counter.emoji ?? "🔢"); Text(counter.title); Spacer(); Text("\(counter.currentCount)").foregroundStyle(.secondary)
                    Button("Restore") { do { try store.setArchived(counter, false) } catch { message = error.localizedDescription } }
                        .buttonStyle(.borderless)
                }.swipeActions {
                    Button(role: .destructive) { deletingCounter = counter } label: { Label("Delete", systemImage: "trash") }
                }
            }
        }
    }


    private var version: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
        return "\(version) (\(build))"
    }

    private func prepareExport() {
        do {
            let counters = try store.context.fetch(FetchDescriptor<Counter>())
            let logs = try store.context.fetch(FetchDescriptor<CounterLog>())
            exportDocument = try BackupDocument(payload: BackupPayload(counters: counters, logs: logs))
            showingExporter = true
        } catch { message = error.localizedDescription }
    }

    private func importBackup(_ result: Result<URL, Error>) {
        do {
            let url = try result.get(); let access = url.startAccessingSecurityScopedResource(); defer { if access { url.stopAccessingSecurityScopedResource() } }
            let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
            let payload = try decoder.decode(BackupPayload.self, from: Data(contentsOf: url))
            guard payload.version == 1 else { throw BackupError.unsupportedVersion }
            let counters = try store.context.fetch(FetchDescriptor<Counter>())
            var byID = Dictionary(uniqueKeysWithValues: counters.map { ($0.id, $0) })
            for item in payload.counters {
                let counter = byID[item.id] ?? Counter(id: item.id, title: item.title, emoji: item.emoji, colorHex: item.colorHex)
                counter.title = item.title; counter.emoji = item.emoji; counter.colorHex = item.colorHex
                counter.currentCount = item.currentCount; counter.goalValue = item.goalValue; counter.isArchived = item.isArchived
                counter.createdAt = item.createdAt; counter.sortOrder = item.sortOrder
                if byID[item.id] == nil { store.context.insert(counter); byID[item.id] = counter }
            }
            let existingLogIDs = Set(try store.context.fetch(FetchDescriptor<CounterLog>()).map(\.id))
            for item in payload.logs where !existingLogIDs.contains(item.id) {
                guard let counter = byID[item.counterID] else { continue }
                store.context.insert(CounterLog(id: item.id, timestamp: item.timestamp, actionType: item.actionType,
                                               delta: item.delta, resultingCount: item.resultingCount,
                                               counter: counter, counterID: item.counterID))
            }
            try store.saveAndReloadWidgets(); message = "Backup imported successfully."
        } catch { message = error.localizedDescription }
    }
}

private struct BackupPayload: Codable {
    let version: Int
    let exportedAt: Date
    let counters: [CounterItem]
    let logs: [LogItem]

    init(counters: [Counter], logs: [CounterLog]) {
        version = 1; exportedAt = Date()
        self.counters = counters.map(CounterItem.init)
        self.logs = logs.map(LogItem.init)
    }
    struct CounterItem: Codable {
        let id, title, colorHex: String; let emoji: String?; let currentCount: Int; let goalValue: Int?
        let isArchived: Bool; let createdAt: Date; let sortOrder: Int
        init(_ value: Counter) {
            id = value.id; title = value.title; emoji = value.emoji; colorHex = value.colorHex
            currentCount = value.currentCount; goalValue = value.goalValue; isArchived = value.isArchived
            createdAt = value.createdAt; sortOrder = value.sortOrder
        }
    }
    struct LogItem: Codable {
        let id, counterID, actionType: String; let timestamp: Date; let delta, resultingCount: Int
        init(_ value: CounterLog) {
            id = value.id; counterID = value.counterID; actionType = value.actionTypeName
            timestamp = value.timestamp; delta = value.delta; resultingCount = value.resultingCount
        }
    }
}

private struct BackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    let data: Data
    init(payload: BackupPayload) throws {
        let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]; encoder.dateEncodingStrategy = .iso8601
        data = try encoder.encode(payload)
    }
    init(configuration: ReadConfiguration) throws { data = configuration.file.regularFileContents ?? Data() }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { FileWrapper(regularFileWithContents: data) }
}

private enum BackupError: LocalizedError {
    case unsupportedVersion
    var errorDescription: String? { "This backup version is not supported." }
}
