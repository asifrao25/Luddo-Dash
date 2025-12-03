//
//  LiveAIView.swift
//  Luddo-Dash
//
//  Tab 4: GPT/Live AI performance analytics
//

import SwiftUI
import Combine

// MARK: - Live AI View Model
@MainActor
class LiveAIViewModel: ObservableObject {
    @Published var stats: LiveAIStats?
    @Published var costs: LiveAICosts?
    @Published var recentGames: LiveAIGamesResponse?
    @Published var decisions: LiveAIDecisionsResponse?
    @Published var errors: LiveAIErrorsResponse?
    @Published var selectedPeriod: String = "all"
    @Published var isLoading = false
    @Published var error: String?
    @Published var endpointsNotAvailable = false

    private var refreshTimer: AnyCancellable?
    private let api = LuddoAPIClient.shared

    let periods = ["today", "week", "month", "all"]

    func startAutoRefresh() {
        // Cancel any existing timer first
        refreshTimer?.cancel()
        refreshTimer = nil

        // Initial fetch
        Task { await refresh() }

        // Set up 5-second auto-refresh timer
        refreshTimer = Timer.publish(every: 5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.refresh()
                }
            }
    }

    func stopAutoRefresh() {
        refreshTimer?.cancel()
        refreshTimer = nil
    }

    func refresh() async {
        if stats == nil {
            isLoading = true
        }
        error = nil

        do {
            async let statsTask = api.liveAIStats(period: selectedPeriod)
            async let costsTask = api.liveAICosts(period: selectedPeriod)
            async let gamesTask = api.liveAIGamesRecent(limit: 10)
            async let decisionsTask = api.liveAIDecisions(limit: 20)
            async let errorsTask = api.liveAIErrors(period: selectedPeriod, limit: 50)

            let (statsResult, costsResult, gamesResult, decisionsResult, errorsResult) =
                try await (statsTask, costsTask, gamesTask, decisionsTask, errorsTask)

            withAnimation(.easeInOut(duration: 0.3)) {
                self.stats = statsResult
                self.costs = costsResult
                self.recentGames = gamesResult
                self.decisions = decisionsResult
                self.errors = errorsResult
                self.endpointsNotAvailable = false
            }
            // Vibrate on successful refresh
            FeedbackManager.shared.lightHaptic()
        } catch let apiError as APIError {
            // Check if it's a 404 error (endpoints not deployed yet)
            if case .httpError(404) = apiError {
                self.endpointsNotAvailable = true
                self.error = nil
            } else {
                self.error = apiError.localizedDescription
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

// MARK: - Live AI View
struct LiveAIView: View {
    @StateObject private var viewModel = LiveAIViewModel()
    @State private var showingResetConfirmation = false
    @State private var isResetting = false
    @State private var resetMessage: String?

    var body: some View {
        PageWithHeader(
            title: "GPT Analytics",
            subtitle: "Live AI metrics",
            color: .liveAIOrange
        ) {
            if viewModel.isLoading && viewModel.stats == nil {
                LoadingView("Loading GPT analytics...")
                    .frame(height: 400)
            } else if viewModel.endpointsNotAvailable {
                comingSoonView
            } else if let error = viewModel.error, viewModel.stats == nil {
                ErrorView(error) {
                    Task { await viewModel.refresh() }
                }
                .frame(height: 400)
            } else {
                liveAIContent
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
    private var liveAIContent: some View {
        VStack(spacing: 20) {
            // Period Picker
            periodPicker

            if let stats = viewModel.stats {
                // Overview Cards
                SectionHeader("Overview", icon: "chart.bar.fill")
                overviewCards(stats: stats)

                // Win Rate Comparison
                SectionHeader("Win Rates", icon: "trophy.fill")
                winRateComparison(stats: stats)

                // Cost Analysis
                if let costs = viewModel.costs {
                    SectionHeader("Cost Analysis", icon: "dollarsign.circle.fill")
                    costAnalysis(costs: costs)
                }

                // Parse Strategy Distribution
                SectionHeader("Parse Strategies", icon: "doc.text.magnifyingglass")
                parseStrategySection(stats: stats)

                // Error Summary
                if let errors = viewModel.errors {
                    SectionHeader("Error Tracking", icon: "exclamationmark.triangle.fill")
                    errorSummary(errors: errors)
                }
            }

            // Recent Games
            if let games = viewModel.recentGames, !games.games.isEmpty {
                SectionHeader("Recent Games", icon: "gamecontroller.fill")
                recentGamesList(games: games.games)
            }

            // Recent Decisions
            if let decisions = viewModel.decisions, !decisions.decisions.isEmpty {
                SectionHeader("Recent Decisions", icon: "brain.fill")
                decisionsList(decisions: decisions.decisions)
            }

            // Reset Section
            SectionHeader("Data Management", icon: "gearshape.fill")
            resetSection
        }
    }

    // MARK: - Reset Section

    @ViewBuilder
    private var resetSection: some View {
        CardContainer {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "arrow.counterclockwise.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color.error)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Reset GPT Data")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("Clear all Live AI decisions, errors, and game data")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }

                if let message = resetMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(Color.success)
                        .padding(.vertical, 4)
                }

                Button {
                    showingResetConfirmation = true
                    FeedbackManager.shared.lightHaptic()
                } label: {
                    HStack {
                        if isResetting {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "trash.fill")
                        }
                        Text(isResetting ? "Resetting..." : "Reset Live AI Data")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.error)
                    .cornerRadius(10)
                }
                .disabled(isResetting)
            }
        }
        .confirmationDialog(
            "Reset Live AI Data?",
            isPresented: $showingResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("Reset", role: .destructive) {
                Task { await performReset() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all GPT decisions, errors, and game data. This cannot be undone.")
        }
    }

    private func performReset() async {
        isResetting = true
        resetMessage = nil

        do {
            let response = try await LuddoAPIClient.shared.resetLiveAI()
            resetMessage = response.message
            FeedbackManager.shared.successHaptic()
            // Refresh data after reset
            await viewModel.refresh()
        } catch {
            resetMessage = "Reset failed: \(error.localizedDescription)"
            FeedbackManager.shared.errorHaptic()
        }

        isResetting = false

        // Clear message after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            resetMessage = nil
        }
    }

    // MARK: - Coming Soon View

    @ViewBuilder
    private var comingSoonView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "wand.and.stars")
                .font(.system(size: 60))
                .foregroundStyle(Color.liveAIOrange)

            Text("GPT Analytics")
                .font(.title2)
                .fontWeight(.bold)

            Text("Live AI endpoints are being deployed.\nCheck back soon!")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                Task { await viewModel.refresh() }
            } label: {
                Label("Retry", systemImage: "arrow.clockwise")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .buttonStyle(.bordered)
            .tint(.liveAIOrange)

            Spacer()
        }
        .frame(height: 400)
    }

    // MARK: - Period Picker

    @ViewBuilder
    private var periodPicker: some View {
        HStack(spacing: 6) {
            ForEach(viewModel.periods, id: \.self) { period in
                Button {
                    viewModel.changePeriod(period)
                } label: {
                    Text(period.capitalized)
                        .font(.subheadline)
                        .fontWeight(viewModel.selectedPeriod == period ? .semibold : .regular)
                        .foregroundStyle(viewModel.selectedPeriod == period ? .white : .primary)
                        .lineLimit(1)
                        .frame(minWidth: 60)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            viewModel.selectedPeriod == period
                                ? Color.liveAIOrange
                                : Color.cardBackground
                        )
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Overview Cards

    @ViewBuilder
    private func overviewCards(stats: LiveAIStats) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            MetricCard(
                title: "Total Games",
                value: "\(stats.games.total)",
                icon: "gamecontroller.fill",
                color: .liveAIOrange,
                subtitle: "\(stats.games.completionRate)% completed"
            )

            MetricCard(
                title: "API Calls",
                value: "\(stats.apiUsage.totalCalls)",
                icon: "network",
                color: .dashboardBlue,
                subtitle: "Avg \(stats.apiUsage.avgResponseTimeMs)ms"
            )

            MetricCard(
                title: "Tokens Used",
                value: formatTokens(stats.apiUsage.totalTokens),
                icon: "text.badge.checkmark",
                color: .gamesTeal,
                subtitle: "\(stats.apiUsage.avgTokensPerTurn)/turn"
            )

            MetricCard(
                title: "Est. Cost",
                value: formatCurrency(stats.apiUsage.estimatedCostUSD),
                icon: "dollarsign.circle.fill",
                color: .success,
                subtitle: "gpt-4o-mini"
            )
        }
    }

    // MARK: - Win Rate Comparison

    @ViewBuilder
    private func winRateComparison(stats: LiveAIStats) -> some View {
        HStack(spacing: 16) {
            // Human Win Rate
            VStack(spacing: 8) {
                GaugeView(
                    value: Double(stats.outcomes.humanWinRate),
                    label: "Human",
                    color: .success
                )
                Text("\(stats.outcomes.humanWins) wins")
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

            // GPT Win Rate
            VStack(spacing: 8) {
                GaugeView(
                    value: Double(100 - stats.outcomes.humanWinRate),
                    label: "GPT",
                    color: .liveAIOrange
                )
                Text("\(stats.outcomes.aiWins) wins")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(Color.cardBackground)
            .cornerRadius(12)
        }
    }

    // MARK: - Cost Analysis

    @ViewBuilder
    private func costAnalysis(costs: LiveAICosts) -> some View {
        CardContainer {
            VStack(spacing: 8) {
                InfoRow("Model", value: costs.model, icon: "cpu")
                Divider()
                InfoRow("Input Cost", value: formatCurrency(costs.costs.inputCostUSD), icon: "arrow.down.circle")
                InfoRow("Output Cost", value: formatCurrency(costs.costs.outputCostUSD), icon: "arrow.up.circle")
                Divider()
                InfoRow("Per Game", value: formatCurrency(costs.costs.avgCostPerGame), icon: "gamecontroller")
                InfoRow("Per Turn", value: formatSmallCurrency(costs.costs.avgCostPerTurn), icon: "arrow.right.circle")
                Divider()
                InfoRow("Monthly (est)", value: formatCurrency(costs.projections.projectedMonthlyCost), icon: "calendar")
                InfoRow("Yearly (est)", value: formatCurrency(costs.projections.projectedYearlyCost), icon: "calendar.badge.clock")
            }
        }
    }

    // MARK: - Parse Strategy Section

    @ViewBuilder
    private func parseStrategySection(stats: LiveAIStats) -> some View {
        let parseSuccess = stats.decisions.parseSuccess
        let percentages = parseSuccess.percentages()

        CardContainer {
            VStack(spacing: 12) {
                // Stacked bar visualization
                GeometryReader { geometry in
                    HStack(spacing: 2) {
                        if parseSuccess.json > 0 {
                            Rectangle()
                                .fill(Color.success)
                                .frame(width: geometry.size.width * CGFloat(percentages.json) / 100)
                        }
                        if parseSuccess.pattern > 0 {
                            Rectangle()
                                .fill(Color.dashboardBlue)
                                .frame(width: geometry.size.width * CGFloat(percentages.pattern) / 100)
                        }
                        if parseSuccess.digit > 0 {
                            Rectangle()
                                .fill(Color.warning)
                                .frame(width: geometry.size.width * CGFloat(percentages.digit) / 100)
                        }
                        if parseSuccess.fallback > 0 {
                            Rectangle()
                                .fill(Color.error)
                                .frame(width: geometry.size.width * CGFloat(percentages.fallback) / 100)
                        }
                    }
                    .cornerRadius(4)
                }
                .frame(height: 12)

                // Legend
                HStack(spacing: 16) {
                    ParseStrategyPill(
                        name: "JSON",
                        count: parseSuccess.json,
                        percent: percentages.json,
                        color: .success
                    )
                    ParseStrategyPill(
                        name: "Pattern",
                        count: parseSuccess.pattern,
                        percent: percentages.pattern,
                        color: .dashboardBlue
                    )
                    ParseStrategyPill(
                        name: "Digit",
                        count: parseSuccess.digit,
                        percent: percentages.digit,
                        color: .warning
                    )
                    ParseStrategyPill(
                        name: "Fallback",
                        count: parseSuccess.fallback,
                        percent: percentages.fallback,
                        color: .error
                    )
                }

                // Confidence indicator
                HStack {
                    Text("Avg Confidence")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(String(format: "%.0f%%", stats.decisions.avgConfidence * 100))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(stats.decisions.avgConfidence > 0.8 ? Color.success : Color.warning)
                }
            }
        }
    }

    // MARK: - Error Summary

    @ViewBuilder
    private func errorSummary(errors: LiveAIErrorsResponse) -> some View {
        CardContainer {
            VStack(spacing: 12) {
                // Header with recovery rate
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(errors.summary.totalErrors) Errors")
                            .font(.headline)
                        Text(String(format: "%.1f%% error rate", errors.summary.errorRate))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    StatusBadge(
                        status: "\(errors.summary.recoveryRate)% recovered",
                        color: errors.summary.recoveryRate >= 90 ? .success : .warning
                    )
                }

                if !errors.summary.byType.isEmpty {
                    Divider()

                    // Error breakdown by type
                    ForEach(Array(errors.summary.byType.sorted(by: { $0.value > $1.value })), id: \.key) { errorType, count in
                        HStack {
                            Circle()
                                .fill(errorTypeColor(errorType))
                                .frame(width: 8, height: 8)

                            Text(formatErrorType(errorType))
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

    // MARK: - Recent Games List

    @ViewBuilder
    private func recentGamesList(games: [LiveAIGame]) -> some View {
        VStack(spacing: 8) {
            ForEach(games.prefix(5)) { game in
                LiveAIGameRow(game: game)
            }
        }
    }

    // MARK: - Decisions List

    @ViewBuilder
    private func decisionsList(decisions: [LiveAIDecision]) -> some View {
        VStack(spacing: 8) {
            ForEach(decisions.prefix(10)) { decision in
                LiveAIDecisionRow(decision: decision)
            }
        }
    }

    // MARK: - Helpers

    private func formatTokens(_ tokens: Int) -> String {
        if tokens >= 1_000_000 {
            return String(format: "%.1fM", Double(tokens) / 1_000_000)
        } else if tokens >= 1_000 {
            return String(format: "%.0fK", Double(tokens) / 1_000)
        }
        return "\(tokens)"
    }

    private func formatCurrency(_ amount: Double) -> String {
        String(format: "$%.2f", amount)
    }

    private func formatSmallCurrency(_ amount: Double) -> String {
        if amount < 0.01 {
            return String(format: "$%.4f", amount)
        }
        return String(format: "$%.3f", amount)
    }

    private func errorTypeColor(_ type: String) -> Color {
        switch type.lowercased() {
        case "rate_limit": return .warning
        case "timeout": return .error
        case "invalid_response": return .systemPink
        case "network_error": return .aiIndigo
        default: return .secondary
        }
    }

    private func formatErrorType(_ type: String) -> String {
        type.replacingOccurrences(of: "_", with: " ").capitalized
    }
}

// MARK: - Parse Strategy Pill

struct ParseStrategyPill: View {
    let name: String
    let count: Int
    let percent: Double
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 4) {
                Circle()
                    .fill(color)
                    .frame(width: 6, height: 6)
                Text(name)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Text("\(count)")
                .font(.caption)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Live AI Game Row

struct LiveAIGameRow: View {
    let game: LiveAIGame

    var body: some View {
        HStack(spacing: 12) {
            // Player colors
            HStack(spacing: -4) {
                ForEach(game.players.indices, id: \.self) { index in
                    Circle()
                        .fill(playerColor(game.players[index].color))
                        .frame(width: 20, height: 20)
                        .overlay(
                            Circle()
                                .stroke(Color.cardBackground, lineWidth: 2)
                        )
                        .overlay(
                            game.players[index].type == "openai" ?
                            Image(systemName: "sparkle")
                                .font(.system(size: 8))
                                .foregroundStyle(.white) : nil
                        )
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Game \(String(game.id.prefix(6)))")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    if let winner = game.winner {
                        StatusBadge(
                            status: winner.type == "human" ? "Human Won" : "GPT Won",
                            color: winner.type == "human" ? .success : .liveAIOrange
                        )
                    } else if game.status == "in_progress" {
                        StatusBadge(status: "Playing", color: .warning)
                    }
                }

                HStack(spacing: 8) {
                    if let duration = game.durationMinutes {
                        Text("\(duration)m")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    Text("•")
                        .foregroundStyle(.tertiary)
                    Text("\(game.totalTurns) turns")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    Text("•")
                        .foregroundStyle(.tertiary)
                    Text(formatCurrency(game.estimatedCostUSD))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            Text("\(game.aiTurns) AI")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(Color.cardBackground)
        .cornerRadius(12)
    }

    private func playerColor(_ color: String) -> Color {
        switch color.lowercased() {
        case "red": return .red
        case "blue": return .blue
        case "yellow": return .yellow
        case "green": return .green
        default: return .gray
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        String(format: "$%.3f", amount)
    }
}

// MARK: - Live AI Decision Row

struct LiveAIDecisionRow: View {
    let decision: LiveAIDecision

    var body: some View {
        HStack(spacing: 12) {
            // Dice value
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.liveAIOrange.opacity(0.1))
                    .frame(width: 40, height: 40)

                Text("🎲\(decision.diceValue)")
                    .font(.subheadline)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Circle()
                        .fill(playerColor(decision.playerColor))
                        .frame(width: 10, height: 10)

                    Text(decision.playerName)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    ParseStrategyBadge(strategy: decision.parseStrategy)
                }

                HStack(spacing: 8) {
                    Text("Token \(decision.selectedToken)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("•")
                        .foregroundStyle(.tertiary)

                    Text("\(decision.responseTimeMs)ms")
                        .font(.caption)
                        .foregroundStyle(.tertiary)

                    if let outcome = decision.moveOutcome {
                        Text("•")
                            .foregroundStyle(.tertiary)
                        Text(outcome.capitalized)
                            .font(.caption)
                            .foregroundStyle(outcomeColor(outcome))
                    }
                }
            }

            Spacer()

            Text(decision.confidencePercent)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(decision.confidence > 0.8 ? Color.success : Color.warning)
        }
        .padding(12)
        .background(Color.cardBackground)
        .cornerRadius(12)
    }

    private func playerColor(_ color: String) -> Color {
        switch color.lowercased() {
        case "red": return .red
        case "blue": return .blue
        case "yellow": return .yellow
        case "green": return .green
        default: return .gray
        }
    }

    private func outcomeColor(_ outcome: String) -> Color {
        switch outcome.lowercased() {
        case "capture": return .error
        case "home": return .success
        case "safe": return .warning
        default: return .secondary
        }
    }
}

// MARK: - Parse Strategy Badge

struct ParseStrategyBadge: View {
    let strategy: String

    var body: some View {
        Text(strategy.uppercased())
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(strategyColor)
            .cornerRadius(4)
    }

    private var strategyColor: Color {
        switch strategy.lowercased() {
        case "json": return .success
        case "pattern": return .dashboardBlue
        case "digit": return .warning
        case "fallback": return .error
        default: return .secondary
        }
    }
}

// MARK: - Preview
#Preview {
    LiveAIView()
}
