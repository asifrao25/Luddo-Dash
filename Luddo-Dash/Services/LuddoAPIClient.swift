//
//  LuddoAPIClient.swift
//  Luddo-Dash
//
//  Network layer for Luddo Metrics API
//

import Foundation
import SwiftUI

// MARK: - API Errors
enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case decodingError(Error)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Reset Response
struct ResetResponse: Decodable {
    let success: Bool
    let message: String
    let deletedCount: Int?
}

// MARK: - Reset Type
enum ResetType: String, CaseIterable, Identifiable {
    case all = "all"
    case games = "games"
    case ai = "ai"
    case sessions = "sessions"
    case trends = "trends"
    case system = "system"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .all: return "All Data"
        case .games: return "Games"
        case .ai: return "AI Decisions"
        case .sessions: return "Sessions"
        case .trends: return "Trends"
        case .system: return "System Metrics"
        }
    }

    var icon: String {
        switch self {
        case .all: return "trash.fill"
        case .games: return "gamecontroller.fill"
        case .ai: return "brain.fill"
        case .sessions: return "person.2.fill"
        case .trends: return "chart.line.uptrend.xyaxis"
        case .system: return "cpu.fill"
        }
    }

    var color: Color {
        switch self {
        case .all: return .error
        case .games: return .gamesTeal
        case .ai: return .aiIndigo
        case .sessions: return .dashboardBlue
        case .trends: return .warning
        case .system: return .systemPink
        }
    }
}

// MARK: - API Client
@MainActor
class LuddoAPIClient: ObservableObject {
    static let shared = LuddoAPIClient()

    private let baseURL = "https://luddo-api.asifrao.com"
    private let apiKey = "luddo_metrics_2024_secure_key"
    private let adminKey = "luddo_admin_2024_secure_key"

    private init() {}

    // MARK: - Generic Request

