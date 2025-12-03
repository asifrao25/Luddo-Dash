//
//  MetricsModels.swift
//  Luddo-Dash
//
//  API Models for /metrics endpoints
//

import Foundation

// MARK: - Real-time Metrics (/metrics/realtime)
struct RealtimeMetrics: Codable {
    let timestamp: String
    let visitors: Visitors
    let games: GamesInProgress

    struct Visitors: Codable {
        let active: Int
        let byPage: [String: Int]
        let byDevice: [String: Int]
    }

    struct GamesInProgress: Codable {
        let inProgress: Int
        let byType: GameTypes
    }

    struct GameTypes: Codable {
        let local: Int
        let ai: Int
    }
}

// MARK: - Summary Metrics (/metrics/summary)
struct SummaryMetrics: Codable {
    let timestamp: String
    let period: String
    let realtime: Realtime
    let visitors: VisitorStats
    let games: GameStats
    let aiPerformance: AIPerformance

    struct Realtime: Codable {
        let activeVisitors: Int
        let gamesInProgress: Int
    }

    struct VisitorStats: Codable {
        let uniqueToday: Int
    }

    struct GameStats: Codable {
        let total: Int
        let completed: Int
        let abandoned: Int
        let completionRate: Int
        let local: Int
        let ai: Int
        let avgDurationMinutes: Int
        let byPlayerCount: [String: Int]
    }

    struct AIPerformance: Codable {
        let humanWins: Int
        let aiWins: Int
        let aiWinRate: Int
        let totalDecisions: Int
        let avgDecisionTimeMs: Int
    }
}
