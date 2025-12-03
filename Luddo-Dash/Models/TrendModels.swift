//
//  TrendModels.swift
//  Luddo-Dash
//
//  API Models for /trends endpoints
//

import Foundation

// MARK: - Hourly Trends Response (/trends/hourly)
struct HourlyTrendsResponse: Codable {
    let timestamp: String
    let requestedHours: Int
    let dataPoints: Int
    let trends: [HourlyTrend]
}

struct HourlyTrend: Codable, Identifiable {
    var id: String { hour }

    let hour: String
    let visitors: Visitors
    let games: Games
    let aiPerformance: AIPerf
    let avgGameDurationSeconds: Double?

    struct Visitors: Codable {
        let total: Int
        let unique: Int
    }

    struct Games: Codable {
        let started: Int
        let completed: Int
        let abandoned: Int
        let local: Int
        let ai: Int
    }

    struct AIPerf: Codable {
        let aiWins: Int
        let humanWins: Int
        let totalDecisions: Int
        let avgDecisionTimeMs: Double?
    }
}

// MARK: - Daily Trends Response (/trends/daily)
struct DailyTrendsResponse: Codable {
    let timestamp: String
    let requestedDays: Int
    let dataPoints: Int
    let trends: [DailyTrend]
}

struct DailyTrend: Codable, Identifiable {
    var id: String { date }

    let date: String
    let visitors: Visitors
    let games: Games
    let aiPerformance: AIPerf
    let avgGameDurationSeconds: Double?

    struct Visitors: Codable {
        let total: Int
        let unique: Int
        let peakConcurrent: Int
    }

    struct Games: Codable {
        let started: Int
        let completed: Int
        let abandoned: Int
        let local: Int
        let ai: Int
        let byPlayerCount: [String: Int]
    }

    struct AIPerf: Codable {
        let aiWins: Int
        let humanWins: Int
        let totalDecisions: Int
        let avgDecisionTimeMs: Double?
    }
}

// MARK: - Growth Comparison (/trends/growth)
struct GrowthComparison: Codable {
    let timestamp: String
    let comparison: String
    let current: PeriodStats
    let previous: PeriodStats
    let growthPercent: GrowthPercent

    struct PeriodStats: Codable {
        let period: String
        let visitors: Int
        let games: Int
        let aiGames: Int
    }

    struct GrowthPercent: Codable {
        let visitors: Int
        let games: Int
        let aiGames: Int
    }
}
