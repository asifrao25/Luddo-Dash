//
//  SystemMonitorView.swift
//  Luddo-Dash
//
//  Tab 4: System monitoring with charts
//

import SwiftUI
import Charts
import Combine

// MARK: - System Monitor View Model
@MainActor
class SystemMonitorViewModel: ObservableObject {
    @Published var systemLive: SystemMetrics?
    @Published var systemHistory: SystemHistoryResponse?
    @Published var hourlyTrends: HourlyTrendsResponse?
    @Published var dailyTrends: DailyTrendsResponse?
    @Published var growth: GrowthComparison?
    @Published var isLoading = false
    @Published var error: String?

    private var fastRefreshTimer: AnyCancellable?
    private var slowRefreshTimer: AnyCancellable?
    private let api = LuddoAPIClient.shared

    func startAutoRefresh() {
        Task { await refreshAll() }

        // Fast refresh for live system metrics (1 second)
        fastRefreshTimer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { await self?.refreshLiveMetrics() }
            }

        // Slow refresh for trends (30 seconds)
        slowRefreshTimer = Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { await self?.refreshTrends() }
            }
    }

    func stopAutoRefresh() {
        fastRefreshTimer?.cancel()
        slowRefreshTimer?.cancel()
    }

    func refreshAll() async {
        if systemLive == nil {
            isLoading = true
        }
        error = nil

        do {
            async let liveTask = api.systemLive()
            async let historyTask = api.systemHistory(seconds: 60)
            async let hourlyTask = api.hourlyTrends(hours: 24)
            async let dailyTask = api.dailyTrends(days: 7)
            async let growthTask = api.growth(compare: "week")

            let (live, history, hourly, daily, growthResult) = try await (
                liveTask,
                historyTask,
                hourlyTask,
                dailyTask,
                growthTask
            )

            withAnimation(.easeInOut(duration: 0.3)) {
                self.systemLive = live
                self.systemHistory = history
                self.hourlyTrends = hourly
                self.dailyTrends = daily
                self.growth = growthResult
            }
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func refreshLiveMetrics() async {
        do {
            let live = try await api.systemLive()
            let history = try await api.systemHistory(seconds: 60)

            withAnimation(.easeInOut(duration: 0.8)) {
                self.systemLive = live
                self.systemHistory = history
            }
        } catch {
            // Silent fail for live updates
        }
    }

    func refreshTrends() async {
        do {
            async let hourlyTask = api.hourlyTrends(hours: 24)
            async let dailyTask = api.dailyTrends(days: 7)
            async let growthTask = api.growth(compare: "week")

            let (hourly, daily, growthResult) = try await (hourlyTask, dailyTask, growthTask)

            withAnimation(.easeInOut(duration: 0.3)) {
                self.hourlyTrends = hourly
                self.dailyTrends = daily
                self.growth = growthResult
            }
        } catch {
            // Silent fail for trend updates
        }
    }
}

// MARK: - System Monitor View
struct SystemMonitorView: View {
    @StateObject private var viewModel = SystemMonitorViewModel()

    var body: some View {
        PageWithHeader(
            title: "System",
            subtitle: "Live monitoring",
            color: .systemPink
        ) {
            if viewModel.isLoading && viewModel.systemLive == nil {
                LoadingView("Loading system metrics...")
                    .frame(height: 400)
            } else if let error = viewModel.error, viewModel.systemLive == nil {
                ErrorView(error) {
                    Task { await viewModel.refreshAll() }
                }
                .frame(height: 400)
            } else {
                systemContent
            }
        }
        .onAppear {
            viewModel.startAutoRefresh()
        }
        .onDisappear {
            viewModel.stopAutoRefresh()
        }
        .refreshable {
            await viewModel.refreshAll()
        }
    }

    @ViewBuilder
    private var systemContent: some View {
        VStack(spacing: 20) {
            if let live = viewModel.systemLive {
                // Live Gauges
                SectionHeader("Live Status", icon: "bolt.fill")
                liveGauges(live: live)

                // CPU & Memory Details
                SectionHeader("Resources", icon: "cpu.fill")
                resourceCards(live: live)

                // Network I/O
                SectionHeader("Network", icon: "network")
                networkCard(network: live.network)

                // Disk I/O
                SectionHeader("Disk", icon: "externaldrive.fill")
                diskCard(disk: live.disk)
            }

            // History Chart
            if let history = viewModel.systemHistory, !history.metrics.isEmpty {
                SectionHeader("CPU History (60s)", icon: "chart.line.uptrend.xyaxis")
                cpuHistoryChart(metrics: history.metrics)
            }

            // Growth Comparison
            if let growth = viewModel.growth {
                SectionHeader("Growth", icon: "arrow.up.right")
                growthCard(growth: growth)
            }
        }
    }

    @ViewBuilder
    private func liveGauges(live: SystemMetrics) -> some View {
        HStack(spacing: 16) {
            GaugeView(
                value: live.cpu.usagePercent,
                label: "CPU",
                color: cpuColor(live.cpu.usagePercent)
            )

            GaugeView(
                value: live.memory.percent,
                label: "Memory",
                color: memoryColor(live.memory.percent)
            )

            GaugeView(
                value: live.disk.usagePercent,
                label: "Disk",
                color: diskColor(live.disk.usagePercent)
            )
        }
        .padding(16)
        .background(Color.cardBackground)
        .cornerRadius(12)
    }

    @ViewBuilder
    private func resourceCards(live: SystemMetrics) -> some View {
        VStack(spacing: 12) {
            // CPU Card
            CardContainer {
                VStack(spacing: 8) {
                    HStack {
                        Text("CPU Usage")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(String(format: "%.1f%%", live.cpu.usagePercent))
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(cpuColor(live.cpu.usagePercent))
                    }

                    Divider()

                    HStack(spacing: 20) {
                        loadAverage("1m", value: live.cpu.load1m)
                        loadAverage("5m", value: live.cpu.load5m)
                        loadAverage("15m", value: live.cpu.load15m)
                    }
                }
            }

            // Memory Card
            CardContainer {
                VStack(spacing: 8) {
                    HStack {
                        Text("Memory")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(live.memory.usedMB) / \(live.memory.totalMB) MB")
                            .font(.headline)
                            .fontWeight(.bold)
                    }

                    // Memory bar
                    GeometryReader { geo in
                        let percent = max(0, min(100, live.memory.percent))
                        let width = max(0, geo.size.width * CGFloat(percent) / 100)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.aiIndigo.opacity(0.2))
                            .frame(height: 8)
                            .overlay(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(memoryColor(live.memory.percent))
                                    .frame(width: width, height: 8)
                                    .animation(.easeInOut(duration: 0.8), value: width)
                            }
                    }
                    .frame(height: 8)

                    HStack {
                        Text("Free: \(live.memory.freeMB) MB")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(String(format: "%.1f%%", live.memory.percent))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func loadAverage(_ label: String, value: Double) -> some View {
        VStack(spacing: 2) {
            Text(String(format: "%.2f", value))
                .font(.subheadline)
                .fontWeight(.medium)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }

    @ViewBuilder
    private func networkCard(network: SystemMetrics.Network) -> some View {
        CardContainer {
            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color.success)
                    Text(network.rxSpeedFormatted)
                        .font(.headline)
                        .fontWeight(.semibold)
                    Text("Download")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)

                Divider()
                    .frame(height: 60)

                VStack(spacing: 4) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color.dashboardBlue)
                    Text(network.txSpeedFormatted)
                        .font(.headline)
                        .fontWeight(.semibold)
                    Text("Upload")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    @ViewBuilder
    private func diskCard(disk: SystemMetrics.Disk) -> some View {
        CardContainer {
            VStack(spacing: 12) {
                HStack {
                    Text("Disk Usage")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(String(format: "%.1f%%", disk.usagePercent))
                        .font(.headline)
                        .fontWeight(.bold)
                }

                // Disk bar
                GeometryReader { geo in
                    let width = geo.size.width * CGFloat(disk.usagePercent) / 100

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.warning.opacity(0.2))
                        .frame(height: 8)
                        .overlay(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(diskColor(disk.usagePercent))
                                .frame(width: width, height: 8)
                        }
                }
                .frame(height: 8)

                HStack {
                    Label("\(disk.readSpeed) B/s read", systemImage: "arrow.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Label("\(disk.writeSpeed) B/s write", systemImage: "arrow.up")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private func cpuHistoryChart(metrics: [SystemHistoryResponse.MetricPoint]) -> some View {
        CardContainer {
            Chart {
                ForEach(Array(metrics.enumerated()), id: \.offset) { index, point in
                    LineMark(
                        x: .value("Time", index),
                        y: .value("CPU", point.cpu)
                    )
                    .foregroundStyle(Color.systemPink.gradient)
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Time", index),
                        y: .value("CPU", point.cpu)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.systemPink.opacity(0.3), Color.systemPink.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }
            }
            .chartYScale(domain: 0...100)
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let intValue = value.as(Int.self) {
                            Text("\(intValue)%")
                                .font(.caption2)
                        }
                    }
                }
            }
            .frame(height: 150)
        }
    }

    @ViewBuilder
    private func growthCard(growth: GrowthComparison) -> some View {
        CardContainer {
            HStack(spacing: 16) {
                growthMetric(
                    label: "Visitors",
                    current: growth.current.visitors,
                    growth: growth.growthPercent.visitors
                )

                Divider()
                    .frame(height: 50)

                growthMetric(
                    label: "Games",
                    current: growth.current.games,
                    growth: growth.growthPercent.games
                )

                Divider()
                    .frame(height: 50)

                growthMetric(
                    label: "AI Games",
                    current: growth.current.aiGames,
                    growth: growth.growthPercent.aiGames
                )
            }
        }
    }

    @ViewBuilder
    private func growthMetric(label: String, current: Int, growth: Int) -> some View {
        VStack(spacing: 4) {
            Text("\(current)")
                .font(.title3)
                .fontWeight(.bold)

            HStack(spacing: 2) {
                Image(systemName: growth >= 0 ? "arrow.up" : "arrow.down")
                    .font(.caption2)
                Text("\(abs(growth))%")
                    .font(.caption)
            }
            .foregroundStyle(growth >= 0 ? Color.success : Color.error)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Helper Functions

    private func cpuColor(_ value: Double) -> Color {
        if value < 50 { return .success }
        if value < 80 { return .warning }
        return .error
    }

    private func memoryColor(_ value: Double) -> Color {
        if value < 60 { return .aiIndigo }
        if value < 85 { return .warning }
        return .error
    }

    private func diskColor(_ value: Double) -> Color {
        if value < 70 { return .utilsGreen }
        if value < 90 { return .warning }
        return .error
    }
}

// MARK: - Preview
#Preview {
    SystemMonitorView()
}
