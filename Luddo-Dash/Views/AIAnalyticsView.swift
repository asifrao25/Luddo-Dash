//
//  AIAnalyticsView.swift
//  Luddo-Dash
//
//  Tab 3: AI performance analytics
//

import SwiftUI
import Combine

// MARK: - AI Analytics View Model
@MainActor
class AIAnalyticsViewModel: ObservableObject {
    @Published var aiStats: AIStats?
    @Published var aiDecisions: AIDecisionsResponse?
    @Published var selectedPeriod: String = "all"
    @Published var isLoading = false
    @Published var error: String?

    private var refreshTimer: AnyCancellable?
    private let api = LuddoAPIClient.shared

    let periods = ["today", "week", "month", "all"]

    func startAutoRefresh() {
        Task { await refresh() }

        refreshTimer = Timer.publish(every: 5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { await self?.refresh() }
            }
    }

    func stopAutoRefresh() {
        refreshTimer?.cancel()
    }

    func refresh() async {
        if aiStats == nil {
            isLoading = true
        }
        error = nil

        do {
            async let statsTask = api.aiStats(period: selectedPeriod)
            async let decisionsTask = api.aiDecisions(limit: 20)

            let (statsResult, decisionsResult) = try await (statsTask, decisionsTask)

            withAnimation(.easeInOut(duration: 0.3)) {
                self.aiStats = statsResult
                self.aiDecisions = decisionsResult
            }
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func changePeriod(_ period: String) {
        selectedPeriod = period
        Task { await refresh() }
        FeedbackManager.shared.selectionHaptic()
    }
}

// MARK: - AI Analytics View
struct AIAnalyticsView: View {
    @StateObject private var viewModel = AIAnalyticsViewModel()

    var body: some View {
        PageWithHeader(
            title: "AI Analytics",
            subtitle: "Performance metrics",
            color: .aiIndigo
        ) {
            if viewModel.isLoading && viewModel.aiStats == nil {
                LoadingView("Loading AI analytics...")
                    .frame(height: 400)
            } else if let error = viewModel.error, viewModel.aiStats == nil {
                ErrorView(error) {
                    Task { await viewModel.refresh() }
                }
                .frame(height: 400)
            } else {
                aiContent
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
    private var aiContent: some View {
        VStack(spacing: 20) {
            // Period Picker
            periodPicker

            if let stats = viewModel.aiStats {
                // Win Rate Comparison
                SectionHeader("Win Rates", icon: "trophy.fill")
                winRateComparison(stats: stats)

                // Decision Metrics
                SectionHeader("Decision Performance", icon: "bolt.fill")
                decisionMetrics(stats: stats)

                // Timing Percentiles
                SectionHeader("Response Times", icon: "clock.fill")
                timingCard(timing: stats.decisions.timing)

                // Game Phase Breakdown
                if !stats.decisions.byPhase.isEmpty {
                    SectionHeader("By Game Phase", icon: "chart.bar.fill")
                    phaseBreakdown(phases: stats.decisions.byPhase)
                }

                // Engine Stats
                SectionHeader("Engine Statistics", icon: "gearshape.2.fill")
                engineStats(engines: stats.engines)
            }

            // Recent Decisions
            if let decisions = viewModel.aiDecisions, !decisions.decisions.isEmpty {
                SectionHeader("Recent Decisions", icon: "list.bullet")
                decisionsList(decisions: decisions.decisions)
            }
        }
    }

    @ViewBuilder
    private var periodPicker: some View {
        HStack(spacing: 8) {
            ForEach(viewModel.periods, id: \.self) { period in
                Button {
                    viewModel.changePeriod(period)
                } label: {
                    Text(period.capitalized)
                        .font(.subheadline)
                        .fontWeight(viewModel.selectedPeriod == period ? .semibold : .regular)
                        .foregroundStyle(viewModel.selectedPeriod == period ? .white : .primary)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            viewModel.selectedPeriod == period
                                ? Color.aiIndigo
                                : Color.cardBackground
                        )
                        .cornerRadius(8)
                }
            }
        }
    }

    @ViewBuilder
    private func winRateComparison(stats: AIStats) -> some View {
        HStack(spacing: 16) {
            // Human Win Rate
            VStack(spacing: 8) {
                GaugeView(
                    value: Double(stats.winRates.humanWinRate),
                    label: "Human",
                    color: .dashboardBlue
                )
                Text("\(stats.winRates.humanWins) wins")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(Color.cardBackground)
            .cornerRadius(12)

            // VS divider
            Text("VS")
                .font(.headline)
                .foregroundStyle(.tertiary)

            // AI Win Rate
            VStack(spacing: 8) {
                GaugeView(
                    value: Double(stats.winRates.aiWinRate),
                    label: "AI",
                    color: .aiIndigo
                )
                Text("\(stats.winRates.aiWins) wins")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(Color.cardBackground)
            .cornerRadius(12)
        }
    }

    @ViewBuilder
    private func decisionMetrics(stats: AIStats) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            MetricCard(
                title: "Total Decisions",
                value: "\(stats.decisions.total)",
                icon: "brain.fill",
                color: .aiIndigo
            )

            MetricCard(
                title: "Avg Confidence",
                value: String(format: "%.0f%%", stats.decisions.avgConfidence * 100),
                icon: "checkmark.seal.fill",
                color: .success
            )
        }
    }

    @ViewBuilder
    private func timingCard(timing: AIStats.Decisions.Timing) -> some View {
        CardContainer {
            VStack(spacing: 12) {
                HStack {
                    timingRow("Average", value: timing.avgMs)
                    Spacer()
                    timingRow("P50", value: timing.p50Ms)
                }

                Divider()

                HStack {
                    timingRow("P95", value: timing.p95Ms)
                    Spacer()
                    timingRow("P99", value: timing.p99Ms)
                }
            }
        }
    }

    @ViewBuilder
    private func timingRow(_ label: String, value: Int) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("\(value)ms")
                .font(.headline)
                .fontWeight(.semibold)
        }
    }

    @ViewBuilder
    private func phaseBreakdown(phases: [String: AIStats.Decisions.PhaseStats]) -> some View {
        CardContainer {
            VStack(spacing: 8) {
                ForEach(Array(phases.sorted(by: { $0.value.count > $1.value.count })), id: \.key) { phase, stats in
                    HStack {
                        Text(formatPhaseName(phase))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Text("\(stats.count)")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Text("(\(stats.avgTimeMs)ms)")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 4)

                    if phase != phases.keys.sorted().last {
                        Divider()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func engineStats(engines: AIStats.Engines) -> some View {
        HStack(spacing: 12) {
            CardContainer {
                VStack(spacing: 8) {
                    Image(systemName: "arrow.triangle.branch")
                        .font(.title2)
                        .foregroundStyle(Color.systemPink)

                    Text("\(engines.minimax.avgNodesEvaluated)")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Minimax Nodes")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }

            CardContainer {
                VStack(spacing: 8) {
                    Image(systemName: "dice.fill")
                        .font(.title2)
                        .foregroundStyle(Color.utilsGreen)

                    Text("\(engines.monteCarlo.avgSimulations)")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("MC Simulations")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    @ViewBuilder
    private func decisionsList(decisions: [AIDecision]) -> some View {
        VStack(spacing: 8) {
            ForEach(decisions.prefix(10)) { decision in
                DecisionListItem(decision: decision)
            }
        }
    }

    private func formatPhaseName(_ phase: String) -> String {
        phase
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
    }
}

// MARK: - Decision List Item
struct DecisionListItem: View {
    let decision: AIDecision

    var body: some View {
        HStack(spacing: 12) {
            // Dice value
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.aiIndigo.opacity(0.1))
                    .frame(width: 40, height: 40)

                Text("🎲\(decision.diceValue)")
                    .font(.subheadline)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Token \(decision.selectedToken)")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    if let phase = decision.phase {
                        Text(phase.replacingOccurrences(of: "_", with: " ").capitalized)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.cardBackground)
                            .cornerRadius(4)
                    }
                }

                HStack(spacing: 8) {
                    Text("\(Int(decision.timing.totalMs))ms")
                        .font(.caption)
                        .foregroundStyle(.tertiary)

                    if let confidence = decision.confidence {
                        Text("•")
                            .foregroundStyle(.tertiary)
                        Text("\(Int(confidence * 100))% conf")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            Spacer()

            Text("\(decision.validMoves) moves")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(Color.cardBackground)
        .cornerRadius(12)
    }
}

// MARK: - Preview
#Preview {
    AIAnalyticsView()
}