    private func request<T: Decodable>(
        endpoint: String,
        requiresAuth: Bool = true
    ) async throws -> T {
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if requiresAuth {
            request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            guard httpResponse.statusCode == 200 else {
                throw APIError.httpError(httpResponse.statusCode)
            }

            do {
                let decoder = JSONDecoder()
                return try decoder.decode(T.self, from: data)
            } catch {
                throw APIError.decodingError(error)
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }

    // MARK: - Health & Status (2 endpoints)

    /// GET /health - Basic health check (no auth)
    func health() async throws -> HealthResponse {
        try await request(endpoint: "/health", requiresAuth: false)
    }

    /// GET /status - Detailed server status with DB stats
    func status() async throws -> StatusResponse {
        try await request(endpoint: "/status")
    }

    // MARK: - Metrics (2 endpoints)

    /// GET /metrics/realtime - Real-time visitor and game counts
    func realtime() async throws -> RealtimeMetrics {
        try await request(endpoint: "/metrics/realtime")
    }

    /// GET /metrics/summary - Summary statistics
    func summary(period: String = "today") async throws -> SummaryMetrics {
        try await request(endpoint: "/metrics/summary?period=\(period)")
    }

    // MARK: - Games (3 endpoints)

    /// GET /games/stats - Game statistics
    func gameStats(period: String = "all", type: String? = nil) async throws -> GameStatsResponse {
        var endpoint = "/games/stats?period=\(period)"
        if let type = type {
            endpoint += "&type=\(type)"
        }
        return try await request(endpoint: endpoint)
    }

    /// GET /games/recent - Recent games list
    func recentGames(limit: Int = 20) async throws -> RecentGamesResponse {
        try await request(endpoint: "/games/recent?limit=\(limit)")
    }

    /// GET /games/saved - Saved games statistics
    func savedGames(period: String = "all") async throws -> SavedGamesStats {
        try await request(endpoint: "/games/saved?period=\(period)")
    }

    // MARK: - AI (2 endpoints)

    /// GET /ai/stats - AI performance statistics
    func aiStats(period: String = "all") async throws -> AIStats {
        try await request(endpoint: "/ai/stats?period=\(period)")
    }

    /// GET /ai/decisions - Recent AI decisions
    func aiDecisions(limit: Int = 50) async throws -> AIDecisionsResponse {
        try await request(endpoint: "/ai/decisions?limit=\(limit)")
    }

    // MARK: - System (2 endpoints)

    /// GET /system/live - Live CPU, memory, network, disk
    func systemLive() async throws -> SystemMetrics {
        try await request(endpoint: "/system/live")
    }

    /// GET /system/history - Historical metrics
    func systemHistory(seconds: Int = 60) async throws -> SystemHistoryResponse {
        try await request(endpoint: "/system/history?seconds=\(seconds)")
    }

    // MARK: - Trends (3 endpoints)

    /// GET /trends/hourly - Hourly aggregates
    func hourlyTrends(hours: Int = 24) async throws -> HourlyTrendsResponse {
        try await request(endpoint: "/trends/hourly?hours=\(hours)")
    }

    /// GET /trends/daily - Daily aggregates
    func dailyTrends(days: Int = 30) async throws -> DailyTrendsResponse {
        try await request(endpoint: "/trends/daily?days=\(days)")
    }

    /// GET /trends/growth - Growth comparison
    func growth(compare: String = "week") async throws -> GrowthComparison {
        try await request(endpoint: "/trends/growth?compare=\(compare)")
    }

    // MARK: - Utilities (5 endpoints)

    /// GET /utils/version - API version and capabilities (no auth)
    func version() async throws -> VersionResponse {
        try await request(endpoint: "/utils/version", requiresAuth: false)
    }

    /// GET /utils/time - Server time in multiple formats
    func serverTime() async throws -> TimeResponse {
        try await request(endpoint: "/utils/time")
    }

    /// GET /utils/ping - Latency test with client info
    func ping() async throws -> PingResponse {
        try await request(endpoint: "/utils/ping")
    }

    /// GET /utils/location - Detect location from client IP
    func location() async throws -> LocationResponse {
        try await request(endpoint: "/utils/location")
    }

    /// GET /utils/location/:ip - Lookup location for specific IP
    func location(ip: String) async throws -> LocationResponse {
        try await request(endpoint: "/utils/location/\(ip)")
    }

    // MARK: - Live AI / GPT Mode (5 endpoints)

    /// GET /liveai/stats - Aggregate Live AI performance statistics
    func liveAIStats(period: String = "all") async throws -> LiveAIStats {
        try await request(endpoint: "/liveai/stats?period=\(period)")
    }

    /// GET /liveai/costs - Token usage, costs, and projections
    func liveAICosts(period: String = "month") async throws -> LiveAICosts {
        try await request(endpoint: "/liveai/costs?period=\(period)")
    }

    /// GET /liveai/decisions - Detailed per-turn decision logs
    func liveAIDecisions(limit: Int = 50, gameId: String? = nil) async throws -> LiveAIDecisionsResponse {
        var endpoint = "/liveai/decisions?limit=\(limit)"
        if let gameId = gameId {
            endpoint += "&gameId=\(gameId)"
        }
        return try await request(endpoint: endpoint)
    }

    /// GET /liveai/errors - Error tracking and recovery rates
    func liveAIErrors(period: String = "week", limit: Int = 100) async throws -> LiveAIErrorsResponse {
        try await request(endpoint: "/liveai/errors?period=\(period)&limit=\(limit)")
    }

    /// GET /liveai/games/recent - Recent Live AI games with outcomes
    func liveAIGamesRecent(limit: Int = 20) async throws -> LiveAIGamesResponse {
        try await request(endpoint: "/liveai/games/recent?limit=\(limit)")
    }

    // MARK: - Admin Reset (DELETE endpoints)

    /// Generic DELETE request for admin operations
    private func deleteRequest<T: Decodable>(endpoint: String) async throws -> T {
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(adminKey, forHTTPHeaderField: "X-API-Key")
        request.setValue(adminKey, forHTTPHeaderField: "X-Admin-Key")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            guard httpResponse.statusCode == 200 else {
                throw APIError.httpError(httpResponse.statusCode)
            }

            do {
                let decoder = JSONDecoder()
                return try decoder.decode(T.self, from: data)
            } catch {
                throw APIError.decodingError(error)
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }

    /// DELETE /admin/reset/:type - Reset specific data type
    func reset(type: ResetType) async throws -> ResetResponse {
        try await deleteRequest(endpoint: "/admin/reset/\(type.rawValue)")
    }

    /// DELETE /admin/reset/all - Reset ALL data (convenience method)
    func resetAll() async throws -> ResetResponse {
        try await reset(type: .all)
    }

    /// DELETE /admin/reset/liveai - Reset Live AI (GPT) data only
    func resetLiveAI() async throws -> ResetResponse {
        try await deleteRequest(endpoint: "/admin/reset/liveai")
    }
}
