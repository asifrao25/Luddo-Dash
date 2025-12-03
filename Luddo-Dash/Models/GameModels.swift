//
//  GameModels.swift
//  Luddo-Dash
//
//  API Models for /games endpoints
//

import Foundation

// MARK: - Game Stats Response (/games/stats)
struct GameStatsResponse: Codable {
    let timestamp: String
    let period: String
    let gameType: String
    let stats: Stats

    struct Stats: Codable {
        let total: Int
        let completed: Int
        let abandoned: Int
        let local: Int
        let ai: Int
        let avgDurationSeconds: Int
        let byPlayerCount: [String: Int]
        let aiWins: Int
        let humanWins: Int
    }
}

// MARK: - Recent Games Response (/games/recent)
struct RecentGamesResponse: Codable {
    let timestamp: String
    let count: Int
    let games: [RecentGame]
}

struct RecentGame: Codable, Identifiable {
    let id: String
    let type: String
    let playerCount: Int
    let aiDifficulty: String?
    let status: String
    let winnerType: String?
    let winnerName: String?
    let durationSeconds: Int?
    let totalTurns: Int
    let startedAt: String
    let endedAt: String?
}

// MARK: - Saved Games Stats (/games/saved)
struct SavedGamesStats: Codable {
    let timestamp: String
    let period: String
    let stats: Stats

    struct Stats: Codable {
        let totalSaved: Int
        let totalResumed: Int
        let resumeRate: Int
        let byType: GameTypes
    }

    struct GameTypes: Codable {
        let local: Int
        let ai: Int
    }
}
