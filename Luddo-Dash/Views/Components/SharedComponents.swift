//
//  SharedComponents.swift
//  Luddo-Dash
//
//  Reusable UI components and design system
//

import SwiftUI

// MARK: - Color Extensions
extension Color {
    // Tab Colors
    static let dashboardBlue = Color(red: 0/255, green: 102/255, blue: 204/255)
    static let gamesTeal = Color(red: 0/255, green: 166/255, blue: 147/255)
    static let aiIndigo = Color(red: 99/255, green: 102/255, blue: 241/255)
    static let liveAIOrange = Color(red: 249/255, green: 115/255, blue: 22/255)  // GPT tab
    static let systemPink = Color(red: 236/255, green: 72/255, blue: 153/255)
    static let utilsGreen = Color(red: 16/255, green: 185/255, blue: 129/255)

    // Status Colors
    static let success = Color(red: 34/255, green: 197/255, blue: 94/255)
    static let warning = Color(red: 245/255, green: 158/255, blue: 11/255)
    static let error = Color(red: 239/255, green: 68/255, blue: 68/255)

    // Background Colors
    static let cardBackground = Color(.systemGray6)
    static let darkCard = Color(.systemGray5)
}

// MARK: - Linear Gradient Extensions
extension LinearGradient {
    static let dashboardBlue = LinearGradient(
        colors: [Color.dashboardBlue, Color.dashboardBlue.opacity(0.7)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let gamesTeal = LinearGradient(
        colors: [Color.gamesTeal, Color.gamesTeal.opacity(0.7)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let aiIndigo = LinearGradient(
        colors: [Color.aiIndigo, Color.aiIndigo.opacity(0.7)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let systemPink = LinearGradient(
        colors: [Color.systemPink, Color.systemPink.opacity(0.7)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let utilsGreen = LinearGradient(
        colors: [Color.utilsGreen, Color.utilsGreen.opacity(0.7)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let liveAIOrange = LinearGradient(
        colors: [Color.liveAIOrange, Color.liveAIOrange.opacity(0.7)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Page Header
struct PageHeader: View {
    let title: String
    let subtitle: String?
    let color: Color
    let showResetMenu: Bool
    let onReset: ((ResetType) -> Void)?

    @State private var showingResetSheet = false
    @State private var selectedResetType: ResetType?
    @State private var showingConfirmation = false

    init(title: String, subtitle: String? = nil, color: Color, showResetMenu: Bool = false, onReset: ((ResetType) -> Void)? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.color = color
        self.showResetMenu = showResetMenu
        self.onReset = onReset
    }

    var body: some View {
        VStack(spacing: 0) {
            // Heading bar content
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [color, color.opacity(0.85)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // Decorative dice patterns
                HStack {
                    Image(systemName: "dice.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.white.opacity(0.08))
                        .rotationEffect(.degrees(-15))
                        .offset(x: -20, y: 5)

                    Spacer()

                    Image(systemName: "dice.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.white.opacity(0.06))
                        .rotationEffect(.degrees(20))
                        .offset(x: 20, y: -5)
                }

                // Content
                HStack(spacing: 12) {
                    // Reset menu button (left side)
                    if showResetMenu {
                        Button {
                            showingResetSheet = true
                            FeedbackManager.shared.lightHaptic()
                        } label: {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.9))
                                .frame(width: 36, height: 36)
                                .background(.white.opacity(0.15))
                                .clipShape(Circle())
                        }
                    } else {
                        Color.clear.frame(width: 36, height: 36)
                    }

                    Spacer()

                    // Centered title area
                    HStack(spacing: 8) {
                        // Dice icon
                        Image(systemName: "dice.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)

                        VStack(alignment: .leading, spacing: 1) {
                            Text(title)
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)

                            if let subtitle = subtitle {
                                Text(subtitle)
                                    .font(.system(size: 11, weight: .medium, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                        }
                    }

                    Spacer()

                    // Live indicator (right side)
                    LiveIndicator()
                        .scaleEffect(0.8)
                }
                .padding(.horizontal, 16)
            }
            .frame(height: 56)
            .clipShape(RoundedCornerShape(corners: [.bottomLeft, .bottomRight], radius: 20))
            .shadow(color: color.opacity(0.25), radius: 8, x: 0, y: 4)
        }
        .background(
            color
                .ignoresSafeArea(edges: .top)
        )
        .sheet(isPresented: $showingResetSheet) {
            ResetMenuSheet(
                onSelect: { type in
                    selectedResetType = type
                    showingResetSheet = false
                    showingConfirmation = true
                }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .confirmationDialog(
            "Reset \(selectedResetType?.displayName ?? "Data")?",
            isPresented: $showingConfirmation,
            titleVisibility: .visible
        ) {
            Button("Reset", role: .destructive) {
                if let type = selectedResetType {
                    onReset?(type)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone. All \(selectedResetType?.displayName.lowercased() ?? "selected") data will be permanently deleted.")
        }
    }
}

// MARK: - Rounded Corner Shape
struct RoundedCornerShape: Shape {
    var corners: UIRectCorner
    var radius: CGFloat

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Dice Icon View
struct DiceIconView: View {
    let color: Color
    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            // Glow effect
            Circle()
                .fill(color.opacity(0.3))
                .frame(width: 36, height: 36)
                .blur(radius: 8)

            // Dice icon with subtle animation
            Image(systemName: "dice.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
                .rotationEffect(.degrees(rotation))
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                rotation = 10
            }
        }
    }
}

// MARK: - Reset Menu Sheet
struct ResetMenuSheet: View {
    let onSelect: (ResetType) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header illustration
                ZStack {
                    Circle()
                        .fill(Color.error.opacity(0.1))
                        .frame(width: 80, height: 80)

                    Image(systemName: "arrow.counterclockwise.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(Color.error)
                }
                .padding(.top, 20)
                .padding(.bottom, 16)

                Text("Reset Data")
                    .font(.system(size: 22, weight: .bold, design: .rounded))

                Text("Select the data you want to reset")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 24)

                // Reset options grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(ResetType.allCases) { type in
                        ResetOptionButton(type: type) {
                            onSelect(type)
                        }
                    }
                }
                .padding(.horizontal, 20)

                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.secondary)
                }
            }
        }
    }
}

// MARK: - Reset Option Button
struct ResetOptionButton: View {
    let type: ResetType
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(type.color.opacity(0.12))
                        .frame(width: 50, height: 50)

                    Image(systemName: type.icon)
                        .font(.system(size: 22))
                        .foregroundStyle(type.color)
                }

                Text(type.displayName)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.cardBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(type.color.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Scale Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Page With Header
struct PageWithHeader<Content: View>: View {
    let title: String
    let subtitle: String?
    let color: Color
    let showResetMenu: Bool
    let onReset: ((ResetType) -> Void)?
    @ViewBuilder let content: Content

    init(
        title: String,
        subtitle: String? = nil,
        color: Color,
        showResetMenu: Bool = false,
        onReset: ((ResetType) -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.color = color
        self.showResetMenu = showResetMenu
        self.onReset = onReset
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with safe area background
            PageHeader(
                title: title,
                subtitle: subtitle,
                color: color,
                showResetMenu: showResetMenu,
                onReset: onReset
            )

            // Scrollable content
            ScrollView {
                content
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 100) // Space for tab bar
            }
        }
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    let icon: String?

    init(_ title: String, icon: String? = nil) {
        self.title = title
        self.icon = icon
    }

    var body: some View {
        HStack(spacing: 8) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }
}

// MARK: - Metric Card
struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let trend: Double?
    let subtitle: String?

    init(title: String, value: String, icon: String, color: Color, trend: Double? = nil, subtitle: String? = nil) {
        self.title = title
        self.value = value
        self.icon = icon
        self.color = color
        self.trend = trend
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)

                Spacer()

                if let trend = trend {
                    TrendBadge(value: trend)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)

                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(16)
        .background(Color.cardBackground)
        .cornerRadius(12)
        .shadow(color: color.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Trend Badge
struct TrendBadge: View {
    let value: Double

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: value >= 0 ? "arrow.up.right" : "arrow.down.right")
                .font(.caption2)
            Text("\(abs(Int(value)))%")
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundStyle(value >= 0 ? Color.success : Color.error)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            (value >= 0 ? Color.success : Color.error).opacity(0.1)
        )
        .cornerRadius(8)
    }
}

// MARK: - Gauge View
struct GaugeView: View {
    let value: Double
    let label: String
    let color: Color
    let maxValue: Double

    init(value: Double, label: String, color: Color, maxValue: Double = 100) {
        self.value = value
        self.label = label
        self.color = color
        self.maxValue = maxValue
    }

    var percentage: Double {
        min(value / maxValue, 1.0)
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Background circle
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 10)

                // Progress circle
                Circle()
                    .trim(from: 0, to: percentage)
                    .stroke(
                        color,
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.8), value: percentage)

                // Value text
                VStack(spacing: 2) {
                    Text("\(Int(value))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)

                    Text("%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 80, height: 80)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }
}

// MARK: - Status Badge
struct StatusBadge: View {
    let status: String
    let color: Color

    var body: some View {
        Text(status)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color)
            .cornerRadius(6)
    }
}

// MARK: - Live Indicator
struct LiveIndicator: View {
    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Color.success)
                .frame(width: 8, height: 8)
                .scaleEffect(isAnimating ? 1.2 : 1.0)
                .animation(
                    .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                    value: isAnimating
                )

            Text("LIVE")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(Color.success)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.success.opacity(0.1))
        .cornerRadius(8)
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Loading View
struct LoadingView: View {
    let message: String

    init(_ message: String = "Loading...") {
        self.message = message
    }

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Error View
struct ErrorView: View {
    let message: String
    let retryAction: (() -> Void)?

    init(_ message: String, retryAction: (() -> Void)? = nil) {
        self.message = message
        self.retryAction = retryAction
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundStyle(Color.error)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if let retryAction = retryAction {
                Button(action: retryAction) {
                    Label("Retry", systemImage: "arrow.clockwise")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)

            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Info Row
struct InfoRow: View {
    let label: String
    let value: String
    let icon: String?

    init(_ label: String, value: String, icon: String? = nil) {
        self.label = label
        self.value = value
        self.icon = icon
    }

    var body: some View {
        HStack {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(width: 24)
            }

            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Card Container
struct CardContainer<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
        }
        .padding(16)
        .background(Color.cardBackground)
        .cornerRadius(12)
    }
}

// MARK: - Preview Provider
#Preview("Components") {
    ScrollView {
        VStack(spacing: 20) {
            // New modern header with reset menu
            PageHeader(
                title: "Dashboard",
                subtitle: "Real-time metrics",
                color: .dashboardBlue,
                showResetMenu: true,
                onReset: { type in
                    print("Reset: \(type.displayName)")
                }
            )

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                MetricCard(title: "Active Users", value: "42", icon: "person.2.fill", color: .dashboardBlue, trend: 12.5)
                MetricCard(title: "Games", value: "156", icon: "gamecontroller.fill", color: .gamesTeal, trend: -5.2)
            }
            .padding(.horizontal)

            HStack(spacing: 20) {
                GaugeView(value: 65, label: "CPU", color: .systemPink)
                GaugeView(value: 42, label: "Memory", color: .aiIndigo)
                GaugeView(value: 78, label: "Disk", color: .warning)
            }
            .padding(.horizontal)

            HStack {
                StatusBadge(status: "Healthy", color: .success)
                StatusBadge(status: "Warning", color: .warning)
                StatusBadge(status: "Error", color: .error)
                LiveIndicator()
            }
            .padding(.horizontal)

            CardContainer {
                InfoRow("Server", value: "Online", icon: "server.rack")
                Divider()
                InfoRow("Uptime", value: "12h 34m", icon: "clock")
                Divider()
                InfoRow("Version", value: "1.0.0", icon: "tag")
            }
            .padding(.horizontal)
        }
    }
}
