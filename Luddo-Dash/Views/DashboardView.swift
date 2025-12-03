//
//  DashboardView.swift
//  Luddo-Dash
//
//  Tab 1: Home dashboard with real-time metrics
//

import SwiftUI
import Combine

// MARK: - Dashboard View Model
@MainActor
class DashboardViewModel: ObservableObject {
    @Published var health: HealthResponse?
    @Published var status: StatusResponse?
    @Published var realtime: RealtimeMetrics?
    @Published var summary: SummaryMetrics?
    @Published var isLoading = false
    @Published var isResetting = false
    @Published var error: String?
    @Published var resetMessage: String?

    private var refreshTimer: AnyCancellable?
    private let api = LuddoAPIClient.shared

    func startAutoRefresh() {
        // Initial load
        Task { await refresh() }

        // Auto-refresh every 5 seconds
        refreshTimer = Timer.publish(every: 5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { await self?.refresh() }
            }
    }

    func stopAutoRefresh() {
        refreshTimer?.cancel()
        refreshTimer = nil
    }

    func refresh() async {
        // Don't show loading indicator on subsequent refreshes
        if health == nil {
            isLoading = true
        }
        error = nil

        do {
            async let healthTask = api.health()
            async let statusTask = api.status()
            async let realtimeTask = api.realtime()
            async let summaryTask = api.summary(period: "today")

            let (healthResult, statusResult, realtimeResult, summaryResult) = try await (
                healthTask,
                statusTask,
                realtimeTask,
                summaryTask
            )

            withAnimation(.easeInOut(duration: 0.3)) {
                self.health = healthResult
                self.status = statusResult
                self.realtime = realtimeResult
                self.summary = summaryResult
            }

            FeedbackManager.shared.refreshSuccessFeedback()
        } catch {
            self.error = error.localizedDescription
            FeedbackManager.shared.refreshErrorFeedback()
        }

        isLoading = false
    }

    func resetData(type: ResetType) async {
        isResetting = true
        resetMessage = nil

        do {
            let result = try await api.reset(type: type)
            resetMessage = result.message
            FeedbackManager.shared.successHaptic()

            // Refresh data after reset
            await refresh()
        } catch {
            resetMessage = "Reset failed: \(error.localizedDescription)"
            FeedbackManager.shared.errorHaptic()
        }

        isResetting = false

        // Clear message after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.resetMessage = nil
        }
    }
}

