//
//  LearnView.swift
//  Luddo-Dash
//
//  Tab 7: AI Learning System - Shows how GPT learns from game data
//

import SwiftUI
import Combine

// MARK: - Learn View Model
@MainActor
class LearnViewModel: ObservableObject {
    @Published var insightsResponse: LearningInsightsResponse?
    @Published var history: LearningHistoryResponse?
    @Published var isLoading = false
    @Published var isAnalyzing = false
    @Published var error: String?
    @Published var analyzeMessage: String?
    @Published var endpointsNotAvailable = false

    private var refreshTimer: AnyCancellable?
    private let api = LuddoAPIClient.shared

    var insights: LearningInsightsData? {
        insightsResponse?.insights
    }

    var hasInsights: Bool {
        insightsResponse?.hasInsights ?? false
    }

    func startAutoRefresh() {
        refreshTimer?.cancel()
        refreshTimer = nil

        Task { await refresh() }

        // Refresh every 30 seconds (learning data doesn't change frequently)
        refreshTimer = Timer.publish(every: 30, on: .main, in: .common)
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
        if insightsResponse == nil {
            isLoading = true
        }
        error = nil

        do {
            async let insightsTask = api.learningInsights()
            async let historyTask = api.learningInsightsHistory()

            let (insightsResult, historyResult) = try await (insightsTask, historyTask)

            withAnimation(.easeInOut(duration: 0.3)) {
                self.insightsResponse = insightsResult
                self.history = historyResult
                self.endpointsNotAvailable = false
            }
            FeedbackManager.shared.lightHaptic()
        } catch let apiError as APIError {
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

    func triggerAnalysis() async {
        isAnalyzing = true
        analyzeMessage = nil

        do {
            let response = try await api.triggerLearningAnalysis(days: 7)
            if response.isSuccess {
                analyzeMessage = "\(response.message) (v\(response.version ?? 0))"
                FeedbackManager.shared.successHaptic()
            } else {
                analyzeMessage = response.message
            }

            // Refresh data after analysis
            await refresh()
        } catch {
            analyzeMessage = "Analysis failed: \(error.localizedDescription)"
            FeedbackManager.shared.errorHaptic()
        }

        isAnalyzing = false

        // Clear message after 4 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            self.analyzeMessage = nil
        }
    }
}

// MARK: - Learn View
struct LearnView: View {
    @StateObject private var viewModel = LearnViewModel()

    var body: some View {
        PageWithHeader(
            title: "AI Learning",
            subtitle: "Pattern analysis",
            color: .learnPurple
        ) {
            if viewModel.isLoading && viewModel.insightsResponse == nil {
                LoadingView("Loading learning insights...")
                    .frame(height: 400)
            } else if viewModel.endpointsNotAvailable {
                comingSoonView
            } else if let error = viewModel.error, viewModel.insightsResponse == nil {
                ErrorView(error) {
                    Task { await viewModel.refresh() }
                }
                .frame(height: 400)
            } else {
                learnContent
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

    // MARK: - Main Content

    @ViewBuilder
    private var learnContent: some View {
        VStack(spacing: 20) {
            if viewModel.hasInsights, let insights = viewModel.insights {
                // Version & Status Card
                SectionHeader("Current Model", icon: "brain.head.profile")
                versionCard(insights: insights)

                // Win Rate Comparison
                SectionHeader("Performance", icon: "trophy.fill")
                performanceSection(insights: insights)

                // Data Range
                SectionHeader("Training Data", icon: "chart.bar.doc.horizontal")
                dataRangeCard(insights: insights)

                // Learned Patterns
                SectionHeader("Learned Strategies", icon: "lightbulb.fill")
                strategiesSection(insights: insights)

                // General Tips
                if !insights.insights.generalTips.isEmpty {
                    SectionHeader("General Tips", icon: "text.quote")
                    tipsCard(tips: insights.insights.generalTips)
                }

                // Prompt Preview
                if let promptAddition = viewModel.insightsResponse?.promptAddition, !promptAddition.isEmpty {
                    SectionHeader("Prompt Addition", icon: "doc.text.fill")
                    promptPreviewCard(prompt: promptAddition)
                }
            } else {
                // No insights yet
                noInsightsView
            }

            // Version History
            if let history = viewModel.history, !history.history.isEmpty {
                SectionHeader("Version History", icon: "clock.arrow.circlepath")
                historySection(history: history)
            }

            // Manual Analysis Trigger
            SectionHeader("Actions", icon: "gearshape.fill")
            analysisActionCard
        }
    }

    // MARK: - No Insights View

    @ViewBuilder
    private var noInsightsView: some View {
        CardContainer {
            VStack(spacing: 16) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 40))
                    .foregroundStyle(Color.learnPurple.opacity(0.5))

                Text("No Learning Data Yet")
                    .font(.headline)

                Text(viewModel.insightsResponse?.message ?? "Run analysis to generate insights from game data.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        }
    }

    // MARK: - Coming Soon View

    @ViewBuilder
    private var comingSoonView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "brain.head.profile")
                .font(.system(size: 60))
                .foregroundStyle(Color.learnPurple)

            Text("AI Learning")
                .font(.title2)
                .fontWeight(.bold)

            Text("Learning endpoints are being deployed.\nCheck back soon!")
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
            .tint(.learnPurple)

            Spacer()
        }
        .frame(height: 400)
    }

