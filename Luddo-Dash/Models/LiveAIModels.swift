//
//  LiveAIModels.swift
//  Luddo-Dash
//
//  Models for Live AI (GPT-powered) game analytics
//

import Foundation

// MARK: - Live AI Stats

struct LiveAIStats: Codable {
    let timestamp: String
    let period: String
    let games: GameStats
    let apiUsage: APIUsage
    let decisions: DecisionStats
    let outcomes: Outcomes

    struct GameStats: Codable {
        let total: Int
        let completed: Int
        let abandoned: Int
        let completionRate: Int
        let avgDurationMinutes: Int
        let allAIGames: Int
        let mixedGames: Int
    }

    struct APIUsage: Codable {
        let totalCalls: Int
        let totalTokens: Int
        let avgTokensPerGame: Int
        let avgTokensPerTurn: Int
        let estimatedCostUSD: Double
        let avgResponseTimeMs: Int
    }

    struct DecisionStats: Codable {
        let total: Int
        let parseSuccess: ParseSuccess
        let avgConfidence: Double
        let errorRate: Double

        struct ParseSuccess: Codable {
            let json: Int
            let pattern: Int
            let digit: Int
            let fallback: Int
        }
    }

    struct Outcomes: Codable {
        let humanWins: Int
        let aiWins: Int
        let humanWinRate: Int
    }
}

// MARK: - Live AI Costs

struct LiveAICosts: Codable {
    let timestamp: String
    let period: String
    let model: String
    let pricing: Pricing
    let usage: Usage
    let costs: Costs
    let projections: Projections
    let perGameBreakdown: [GameCost]?

    struct Pricing: Codable {
        let inputPer1kTokens: Double
        let outputPer1kTokens: Double
    }

    struct Usage: Codable {
        let totalInputTokens: Int
        let totalOutputTokens: Int
        let totalCalls: Int
    }

    struct Costs: Codable {
        let inputCostUSD: Double
        let outputCostUSD: Double
        let totalCostUSD: Double
        let avgCostPerGame: Double
        let avgCostPerTurn: Double
    }

    struct Projections: Codable {
        let dailyAvgGames: Int
        let projectedMonthlyCost: Double
        let projectedYearlyCost: Double
    }

    struct GameCost: Codable {
        let gameId: String
        let date: String
        let totalTokens: Int
        let costUSD: Double
        let turns: Int
    }
}

// MARK: - Live AI Decisions

struct LiveAIDecisionsResponse: Codable {
    let timestamp: String
    let count: Int
    let decisions: [LiveAIDecision]
}

struct LiveAIDecision: Codable, Identifiable {
    let id: String
    let gameId: String
    let turnNumber: Int
    let playerColor: String
    let playerName: String
    let diceValue: Int
    let validMoves: [Int]
    let selectedToken: Int
    let parseStrategy: String
    let confidence: Double
    let tokensUsed: TokensUsed
    let responseTimeMs: Int
    let moveOutcome: String?
    let retryAttempts: Int
    let timestamp: String

    struct TokensUsed: Codable {
        let prompt: Int
        let completion: Int
        let total: Int
    }
}

// MARK: - Live AI Errors

struct LiveAIErrorsResponse: Codable {
    let timestamp: String
    let period: String
    let summary: ErrorSummary
    let recentErrors: [LiveAIError]

    struct ErrorSummary: Codable {
        let totalErrors: Int
        let errorRate: Double
        let byType: [String: Int]
        let recoveryRate: Int
    }
}

struct LiveAIError: Codable, Identifiable {
    var id: String { "\(gameId)-\(turnNumber)-\(timestamp)" }

    let gameId: String
    let turnNumber: Int
    let errorCode: String
    let errorMessage: String
    let retryAttempts: Int
    let recovered: Bool
    let timestamp: String
}

// MARK: - Live AI Games

struct LiveAIGamesResponse: Codable {
    let timestamp: String
    let count: Int
    let games: [LiveAIGame]
}

struct LiveAIGame: Codable, Identifiable {
    let id: String
    let startedAt: String
    let endedAt: String?
    let durationMinutes: Int?
    let status: String
    let playerCount: Int
    let players: [Player]
    let winner: Player?
    let totalTurns: Int
    let aiTurns: Int
    let totalTokensUsed: Int
    let totalAPICalls: Int
    let totalErrors: Int
    let estimatedCostUSD: Double

    struct Player: Codable {
        let color: String
        let name: String
        let type: String  // "human" or "openai"
    }
}

// MARK: - Helper Extensions

extension LiveAIDecision {
    /// Returns the color for the parse strategy badge
    var parseStrategyColor: String {
        switch parseStrategy.lowercased() {
        case "json": return "green"
        case "pattern": return "blue"
        case "digit": return "yellow"
        case "fallback": return "red"
        default: return "gray"
        }
    }

    /// Returns formatted confidence percentage
    var confidencePercent: String {
        String(format: "%.0f%%", confidence * 100)
    }
}

extension LiveAIGame {
    /// Returns true if this is an all-AI game (no human players)
    var isAllAIGame: Bool {
        players.allSatisfy { $0.type == "openai" }
    }

    /// Returns the count of AI players in the game
    var aiPlayerCount: Int {
        players.filter { $0.type == "openai" }.count
    }

    /// Returns the count of human players in the game
    var humanPlayerCount: Int {
        players.filter { $0.type == "human" }.count
    }
}

extension LiveAIStats.DecisionStats.ParseSuccess {
    /// Total successful parses across all strategies
    var total: Int {
        json + pattern + digit + fallback
    }

    /// Percentage for each strategy (returns tuple of percentages)
    func percentages() -> (json: Double, pattern: Double, digit: Double, fallback: Double) {
        let t = Double(total)
        guard t > 0 else { return (0, 0, 0, 0) }
        return (
            json: Double(json) / t * 100,
            pattern: Double(pattern) / t * 100,
            digit: Double(digit) / t * 100,
            fallback: Double(fallback) / t * 100
        )
    }
}
