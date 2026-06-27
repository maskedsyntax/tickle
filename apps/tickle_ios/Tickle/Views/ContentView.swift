import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: CounterStore
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("has_completed_onboarding") private var hasCompletedOnboarding = false
    @State private var selectedTab: Tab = .home
    @State private var migrationError: String?
    @State private var deepLinkDraft: CounterDraft? = nil

    init(startupMigrationError: String? = nil) {
        _migrationError = State(initialValue: startupMigrationError)
    }

    enum Tab { case home, settings }

    var body: some View {
        Group {
            if let migrationError {
                MigrationRecoveryView(error: migrationError) { self.migrationError = nil }
            } else {
                TabView(selection: $selectedTab) {
                    HomeView()
                        .tabItem { Label("Counters", systemImage: "square.grid.2x2.fill") }
                        .tag(Tab.home)
                    SettingsView()
                        .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                        .tag(Tab.settings)
                }
            }
        }
        .fullScreenCover(isPresented: Binding(
            get: { migrationError == nil && !hasCompletedOnboarding },
            set: { _ in }
        )) {
            OnboardingView { hasCompletedOnboarding = true }
        }
        .sheet(item: $deepLinkDraft) { draft in
            CounterEditorSheet(draft: draft, title: "Import Counter") { updatedDraft in
                _ = try store.create(
                    title: updatedDraft.title,
                    emoji: updatedDraft.emoji,
                    colorHex: updatedDraft.colorHex,
                    goal: Int(updatedDraft.goal),
                    imageData: updatedDraft.imageData
                )
            }
        }
        .onOpenURL { url in
            handleDeepLink(url)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                store.flushPendingSave()
            }
        }
    }

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "tickle" else { return }
        if url.host == "template" {
            guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else { return }
            var title = ""
            var emoji = "💧"
            var colorHex = "#3498DB"
            var goal = ""
            
            for item in components.queryItems ?? [] {
                switch item.name {
                case "title": title = item.value ?? ""
                case "emoji": emoji = item.value ?? "💧"
                case "colorHex":
                    let hex = item.value ?? "3498DB"
                    colorHex = hex.hasPrefix("#") ? hex : "#\(hex)"
                case "goal": goal = item.value ?? ""
                default: break
                }
            }
            if !title.isEmpty {
                deepLinkDraft = CounterDraft(title: title, emoji: emoji, colorHex: colorHex, goal: goal)
            }
        }
    }
}

private struct MigrationRecoveryView: View {
    @EnvironmentObject private var store: CounterStore
    let error: String
    let onRecovered: () -> Void
    @State private var retryError: String?

    var body: some View {
        ContentUnavailableView {
            Label("Your Data Needs Attention", systemImage: "exclamationmark.triangle")
        } description: {
            Text(retryError ?? error)
        } actions: {
            Button("Retry Migration") {
                do { try LegacyMigrationService.runIfNeeded(using: store); onRecovered() }
                catch { retryError = error.localizedDescription }
            }.buttonStyle(.borderedProminent)
            if let legacyURL {
                ShareLink(item: legacyURL) {
                    Label("Export Original Database", systemImage: "square.and.arrow.up")
                }.buttonStyle(.bordered)
            }
        }.padding()
    }

    private var legacyURL: URL? {
        guard let documents = try? FileManager.default.url(
            for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false
        ) else { return nil }
        let url = documents.appendingPathComponent("tickle.sqlite")
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }
}