    // MARK: - Version Card

    @ViewBuilder
    private func versionCard(insights: LearningInsightsData) -> some View {
        CardContainer {
            HStack(spacing: 16) {
                // Version badge
                ZStack {
                    Circle()
                        .fill(Color.learnPurple.opacity(0.15))
                        .frame(width: 60, height: 60)

                    VStack(spacing: 2) {
                        Text("v\(insights.version)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.learnPurple)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Learning Model")
                        .font(.headline)

                    Text("Generated \(formatDate(insights.generatedAt))")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 8) {
                        StatusBadge(status: "Active", color: .success)
                        StatusBadge(status: "Auto-refresh", color: .learnPurple)
                    }
                }

                Spacer()
            }
        }
    }

    // MARK: - Performance Section

    @ViewBuilder
    private func performanceSection(insights: LearningInsightsData) -> some View {
        HStack(spacing: 16) {
            // Human Win Rate
            VStack(spacing: 8) {
                GaugeView(
                    value: insights.metadata.humanWinRate,
                    label: "Human",
                    color: .success
                )
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(Color.cardBackground)
            .cornerRadius(12)

            // VS
            Text("VS")
                .font(.headline)
                .foregroundStyle(.tertiary)

            // AI Win Rate
            VStack(spacing: 8) {
                GaugeView(
                    value: insights.metadata.aiWinRate,
                    label: "GPT",
                    color: .learnPurple
                )
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(Color.cardBackground)
            .cornerRadius(12)
        }

        // Additional Metrics
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            MetricCard(
                title: "Avg Game Duration",
                value: String(format: "%.0f min", insights.metadata.avgGameDuration),
                icon: "clock.fill",
                color: .learnPurple
            )

            MetricCard(
                title: "Decisions Analyzed",
                value: formatNumber(insights.metadata.totalDecisionsAnalyzed),
                icon: "arrow.triangle.swap",
                color: .aiIndigo
            )
        }
    }

    // MARK: - Data Range Card

    @ViewBuilder
    private func dataRangeCard(insights: LearningInsightsData) -> some View {
        CardContainer {
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Analysis Period")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Text("\(formatDate(insights.periodStart)) → \(formatDate(insights.periodEnd))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }

                Divider()

                HStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(insights.gamesAnalyzed)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.learnPurple)
                        Text("Games")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(formatNumber(insights.metadata.totalDecisionsAnalyzed))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.aiIndigo)
                        Text("Decisions")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
            }
        }
    }

    // MARK: - Strategies Section

    @ViewBuilder
    private func strategiesSection(insights: LearningInsightsData) -> some View {
        VStack(spacing: 12) {
            // Dice Strategies
            if !insights.insights.diceStrategies.isEmpty {
                DiceStrategiesCard(strategies: insights.insights.diceStrategies)
            }

            // Phase Strategies
            if !insights.insights.phaseStrategies.isEmpty {
                PhaseStrategiesCard(strategies: insights.insights.phaseStrategies)
            }

            // Position Insights
            if !insights.insights.positionInsights.isEmpty {
                PositionInsightsCard(insights: insights.insights.positionInsights)
            }

            // Capture Patterns
            if !insights.insights.capturePatterns.isEmpty {
                CapturePattersCard(patterns: insights.insights.capturePatterns)
            }
        }
    }

    // MARK: - Tips Card

    @ViewBuilder
    private func tipsCard(tips: [String]) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(tips.indices, id: \.self) { index in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .font(.caption)
                            .foregroundStyle(Color.warning)

                        Text(tips[index])
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Prompt Preview Card

    @ViewBuilder
    private func promptPreviewCard(prompt: String) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "doc.text.fill")
                        .foregroundStyle(Color.learnPurple)

                    Text("GPT System Prompt Addition")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Spacer()

                    Text("\(prompt.count) chars")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                ScrollView {
                    Text(prompt)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 150)
                .padding(12)
                .background(Color(.systemGray5))
                .cornerRadius(8)
            }
        }
    }

    // MARK: - History Section

    @ViewBuilder
    private func historySection(history: LearningHistoryResponse) -> some View {
        VStack(spacing: 8) {
            ForEach(history.history.prefix(5)) { version in
                HistoryVersionRow(version: version)
            }

            if history.count > 5 {
                Text("+ \(history.count - 5) more versions")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 4)
            }
        }
    }

    // MARK: - Analysis Action Card

    @ViewBuilder
    private var analysisActionCard: some View {
        CardContainer {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "wand.and.stars")
                        .font(.title2)
                        .foregroundStyle(Color.learnPurple)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Manual Analysis")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("Trigger pattern analysis for the last 7 days")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }

                if let message = viewModel.analyzeMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(message.contains("failed") ? Color.error : Color.success)
                        .padding(.vertical, 4)
                }

                Button {
                    FeedbackManager.shared.lightHaptic()
                    Task { await viewModel.triggerAnalysis() }
                } label: {
                    HStack {
                        if viewModel.isAnalyzing {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "sparkles")
                        }
                        Text(viewModel.isAnalyzing ? "Analyzing..." : "Run Analysis")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.learnPurple)
                    .cornerRadius(10)
                }
                .disabled(viewModel.isAnalyzing)
            }
        }
    }

    // MARK: - Helpers

    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .short
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }

        // Fallback: try without fractional seconds
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .short
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }

        return dateString
    }

    private func formatNumber(_ num: Int) -> String {
        if num >= 1000 {
            return String(format: "%.1fK", Double(num) / 1000)
        }
        return "\(num)"
    }
}

