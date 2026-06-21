import SwiftUI
import UIKit

@MainActor
final class SettingsStore: ObservableObject {
    enum Appearance: Int, CaseIterable, Identifiable {
        case system, light, dark
        var id: Int { rawValue }
        var title: String { ["System", "Light", "Dark"][rawValue] }
        var colorScheme: ColorScheme? { self == .light ? .light : self == .dark ? .dark : nil }
    }

    enum HapticLevel: String, CaseIterable, Identifiable {
        case off, light, medium, heavy
        var id: String { rawValue }
        var title: String { rawValue.capitalized }
    }

    @Published var appearance: Appearance { didSet { defaults.set(appearance.rawValue, forKey: "appearance") } }
    @Published var haptics: HapticLevel { didSet { defaults.set(haptics.rawValue, forKey: "haptics") } }
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let legacyAppearance = defaults.object(forKey: "flutter.pref_theme_mode") as? Int
        appearance = Appearance(rawValue: defaults.object(forKey: "appearance") as? Int ?? legacyAppearance ?? 0) ?? .system
        let legacyHaptics = defaults.string(forKey: "flutter.pref_haptic_level")
        haptics = HapticLevel(rawValue: defaults.string(forKey: "haptics") ?? legacyHaptics ?? "medium") ?? .medium
    }

    func impact() {
        guard haptics != .off else { return }
        let style: UIImpactFeedbackGenerator.FeedbackStyle = haptics == .light ? .light : haptics == .heavy ? .heavy : .medium
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}
