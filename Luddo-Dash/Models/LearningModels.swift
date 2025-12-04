//
//  LearningModels.swift
//  Luddo-Dash
//
//  Models for AI Learning System endpoints
//

import Foundation

// MARK: - Learning Insights Response
struct LearningInsightsResponse: Decodable {
    let status: String  // "active" or "no_insights"
    let insights: LearningInsightsData?
    let promptAddition: String
    let message: String?

    var hasInsights: Bool {
        status == "active" && insights != nil
    }
}

// MARK: - Learning Insights Data
struct LearningInsightsData: Decodable {
    let generatedAt: String
    let periodStart: String
    let periodEnd: String
    let gamesAnalyzed: Int
    let version: Int
    let insights: PatternInsights
    let metadata: InsightsMetadata

    struct PatternInsights: Decodable {
        let capturePatterns: [CapturePattern]
        let diceStrategies: [DiceStrategy]
        let phaseStrategies: [PhaseStrategy]
        let positionInsights: [PositionInsight]
        let generalTips: [String]
    }

    struct InsightsMetadata: Decodable {
        let aiWinRate: Double
        let humanWinRate: Double
        let avgGameDuration: Double
        let totalDecisionsAnalyzed: Int
    }
}

// MARK: - Pattern Types
struct CapturePattern: Decodable, Identifiable {
    var id: String { pattern }
    let pattern: String
    let successRate: Double?
    let occurrences: Int?

    enum CodingKeys: String, CodingKey {
        case pattern, successRate, occurrences
    }
}

struct DiceStrategy: Decodable, Identifiable {
    var id: Int { diceValue }
    let diceValue: Int
    let pattern: String
    let winCorrelation: Double
    let sampleSize: Int
    let confidence: Double
}

struct PhaseStrategy: Decodable, Identifiable {
    var id: String { phase }
    let phase: String
    let pattern: String
    let effectiveness: Double
    let sampleSize: Int
    let confidence: Double
}

struct PositionInsight: Decodable, Identifiable {
    var id: Int { position }
    let position: Int
    let insight: String
    let winRate: Double
    let sampleSize: Int
}

// MARK: - Insights History Response
struct LearningHistoryResponse: Decodable {
    let timestamp: String
    let count: Int
    let history: [HistoryVersion]

    struct HistoryVersion: Decodable, Identifiable {
        let id: Int
        let generatedAt: String
        let gamesAnalyzed: Int
        let version: Int
        let isActive: Bool
        let winRateBefore: Double?
        let winRateAfter: Double?
    }
}

// MARK: - Analyze Response (Manual Trigger)
struct AnalyzeResponse: Decodable {
    let status: String
    let message: String
    let insightId: Int?
    let version: Int?
    let gamesAnalyzed: Int?
    let tipsGenerated: Int?
    let metadata: AnalyzeMetadata?

    struct AnalyzeMetadata: Decodable {
        let aiWinRate: Double?
        let humanWinRate: Double?
        let avgGameDuration: Double?
        let totalDecisionsAnalyzed: Int?
    }

    var isSuccess: Bool {
        status == "success"
    }
}