// MARK: - Dice Strategies Card

struct DiceStrategiesCard: View {
    let strategies: [DiceStrategy]
    @State private var isExpanded = true

    var body: some View {
        CardContainer {
            VStack(spacing: 12) {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isExpanded.toggle()
                    }
                    FeedbackManager.shared.selectionHaptic()
                } label: {
                    HStack {
                        Image(systemName: "dice.fill")
                            .foregroundStyle(Color.liveAIOrange)

                        Text("Dice Strategies")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)

                        Spacer()

                        Text("\(strategies.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)

                if isExpanded {
                    Divider()

                    ForEach(strategies) { strategy in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                // Dice value badge
                                ZStack {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.liveAIOrange.opacity(0.15))
                                        .frame(width: 28, height: 28)

                                    Text("\(strategy.diceValue)")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundStyle(Color.liveAIOrange)
                                }

                                Text(strategy.pattern)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                Spacer()
                            }

                            HStack(spacing: 12) {
                                HStack(spacing: 4) {
                                    Text("Win:")
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                    Text("\(Int(strategy.winCorrelation))%")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(strategy.winCorrelation > 50 ? Color.success : Color.warning)
                                }

                                HStack(spacing: 4) {
                                    Text("Sample:")
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                    Text("\(strategy.sampleSize)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                HStack(spacing: 4) {
                                    Text("Confidence:")
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                    Text(String(format: "%.0f%%", strategy.confidence * 100))
                                        .font(.caption)
                                        .foregroundStyle(strategy.confidence > 0.7 ? Color.success : Color.warning)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }
}

// MARK: - Phase Strategies Card

struct PhaseStrategiesCard: View {
    let strategies: [PhaseStrategy]
    @State private var isExpanded = true

    var body: some View {
        CardContainer {
            VStack(spacing: 12) {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isExpanded.toggle()
                    }
                    FeedbackManager.shared.selectionHaptic()
                } label: {
                    HStack {
                        Image(systemName: "arrow.triangle.branch")
                            .foregroundStyle(Color.learnPurple)

                        Text("Game Phase Strategies")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)

                        Spacer()

                        Text("\(strategies.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)

                if isExpanded {
                    Divider()

                    ForEach(strategies) { strategy in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                StatusBadge(
                                    status: strategy.phase.capitalized,
                                    color: phaseColor(strategy.phase)
                                )

                                Text(strategy.pattern)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                Spacer()
                            }

                            // Effectiveness bar
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color.learnPurple.opacity(0.2))

                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color.learnPurple)
                                        .frame(width: geo.size.width * (strategy.effectiveness / 100))
                                }
                            }
                            .frame(height: 4)

                            HStack(spacing: 12) {
                                Text("Effectiveness: \(Int(strategy.effectiveness))%")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)

                                Text("Sample: \(strategy.sampleSize)")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }

    private func phaseColor(_ phase: String) -> Color {
        switch phase.lowercased() {
        case "early": return .success
        case "mid", "middle": return .warning
        case "late", "end": return .error
        default: return .secondary
        }
    }
}

// MARK: - Position Insights Card

struct PositionInsightsCard: View {
    let insights: [PositionInsight]
    @State private var isExpanded = false

    var body: some View {
        CardContainer {
            VStack(spacing: 12) {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isExpanded.toggle()
                    }
                    FeedbackManager.shared.selectionHaptic()
                } label: {
                    HStack {
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundStyle(Color.dashboardBlue)

                        Text("Position Insights")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)

                        Spacer()

                        Text("\(insights.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)

                if isExpanded {
                    Divider()

                    ForEach(insights) { insight in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "info.circle.fill")
                                .font(.caption)
                                .foregroundStyle(Color.dashboardBlue)

                            Text(insight.insight)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }
}

// MARK: - Capture Patterns Card

struct CapturePattersCard: View {
    let patterns: [CapturePattern]
    @State private var isExpanded = false

    var body: some View {
        CardContainer {
            VStack(spacing: 12) {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isExpanded.toggle()
                    }
                    FeedbackManager.shared.selectionHaptic()
                } label: {
                    HStack {
                        Image(systemName: "target")
                            .foregroundStyle(Color.error)

                        Text("Capture Patterns")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)

                        Spacer()

                        Text("\(patterns.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)

                if isExpanded {
                    Divider()

                    ForEach(patterns) { pattern in
                        HStack {
                            Text(pattern.pattern)
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Spacer()

                            if let rate = pattern.successRate {
                                Text(String(format: "%.0f%%", rate * 100))
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(rate > 0.5 ? Color.success : Color.warning)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }
}

// MARK: - History Version Row

struct HistoryVersionRow: View {
    let version: LearningHistoryResponse.HistoryVersion

    var body: some View {
        HStack(spacing: 12) {
            // Version number
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(version.isActive ? Color.learnPurple.opacity(0.15) : Color.cardBackground)
                    .frame(width: 40, height: 40)

                Text("v\(version.version)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(version.isActive ? Color.learnPurple : .secondary)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(version.generatedAt)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    if version.isActive {
                        StatusBadge(status: "Active", color: .success)
                    }
                }

                HStack(spacing: 8) {
                    Text("\(version.gamesAnalyzed) games")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let winRate = version.winRateBefore {
                        Text("•")
                            .foregroundStyle(.tertiary)

                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.learnPurple)
                                .frame(width: 6, height: 6)
                            Text("AI: \(Int(winRate))%")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Spacer()
        }
        .padding(12)
        .background(Color.cardBackground)
        .cornerRadius(12)
    }
}

// MARK: - Preview
#Preview {
    LearnView()
}
