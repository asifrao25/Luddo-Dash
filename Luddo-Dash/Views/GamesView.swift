//
//  GamesView.swift
//  Luddo-Dash
//
//  Tab 2: Games statistics
//

import SwiftUI
import Combine

// MARK: - Games View Model
@MainActor
class GamesViewModel: ObservableObject {
    @Published var gameStats: GameStatsResponse?
    @Published var recentGames: RecentGamesResponse?
    @Published var savedGames: SavedGamesStats?
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
        if gameStats == nil {
            isLoading = true
        }
        error = nil

        do {
            async let statsTask = api.gameStats(period: selectedPeriod)
            async let recentTask = api.recentGames(limit: 10)
            async let savedTask = api.savedGames(period: selectedPeriod)

            let (statsResult, recentResult, savedResult) = try await (
                statsTask,
                recentTask,
                savedTask
            )

            withAnimation(.easeInOut(duration: 0.3)) {
                self.gameStats = statsResult
                self.recentGames = recentResult
                self.savedGames = savedResult
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

// MARK: - Games View
struct GamesView: View {
    @StateObject private var viewModel = GamesViewModel()

    var body: some View {
        PageWithHeader(
            title: "Games",
            subtitle: "Statistics & history",
            color: .gamesTeal
        ) {
            if viewModel.isLoading && viewModel.gameStats == nil {
                LoadingView("Loading games...")
                    .frame(height: 400)
            } else if let error = viewModel.error, viewModel.gameStats == nil {
                ErrorView(error) {
                    Task { await viewModel.refresh() }
                }
                .frame(height: 400)
            } else {
                gamesContent
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
    private var gamesContent: some View {
        VStack(spacing: 20) {
            // Period Picker
            periodPicker

            // Game Stats Overview
            if let stats = viewModel.gameStats {
                SectionHeader("Overview", icon: "chart.bar.fill")
                statsOverview(stats: stats)

                // Game Type Breakdown
                SectionHeader("Game Types", icon: "rectangle.split.2x1.fill")
                gameTypeCards(stats: stats)

                // Player Count Distribution
                SectionHeader("Players", icon: "person.3.fill")
                playerCountChart(stats: stats)
            }

            // Saved Games Stats
            if let saved = viewModel.savedGames {
                SectionHeader("Saved Games", icon: "square.and.arrow.down.fill")
                savedGamesCard(saved: saved)
            }

            // Recent Games
            if let recent = viewModel.recentGames, !recent.games.isEmpty {
                SectionHeader("Recent Games", icon: "clock.fill")
                recentGamesList(games: recent.games)
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
                                ? Color.gamesTeal
                                : Color.cardBackground
                        )
                        .cornerRadius(8)
                }
            }
        }
    }

    @ViewBuilder
    private func statsOverview(stats: GameStatsResponse) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            MetricCard(
                title: "Total Games",
                value: "\(stats.stats.total)",
                icon: "gamecontroller.fill",
                color: .gamesTeal
            )

            MetricCard(
                title: "Completed",
                value: "\(stats.stats.completed)",
                icon: "checkmark.circle.fill",
                color: .success,
                subtitle: "\(stats.stats.abandoned) abandoned"
            )

            MetricCard(
                title: "Human Wins",
                value: "\(stats.stats.humanWins)",
                icon: "person.fill",
                color: .dashboardBlue
            )

            MetricCard(
                title: "AI Wins",
                value: "\(stats.stats.aiWins)",
                icon: "brain.fill",
                color: .aiIndigo
            )
        }
    }

    @ViewBuilder
    private func gameTypeCards(stats: GameStatsResponse) -> some View {
        HStack(spacing: 12) {
            // Local Games Card
            VStack(spacing: 8) {
                Image(systemName: "person.2.fill")
                    .font(.title2)
                    .foregroundStyle(Color.dashboardBlue)

                Text("\(stats.stats.local)")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Local Games")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(Color.cardBackground)
            .cornerRadius(12)

            // AI Games Card
            VStack(spacing: 8) {
                Image(systemName: "brain.head.profile")
                    .font(.title2)
                    .foregroundStyle(Color.aiIndigo)

                Text("\(stats.stats.ai)")
                    .font(.title)
                    .fontWeight(.bold)

                Text("AI Games")
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
    private func playerCountChart(stats: GameStatsResponse) -> some View {
        CardContainer {
            VStack(spacing: 12) {
                ForEach(Array(stats.stats.byPlayerCount.sorted(by: { $0.key < $1.key })), id: \.key) { players, count in
                    HStack {
                        Text("\(players) Players")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Spacer()

                        // Progress bar
                        GeometryReader { geo in
                            let maxCount = stats.stats.byPlayerCount.values.max() ?? 1
                            let width = geo.size.width * CGFloat(count) / CGFloat(maxCount)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gamesTeal.opacity(0.3))
                                .frame(height: 8)
                                .overlay(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.gamesTeal)
                                        .frame(width: width, height: 8)
                                }
                        }
                        .frame(width: 100, height: 8)

                        Text("\(count)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .frame(width: 40, alignment: .trailing)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func savedGamesCard(saved: SavedGamesStats) -> some View {
        CardContainer {
            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("\(saved.stats.totalSaved)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Saved")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Divider()
                    .frame(height: 40)

                VStack(spacing: 4) {
                    Text("\(saved.stats.totalResumed)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Resumed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Divider()
                    .frame(height: 40)

                VStack(spacing: 4) {
                    Text("\(saved.stats.resumeRate)%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.gamesTeal)
                    Text("Resume Rate")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private func recentGamesList(games: [RecentGame]) -> some View {
        VStack(spacing: 8) {
            ForEach(games) { game in
                GameListItem(game: game)
            }
        }
    }
}

// MARK: - Game List Item
struct GameListItem: View {
    let game: RecentGame

    var body: some View {
        HStack(spacing: 12) {
            // Game type icon
            Image(systemName: game.type == "ai" ? "brain.fill" : "person.2.fill")
                .font(.title3)
                .foregroundStyle(game.type == "ai" ? Color.aiIndigo : Color.dashboardBlue)
                .frame(width: 40, height: 40)
                .background(
                    (game.type == "ai" ? Color.aiIndigo : Color.dashboardBlue).opacity(0.1)
                )
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("\(game.playerCount) Players")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    if let difficulty = game.aiDifficulty {
                        Text(difficulty.capitalized)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.cardBackground)
                            .cornerRadius(4)
                    }
                }

                Text(formatDate(game.startedAt))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            // Status badge
            StatusBadge(
                status: game.status.capitalized,
                color: statusColor(for: game.status)
            )
        }
        .padding(12)
        .background(Color.cardBackground)
        .cornerRadius(12)
    }

    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else { return dateString }

        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .short
        displayFormatter.timeStyle = .short
        return displayFormatter.string(from: date)
    }

    private func statusColor(for status: String) -> Color {
        switch status.lowercased() {
        case "completed": return .success
        case "in_progress", "inprogress": return .dashboardBlue
        case "abandoned": return .warning
        default: return .secondary
        }
    }
}

// MARK: - Preview
#Preview {
    GamesView()
}