// MARK: - Dashboard View
struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()

    var body: some View {
        ZStack {
            PageWithHeader(
                title: "Dashboard",
                subtitle: "Real-time metrics",
                color: .dashboardBlue,
                showResetMenu: true,
                onReset: { type in
                    Task { await viewModel.resetData(type: type) }
                }
            ) {
                if viewModel.isLoading && viewModel.health == nil {
                    LoadingView("Loading dashboard...")
                        .frame(height: 400)
                } else if let error = viewModel.error, viewModel.health == nil {
                    ErrorView(error) {
                        Task { await viewModel.refresh() }
                    }
                    .frame(height: 400)
                } else {
                    dashboardContent
                }
            }

            // Reset message toast
            if let message = viewModel.resetMessage {
                VStack {
                    Spacer()

                    HStack(spacing: 8) {
                        Image(systemName: message.contains("failed") ? "xmark.circle.fill" : "checkmark.circle.fill")
                            .foregroundStyle(message.contains("failed") ? Color.error : Color.success)

                        Text(message)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(.regularMaterial)
                    .cornerRadius(25)
                    .shadow(radius: 10)
                    .padding(.bottom, 120)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.resetMessage)
            }

            // Loading overlay during reset
            if viewModel.isResetting {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)

                    Text("Resetting data...")
                        .font(.headline)
                        .foregroundStyle(.white)
                }
            }
        }
        .onAppear {
            viewModel.startAutoRefresh()
        }
        .onDisappear {
            viewModel.stopAutoRefresh()
        }
        .refreshable {
            await viewModel.refresh()
        }
    }

    @ViewBuilder
    private var dashboardContent: some View {
        VStack(spacing: 20) {
            // Server Status Card
            serverStatusCard

            // Real-time Metrics
            SectionHeader("Real-time Activity", icon: "bolt.fill")
            realtimeMetricsGrid

            // Today's Summary
            SectionHeader("Today's Summary", icon: "calendar")
            summaryMetricsGrid

            // Database Stats
            if let status = viewModel.status {
                SectionHeader("Database", icon: "cylinder.fill")
                databaseStatsCard(status: status)
            }
        }
    }

    @ViewBuilder
    private var serverStatusCard: some View {
        CardContainer {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Server Status")
                            .font(.headline)
                            .fontWeight(.semibold)

                        Spacer()

                        LiveIndicator()
                    }

                    if let health = viewModel.health {
                        HStack(spacing: 16) {
                            StatusBadge(
                                status: health.status.capitalized,
                                color: health.status == "healthy" ? .success : .warning
                            )

                            Text("Uptime: \(formatUptime(health.uptime))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if let status = viewModel.status {
                        Text("Version \(status.version)")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var realtimeMetricsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            if let realtime = viewModel.realtime {
                MetricCard(
                    title: "Active Visitors",
                    value: "\(realtime.visitors.active)",
                    icon: "person.2.fill",
                    color: .dashboardBlue,
                    subtitle: visitorBreakdown(realtime.visitors)
                )

                MetricCard(
                    title: "Games in Progress",
                    value: "\(realtime.games.inProgress)",
                    icon: "gamecontroller.fill",
                    color: .gamesTeal,
                    subtitle: gameTypeBreakdown(realtime.games)
                )
            }
        }
    }

    @ViewBuilder
    private var summaryMetricsGrid: some View {
        if let summary = viewModel.summary {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                MetricCard(
                    title: "Unique Visitors",
                    value: "\(summary.visitors.uniqueToday)",
                    icon: "person.badge.clock.fill",
                    color: .aiIndigo
                )

                MetricCard(
                    title: "Total Games",
                    value: "\(summary.games.total)",
                    icon: "flag.checkered",
                    color: .systemPink,
                    subtitle: "\(summary.games.completed) completed"
                )

                MetricCard(
                    title: "Completion Rate",
                    value: "\(summary.games.completionRate)%",
                    icon: "chart.pie.fill",
                    color: .success
                )

                MetricCard(
                    title: "AI Win Rate",
                    value: "\(summary.aiPerformance.aiWinRate)%",
                    icon: "brain.fill",
                    color: .utilsGreen,
                    subtitle: "\(summary.aiPerformance.totalDecisions) decisions"
                )
            }
        }
    }

    @ViewBuilder
    private func databaseStatsCard(status: StatusResponse) -> some View {
        CardContainer {
            VStack(spacing: 12) {
                HStack {
                    Text("Database Size")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(String(format: "%.2f MB", status.database.sizeMB))
                        .font(.headline)
                        .fontWeight(.semibold)
                }

                Divider()

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(Array(status.database.tables.sorted(by: { $0.key < $1.key })), id: \.key) { table, count in
                        HStack {
                            Text(table.replacingOccurrences(of: "_", with: " ").capitalized)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(count)")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Helper Functions

    private func formatUptime(_ seconds: Double) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    private func visitorBreakdown(_ visitors: RealtimeMetrics.Visitors) -> String? {
        guard !visitors.byDevice.isEmpty else { return nil }
        let parts = visitors.byDevice.map { "\($0.value) \($0.key)" }
        return parts.joined(separator: ", ")
    }

    private func gameTypeBreakdown(_ games: RealtimeMetrics.GamesInProgress) -> String? {
        guard games.inProgress > 0 else { return nil }
        return "\(games.byType.local) local, \(games.byType.ai) AI"
    }
}

// MARK: - Preview
#Preview {
    DashboardView()
}
