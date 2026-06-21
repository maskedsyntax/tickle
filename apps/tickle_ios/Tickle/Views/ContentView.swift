import SwiftUI

struct ContentView: View {
    @AppStorage("has_completed_onboarding") private var hasCompletedOnboarding = false
    @State private var selectedTab: Tab = .home
    @State private var migrationError: String?

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
