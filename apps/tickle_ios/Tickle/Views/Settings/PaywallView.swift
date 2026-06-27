import SwiftUI

struct PaywallView: View {
    @EnvironmentObject private var purchases: PurchaseService
    @Binding var isPresented: Bool
    @State private var pulseGlow = false

    private struct Feature: Identifiable {
        let id = UUID()
        let icon: String
        let color: Color
        let title: String
        let subtitle: String
    }

    private let features: [Feature] = [
        Feature(icon: "rectangle.grid.1x2.fill", color: .blue, title: "Any Counter in Widgets", subtitle: "Put your favorites on your Home Screen"),
        Feature(icon: "icloud.fill", color: .cyan, title: "iCloud Sync", subtitle: "Your data, private and everywhere"),
        Feature(icon: "bell.fill", color: .purple, title: "Daily Reminders", subtitle: "Never forget to track what matters"),
        Feature(icon: "applewatch", color: .indigo, title: "Apple Watch", subtitle: "Count right from your wrist"),
    ]

    var body: some View {
        ZStack {
            // Ambient background matching app design language
            AmbientBackgroundView()

            VStack(spacing: 0) {
                // --- Dismiss affordance ---
                HStack {
                    Spacer()
                    Button {
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 26))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel("Dismiss")
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                Spacer(minLength: 4)

                // --- Hero Section ---
                VStack(spacing: 10) {
                    // Glowing sparkle icon
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [Color.blue.opacity(0.35), Color.blue.opacity(0)],
                                    center: .center,
                                    startRadius: 8,
                                    endRadius: 50
                                )
                            )
                            .frame(width: 100, height: 100)
                            .scaleEffect(pulseGlow ? 1.12 : 0.92)
                            .animation(
                                .easeInOut(duration: 2.4).repeatForever(autoreverses: true),
                                value: pulseGlow
                            )

                        Image(systemName: "sparkles")
                            .font(.system(size: 40, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(red: 0.25, green: 0.5, blue: 1.0), Color(red: 0.35, green: 0.35, blue: 0.95)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }

                    Text("Tickle Pro")
                        .font(.system(size: 30, weight: .bold, design: .rounded))

                    Text("One purchase. Yours forever.")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 16)

                // --- Feature Benefit Cards ---
                VStack(spacing: 8) {
                    ForEach(features) { feature in
                        featureCard(feature)
                    }
                }
                .padding(.horizontal, 20)

                Spacer(minLength: 8)

                // --- Social Proof + Price Anchor ---
                VStack(spacing: 3) {
                    HStack(spacing: 5) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.blue)
                        Text("Loved by thousands of counters")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    Text("One-Time Purchase · Less than a cup of coffee ☕")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.tertiary)
                }
                .padding(.bottom, 12)

                // --- CTA Button ---
                Button {
                    Task {
                        await purchases.purchase()
                        if purchases.isPro {
                            isPresented = false
                        }
                    }
                } label: {
                    Text(purchases.isLoading ? "Please Wait…" : "Unlock for \(purchases.price)")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.25, green: 0.5, blue: 1.0), Color(red: 0.3, green: 0.35, blue: 0.95)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: Color.blue.opacity(0.35), radius: 10, x: 0, y: 5)
                }
                .buttonStyle(.plain)
                .disabled(purchases.isLoading)
                .padding(.horizontal, 24)

                // --- Secondary Actions ---
                Button("Restore Purchases") {
                    Task {
                        await purchases.restore()
                        if purchases.isPro {
                            isPresented = false
                        }
                    }
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
                .disabled(purchases.isLoading)
                .padding(.top, 10)

                Button("Not Now") {
                    isPresented = false
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.tertiary)
                .padding(.top, 5)
                .padding(.bottom, 16)
            }
        }
        .onAppear { pulseGlow = true }
        .alert("Purchase Error", isPresented: Binding(
            get: { purchases.errorMessage != nil },
            set: { if !$0 { purchases.errorMessage = nil } }
        )) {
            Button("OK") { purchases.errorMessage = nil }
        } message: {
            Text(purchases.errorMessage ?? "")
        }
    }

    // MARK: - Feature Card

    private func featureCard(_ feature: Feature) -> some View {
        HStack(spacing: 12) {
            Image(systemName: feature.icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(feature.color)
                .frame(width: 34, height: 34)
                .background(
                    Circle()
                        .fill(feature.color.opacity(0.12))
                )

            VStack(alignment: .leading, spacing: 1) {
                Text(feature.title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                Text(feature.subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }
}
