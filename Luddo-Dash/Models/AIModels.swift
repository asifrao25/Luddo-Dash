//
//  AIModels.swift
//  Luddo-Dash
//
//  API Models for /ai endpoints
//

import Foundation

// MARK: - AI Stats (/ai/stats)
struct AIStats: Codable {
    let timestamp: String
    let period: String
    let winRates: WinRates
    let decisions: Decisions
    let engines: Engines

    struct WinRates: Codable {
        let humanWins: Int
        let aiWins: Int
        let totalGames: Int
        let humanWinRate: Int
        let aiWinRate: Int
    }

    struct Decisions: Codable {
        let total: Int
        let timing: Timing
        let avgConfidence: Double
        let byPhase: [String: PhaseStats]

        struct Timing: Codable {
            let avgMs: Int
            let p50Ms: Int
            let p95Ms: Int
            let p99Ms: Int
        }

        struct PhaseStats: Codable {
            let count: Int
            let avgTimeMs: Int
        }
    }

    struct Engines: Codable {
        let minimax: MinimaxStats
        let monteCarlo: MonteCarloStats

        struct MinimaxStats: Codable {
            let avgNodesEvaluated: Int
        }

        struct MonteCarloStats: Codable {
            let avgSimulations: Int
        }
    }
}

// MARK: - AI Decisions Response (/ai/decisions)
struct AIDecisionsResponse: Codable {
    let timestamp: String
    let count: Int
    let decisions: [AIDecision]
}

struct AIDecision: Codable, Identifiable {
    var id: String { "\(gameId)-\(timestamp)" }

    let gameId: String
    let turnNumber: Int?
    let diceValue: Int
    let validMoves: Int
    let selectedToken: Int
    let confidence: Double?
    let phase: String?
    let timing: Timing
    let minimax: Minimax
    let monteCarlo: MonteCarlo
    let timestamp: String

    struct Timing: Codable {
        let totalMs: Double
        let heuristicMs: Double?
        let minimaxMs: Double?
        let montecarloMs: Double?
        let safetyMs: Double?
    }

    struct Minimax: Codable {
        let nodesEvaluated: Int?
        let depthReached: Int?
    }

    struct MonteCarlo: Codable {
        let simulations: Int?
        let avgPlayoutLength: Double?
    }
}
