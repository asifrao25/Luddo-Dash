# Luddo Metrics API - iOS Integration Guide

Complete API documentation for integrating with the Luddo Metrics API from iOS applications.

## Quick Reference

| Item | Value |
|------|-------|
| **Base URL** | `https://luddo-api.asifrao.com` |
| **API Key** | `luddo_metrics_2024_secure_key` |
| **Admin Key** | `luddo_admin_2024_secure_key` |
| **Auth Header** | `X-API-Key` |
| **Rate Limit (Read)** | 100 requests/minute |
| **Rate Limit (Write)** | 1000 requests/minute |

---

## Authentication

All endpoints (except `/health` and `/utils/version`) require the `X-API-Key` header:

```swift
let headers = ["X-API-Key": "luddo_metrics_2024_secure_key"]
```

---

## API Endpoints Summary

### Health & Status
| Endpoint | Auth | Description |
|----------|------|-------------|
| `GET /health` | No | Basic health check |
| `GET /status` | Yes | Detailed server status with DB stats |

### Metrics
| Endpoint | Auth | Description |
|----------|------|-------------|
| `GET /metrics/realtime` | Yes | Real-time visitor and game counts |
| `GET /metrics/summary?period=today\|week\|month\|all` | Yes | Summary statistics |

### Games
| Endpoint | Auth | Description |
|----------|------|-------------|
| `GET /games/stats?period=&type=` | Yes | Game statistics |
| `GET /games/recent?limit=20` | Yes | Recent games list |
| `GET /games/saved?period=` | Yes | Saved games statistics |

### AI
| Endpoint | Auth | Description |
|----------|------|-------------|
| `GET /ai/stats?period=` | Yes | AI performance statistics |
| `GET /ai/decisions?limit=50` | Yes | Recent AI decisions |

### System
| Endpoint | Auth | Description |
|----------|------|-------------|
| `GET /system/live` | Yes | Live CPU, memory, network, disk |
| `GET /system/history?seconds=60` | Yes | Historical metrics (max 300s) |

### Trends
| Endpoint | Auth | Description |
|----------|------|-------------|
| `GET /trends/hourly?hours=24` | Yes | Hourly aggregates (max 168h) |
| `GET /trends/daily?days=30` | Yes | Daily aggregates (max 365d) |
| `GET /trends/growth?compare=week\|month` | Yes | Growth comparison |

### Utilities (NEW)
| Endpoint | Auth | Description |
|----------|------|-------------|
| `GET /utils/version` | No | API version and capabilities |
| `GET /utils/time` | Yes | Server time in multiple formats |
| `GET /utils/ping` | Yes | Latency test with client info |
| `GET /utils/location` | Yes | Detect location from client IP |
| `GET /utils/location/:ip` | Yes | Lookup location for specific IP |

### Admin (Requires Admin Key)
| Endpoint | Description |
|----------|-------------|
| `DELETE /admin/reset/all` | Reset ALL data |
| `DELETE /admin/reset/games` | Reset game data only |
| `DELETE /admin/reset/ai` | Reset AI decision data |
| `DELETE /admin/reset/sessions` | Reset session data |
| `DELETE /admin/reset/trends` | Reset hourly/daily aggregates |
| `DELETE /admin/reset/system` | Reset system metrics |

---

## Detailed Endpoint Documentation

### 1. Health Check (No Auth)
```
GET /health
```
**Response:**
```json
{
  "status": "healthy",
  "timestamp": "2025-11-27T19:13:35.193Z",
  "uptime": 72715.277
}
```

### 2. Server Status
```
GET /status
```
**Response:**
```json
{
  "status": "healthy",
  "timestamp": "2025-11-27T19:08:32.156Z",
  "uptime": 72715.975,
  "version": "1.0.0",
  "memory": {
    "heapUsed": 19,
    "heapTotal": 23,
    "external": 2,
    "rss": 89
  },
  "database": {
    "sizeBytes": 331776,
    "sizeMB": 0.32,
    "tables": {
      "sessions": 40,
      "games": 11,
      "game_events": 0,
      "ai_decisions": 520,
      "hourly_stats": 3,
      "daily_stats": 1,
      "saved_games": 5,
      "system_metrics": 300
    }
  }
}
```

### 3. Real-time Metrics
```
GET /metrics/realtime
```
**Response:**
```json
{
  "timestamp": "2025-11-27T19:08:33.277Z",
  "visitors": {
    "active": 5,
    "byPage": { "game": 4, "home": 1 },
    "byDevice": { "mobile": 3, "desktop": 2 }
  },
  "games": {
    "inProgress": 2,
    "byType": { "local": 1, "ai": 1 }
  }
}
```

### 4. Summary Metrics
```
GET /metrics/summary?period=today|week|month|all
```
**Response:**
```json
{
  "timestamp": "2025-11-27T19:08:44.145Z",
  "period": "all",
  "realtime": {
    "activeVisitors": 5,
    "gamesInProgress": 2
  },
  "visitors": {
    "uniqueToday": 15
  },
  "games": {
    "total": 42,
    "completed": 35,
    "abandoned": 7,
    "completionRate": 83,
    "local": 20,
    "ai": 22,
    "avgDurationMinutes": 8,
    "byPlayerCount": { "2": 15, "3": 12, "4": 15 }
  },
  "aiPerformance": {
    "humanWins": 12,
    "aiWins": 10,
    "aiWinRate": 45,
    "totalDecisions": 450,
    "avgDecisionTimeMs": 125
  }
}
```

### 5. IP Location Detection (NEW)
```
GET /utils/location
```
**Response:**
```json
{
  "timestamp": "2025-11-27T19:13:40.112Z",
  "ip": "2a0a:ef40:19b6:f001:be24:11ff:fe85:825f",
  "location": {
    "country": "United Kingdom",
    "countryCode": "GB",
    "region": "England",
    "regionCode": "ENG",
    "city": "Birmingham",
    "zipCode": "B18",
    "latitude": 52.4867,
    "longitude": -1.8989,
    "timezone": "Europe/London"
  },
  "network": {
    "isp": "Vodafone Limited",
    "organization": "Vodafone DYN IP",
    "asn": "AS5378 Vodafone Limited"
  }
}
```

### 6. IP Location Lookup for Specific IP (NEW)
```
GET /utils/location/:ip
```
**Example:** `GET /utils/location/8.8.8.8`

**Response:**
```json
{
  "timestamp": "2025-11-27T19:13:48.555Z",
  "ip": "8.8.8.8",
  "location": {
    "country": "United States",
    "countryCode": "US",
    "region": "Virginia",
    "regionCode": "VA",
    "city": "Ashburn",
    "zipCode": "20149",
    "latitude": 39.03,
    "longitude": -77.5,
    "timezone": "America/New_York"
  },
  "network": {
    "isp": "Google LLC",
    "organization": "Google Public DNS",
    "asn": "AS15169 Google LLC"
  }
}
```

### 7. Server Time (NEW)
```
GET /utils/time
```
**Response:**
```json
{
  "timestamp": "2025-11-27T19:13:36.492Z",
  "unix": 1764270816,
  "unixMs": 1764270816492,
  "utc": {
    "year": 2025,
    "month": 11,
    "day": 27,
    "hour": 19,
    "minute": 13,
    "second": 36,
    "dayOfWeek": 4,
    "dayOfYear": 331
  },
  "formatted": {
    "iso": "2025-11-27T19:13:36.492Z",
    "date": "2025-11-27",
    "time": "19:13:36"
  },
  "serverTimezone": "UTC"
}
```

### 8. Ping / Latency Test (NEW)
```
GET /utils/ping
```
**Response:**
```json
{
  "pong": true,
  "timestamp": "2025-11-27T19:13:38.008Z",
  "serverTime": 1764270818008,
  "clientIP": "2a0a:ef40:19b6:f001:be24:11ff:fe85:825f",
  "headers": {
    "userAgent": "MyApp/1.0",
    "acceptLanguage": "en-US"
  }
}
```

### 9. API Version (No Auth - NEW)
```
GET /utils/version
```
**Response:**
```json
{
  "name": "Luddo Metrics API",
  "version": "1.0.0",
  "timestamp": "2025-11-27T19:13:35.193Z",
  "capabilities": [
    "health",
    "metrics",
    "games",
    "ai-stats",
    "system-monitoring",
    "trends",
    "ip-geolocation",
    "server-time"
  ],
  "endpoints": {
    "health": ["/health", "/status"],
    "metrics": ["/metrics/realtime", "/metrics/summary"],
    "games": ["/games/stats", "/games/recent", "/games/saved"],
    "ai": ["/ai/stats", "/ai/decisions"],
    "system": ["/system/live", "/system/history"],
    "trends": ["/trends/hourly", "/trends/daily", "/trends/growth"],
    "utils": ["/utils/location", "/utils/location/:ip", "/utils/time", "/utils/ping", "/utils/version"],
    "admin": ["/admin/reset/*"]
  }
}
```

### 10. System Live Metrics
```
GET /system/live
```
**Response:**
```json
{
  "timestamp": "2025-11-27T19:08:34.442Z",
  "cpu": {
    "usagePercent": 46.83,
    "load1m": 0.77,
    "load5m": 0.77,
    "load15m": 0.77
  },
  "memory": {
    "usedMB": 815,
    "freeMB": 7185,
    "totalMB": 8000,
    "percent": 10.18
  },
  "network": {
    "rxBytes": 258258332,
    "txBytes": 1426970201,
    "rxSpeed": 28942,
    "txSpeed": 4011471,
    "rxSpeedFormatted": "28.26 KB/s",
    "txSpeedFormatted": "3.83 MB/s"
  },
  "disk": {
    "readSpeed": 0,
    "writeSpeed": 55,
    "usagePercent": 50.74
  },
  "node": {
    "heapUsedMB": 19,
    "heapTotalMB": 23,
    "externalMB": 2,
    "eventLoopLagMs": 0
  }
}
```

---

## Swift API Client

```swift
import Foundation

class LuddoMetricsAPI {
    static let shared = LuddoMetricsAPI()

    private let baseURL = "https://luddo-api.asifrao.com"
    private let apiKey = "luddo_metrics_2024_secure_key"

    private init() {}

    // MARK: - Generic Request

    private func request<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        requiresAuth: Bool = true
    ) async throws -> T {
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if requiresAuth {
            request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(httpResponse.statusCode)
        }

        return try JSONDecoder().decode(T.self, from: data)
    }

    // MARK: - Health & Status

    func health() async throws -> HealthResponse {
        try await request(endpoint: "/health", requiresAuth: false)
    }

    func status() async throws -> StatusResponse {
        try await request(endpoint: "/status")
    }

    // MARK: - Metrics

    func realtime() async throws -> RealtimeMetrics {
        try await request(endpoint: "/metrics/realtime")
    }

    func summary(period: String = "today") async throws -> SummaryMetrics {
        try await request(endpoint: "/metrics/summary?period=\(period)")
    }

    // MARK: - Games

    func gameStats(period: String = "all", type: String? = nil) async throws -> GameStatsResponse {
        var endpoint = "/games/stats?period=\(period)"
        if let type = type { endpoint += "&type=\(type)" }
        return try await request(endpoint: endpoint)
    }

    func recentGames(limit: Int = 20) async throws -> RecentGamesResponse {
        try await request(endpoint: "/games/recent?limit=\(limit)")
    }

    func savedGamesStats(period: String = "all") async throws -> SavedGamesStats {
        try await request(endpoint: "/games/saved?period=\(period)")
    }

    // MARK: - AI

    func aiStats(period: String = "all") async throws -> AIStats {
        try await request(endpoint: "/ai/stats?period=\(period)")
    }

    func aiDecisions(limit: Int = 50) async throws -> AIDecisionsResponse {
        try await request(endpoint: "/ai/decisions?limit=\(limit)")
    }

    // MARK: - System

    func systemLive() async throws -> SystemMetrics {
        try await request(endpoint: "/system/live")
    }

    func systemHistory(seconds: Int = 60) async throws -> SystemHistoryResponse {
        try await request(endpoint: "/system/history?seconds=\(seconds)")
    }

    // MARK: - Trends

    func hourlyTrends(hours: Int = 24) async throws -> HourlyTrendsResponse {
        try await request(endpoint: "/trends/hourly?hours=\(hours)")
    }

    func dailyTrends(days: Int = 30) async throws -> DailyTrendsResponse {
        try await request(endpoint: "/trends/daily?days=\(days)")
    }

    func growth(compare: String = "week") async throws -> GrowthComparison {
        try await request(endpoint: "/trends/growth?compare=\(compare)")
    }

    // MARK: - Utilities (NEW)

    func version() async throws -> VersionResponse {
        try await request(endpoint: "/utils/version", requiresAuth: false)
    }

    func serverTime() async throws -> TimeResponse {
        try await request(endpoint: "/utils/time")
    }

    func ping() async throws -> PingResponse {
        try await request(endpoint: "/utils/ping")
    }

    func location() async throws -> LocationResponse {
        try await request(endpoint: "/utils/location")
    }

    func location(ip: String) async throws -> LocationResponse {
        try await request(endpoint: "/utils/location/\(ip)")
    }

    // MARK: - Error

    enum APIError: Error, LocalizedError {
        case invalidURL
        case invalidResponse
        case httpError(Int)

        var errorDescription: String? {
            switch self {
            case .invalidURL: return "Invalid URL"
            case .invalidResponse: return "Invalid response"
            case .httpError(let code): return "HTTP error: \(code)"
            }
        }
    }
}
```

---

## Swift Models

```swift
import Foundation

// MARK: - Health & Status

struct HealthResponse: Codable {
    let status: String
    let timestamp: String
    let uptime: Double
}

struct StatusResponse: Codable {
    let status: String
    let timestamp: String
    let uptime: Double
    let version: String
    let memory: MemoryInfo
    let database: DatabaseInfo

    struct MemoryInfo: Codable {
        let heapUsed: Int
        let heapTotal: Int
        let external: Int
        let rss: Int
    }

    struct DatabaseInfo: Codable {
        let sizeBytes: Int
        let sizeMB: Double
        let tables: [String: Int]
    }
}

// MARK: - Utilities (NEW)

struct VersionResponse: Codable {
    let name: String
    let version: String
    let timestamp: String
    let capabilities: [String]
    let endpoints: [String: [String]]
}

struct TimeResponse: Codable {
    let timestamp: String
    let unix: Int
    let unixMs: Int
    let utc: UTCTime
    let formatted: FormattedTime
    let serverTimezone: String

    struct UTCTime: Codable {
        let year: Int
        let month: Int
        let day: Int
        let hour: Int
        let minute: Int
        let second: Int
        let dayOfWeek: Int
        let dayOfYear: Int
    }

    struct FormattedTime: Codable {
        let iso: String
        let date: String
        let time: String
    }
}

struct PingResponse: Codable {
    let pong: Bool
    let timestamp: String
    let serverTime: Int
    let clientIP: String
    let headers: Headers

    struct Headers: Codable {
        let userAgent: String?
        let acceptLanguage: String?
    }
}

struct LocationResponse: Codable {
    let timestamp: String
    let ip: String
    let isPrivate: Bool?
    let location: Location?
    let network: Network?
    let message: String?
    let error: String?

    struct Location: Codable {
        let country: String
        let countryCode: String
        let region: String
        let regionCode: String
        let city: String
        let zipCode: String
        let latitude: Double
        let longitude: Double
        let timezone: String
    }

    struct Network: Codable {
        let isp: String
        let organization: String
        let asn: String
    }
}

// MARK: - Real-time Metrics

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

// MARK: - Summary

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

// MARK: - System Metrics

struct SystemMetrics: Codable {
    let timestamp: String
    let cpu: CPU
    let memory: Memory
    let network: Network
    let disk: Disk
    let node: NodeMetrics

    struct CPU: Codable {
        let usagePercent: Double
        let load1m: Double
        let load5m: Double
        let load15m: Double
    }

    struct Memory: Codable {
        let usedMB: Int
        let freeMB: Int
        let totalMB: Int
        let percent: Double
    }

    struct Network: Codable {
        let rxBytes: Int
        let txBytes: Int
        let rxSpeed: Int
        let txSpeed: Int
        let rxSpeedFormatted: String
        let txSpeedFormatted: String
    }

    struct Disk: Codable {
        let readSpeed: Int
        let writeSpeed: Int
        let usagePercent: Double
    }

    struct NodeMetrics: Codable {
        let heapUsedMB: Int
        let heapTotalMB: Int
        let externalMB: Int
        let eventLoopLagMs: Int
    }
}

// MARK: - AI Stats

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

// MARK: - Games

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

struct RecentGamesResponse: Codable {
    let timestamp: String
    let count: Int
    let games: [RecentGame]
}

struct RecentGame: Codable {
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

struct AIDecisionsResponse: Codable {
    let timestamp: String
    let count: Int
    let decisions: [AIDecision]
}

struct AIDecision: Codable {
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

// MARK: - Trends

struct SystemHistoryResponse: Codable {
    let timestamp: String
    let requestedSeconds: Int
    let dataPoints: Int
    let metrics: [MetricPoint]

    struct MetricPoint: Codable {
        let timestamp: String
        let cpu: Double
        let memoryPercent: Double
        let memoryUsedMB: Int
        let networkRxSpeed: Int
        let networkTxSpeed: Int
        let diskReadSpeed: Int
        let diskWriteSpeed: Int
        let nodeHeapUsedMB: Int
        let eventLoopLagMs: Int
    }
}

struct HourlyTrendsResponse: Codable {
    let timestamp: String
    let requestedHours: Int
    let dataPoints: Int
    let trends: [HourlyTrend]
}

struct HourlyTrend: Codable {
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

struct DailyTrendsResponse: Codable {
    let timestamp: String
    let requestedDays: Int
    let dataPoints: Int
    let trends: [DailyTrend]
}

struct DailyTrend: Codable {
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
```

---

## Usage Examples

### Basic Dashboard
```swift
import SwiftUI

struct DashboardView: View {
    @State private var summary: SummaryMetrics?
    @State private var location: LocationResponse?
    @State private var isLoading = true

    var body: some View {
        NavigationView {
            List {
                if let location = location?.location {
                    Section("Your Location") {
                        LabeledContent("Country", value: location.country)
                        LabeledContent("City", value: location.city)
                        LabeledContent("Timezone", value: location.timezone)
                    }
                }

                if let summary = summary {
                    Section("Real-time") {
                        LabeledContent("Active Visitors", value: "\(summary.realtime.activeVisitors)")
                        LabeledContent("Games in Progress", value: "\(summary.realtime.gamesInProgress)")
                    }

                    Section("Today's Stats") {
                        LabeledContent("Total Games", value: "\(summary.games.total)")
                        LabeledContent("Completion Rate", value: "\(summary.games.completionRate)%")
                    }
                }
            }
            .navigationTitle("Luddo Dashboard")
            .refreshable { await refresh() }
            .task { await refresh() }
        }
    }

    func refresh() async {
        do {
            async let summaryTask = LuddoMetricsAPI.shared.summary()
            async let locationTask = LuddoMetricsAPI.shared.location()

            summary = try await summaryTask
            location = try await locationTask
            isLoading = false
        } catch {
            print("Error: \(error)")
        }
    }
}
```

### Latency Monitoring
```swift
func measureLatency() async -> Double? {
    let start = Date()
    do {
        let response = try await LuddoMetricsAPI.shared.ping()
        let latency = Date().timeIntervalSince(start) * 1000 // ms
        print("Latency: \(latency)ms, Server Time: \(response.serverTime)")
        return latency
    } catch {
        print("Ping failed: \(error)")
        return nil
    }
}
```

---

## Error Handling

| Status Code | Meaning |
|-------------|---------|
| 200 | Success |
| 400 | Bad request (invalid parameters) |
| 401 | Missing or invalid API key |
| 403 | Admin access required |
| 429 | Rate limit exceeded |
| 503 | Service temporarily unavailable |

---

## IP Geolocation Service

The `/utils/location` endpoints use **ip-api.com** for geolocation:
- **Rate Limit:** 45 requests/minute (cached server-side for 1 hour)
- **Accuracy:** City-level (±10km typical)
- **Coverage:** Global
- **Private IPs:** Returns `isPrivate: true` with null location

---

## Notes

- All timestamps are in ISO 8601 format (UTC)
- System metrics collected every 1 second
- Historical system metrics: 300 seconds (5 minutes)
- Game/session data retained: 90 days
- Daily aggregates retained indefinitely
- Sessions auto-expire after 60 seconds without heartbeat
- IP geolocation cached for 1 hour to respect rate limits

---

# New API Endpoints for Live GPT Mode

These endpoints track and analyze the **Live AI Play** mode which uses OpenAI GPT models (gpt-4o-mini) for AI opponents.

## Quick Reference

| Item | Value |
|------|-------|
| **Base URL** | `https://luddo-api.asifrao.com` |
| **API Key** | `luddo_metrics_2024_secure_key` |
| **Admin Key** | `luddo_admin_2024_secure_key` |
| **Auth Header** | `X-API-Key` |

---

## Live AI Endpoints Summary

| Endpoint | Method | Auth | Description |
|----------|--------|------|-------------|
| `/liveai/stats` | GET | Yes | Aggregate Live AI performance statistics |
| `/liveai/costs` | GET | Yes | Token usage, costs, and projections |
| `/liveai/decisions` | GET | Yes | Detailed per-turn decision logs |
| `/liveai/errors` | GET | Yes | Error tracking and recovery rates |
| `/liveai/games/recent` | GET | Yes | Recent Live AI games with outcomes |
| `/events/liveai/decision` | POST | Yes | Record a GPT decision |
| `/events/liveai/error` | POST | Yes | Record an API error |

---

## 1. Live AI Stats

Get aggregate statistics for Live AI mode games.

```
GET /liveai/stats?period=today|week|month|all
```

**Headers:**
```
X-API-Key: luddo_metrics_2024_secure_key
```

**Response:**
```json
{
  "timestamp": "2025-12-03T19:45:00.000Z",
  "period": "week",
  "games": {
    "total": 45,
    "completed": 38,
    "abandoned": 7,
    "completionRate": 84,
    "avgDurationMinutes": 12,
    "allAIGames": 5,
    "mixedGames": 40
  },
  "apiUsage": {
    "totalCalls": 1250,
    "totalTokens": 562000,
    "avgTokensPerGame": 12489,
    "avgTokensPerTurn": 450,
    "estimatedCostUSD": 0.85,
    "avgResponseTimeMs": 1200
  },
  "decisions": {
    "total": 1250,
    "parseSuccess": {
      "json": 1050,
      "pattern": 120,
      "digit": 50,
      "fallback": 30
    },
    "avgConfidence": 0.89,
    "errorRate": 2.4
  },
  "outcomes": {
    "humanWins": 22,
    "aiWins": 16,
    "humanWinRate": 58
  }
}
```

---

## 2. Live AI Costs

Monitor API spending and project future costs.

```
GET /liveai/costs?period=today|week|month
```

**Headers:**
```
X-API-Key: luddo_metrics_2024_secure_key
```

**Response:**
```json
{
  "timestamp": "2025-12-03T19:45:00.000Z",
  "period": "month",
  "model": "gpt-4o-mini",
  "pricing": {
    "inputPer1kTokens": 0.00015,
    "outputPer1kTokens": 0.0006
  },
  "usage": {
    "totalInputTokens": 480000,
    "totalOutputTokens": 15000,
    "totalCalls": 1250
  },
  "costs": {
    "inputCostUSD": 0.072,
    "outputCostUSD": 0.009,
    "totalCostUSD": 0.081,
    "avgCostPerGame": 0.018,
    "avgCostPerTurn": 0.00065
  },
  "projections": {
    "dailyAvgGames": 6,
    "projectedMonthlyCost": 3.24,
    "projectedYearlyCost": 38.88
  },
  "perGameBreakdown": [
    {
      "gameId": "game_xyz789",
      "date": "2025-12-03",
      "totalTokens": 18500,
      "costUSD": 0.028,
      "turns": 42
    }
  ]
}
```

---

## 3. Live AI Decisions

Get detailed per-turn decision logs for debugging and analysis.

```
GET /liveai/decisions?limit=50&gameId=optional
```

**Parameters:**
- `limit` (optional): 1-200, default 50
- `gameId` (optional): Filter by specific game

**Headers:**
```
X-API-Key: luddo_metrics_2024_secure_key
```

**Response:**
```json
{
  "timestamp": "2025-12-03T19:45:00.000Z",
  "count": 50,
  "decisions": [
    {
      "id": "dec_abc123",
      "gameId": "game_xyz789",
      "turnNumber": 15,
      "playerColor": "red",
      "playerName": "GPT-Nova",
      "diceValue": 4,
      "validMoves": [0, 2],
      "selectedToken": 0,
      "parseStrategy": "json",
      "confidence": 0.95,
      "tokensUsed": {
        "prompt": 380,
        "completion": 12,
        "total": 392
      },
      "responseTimeMs": 1150,
      "moveOutcome": "capture",
      "retryAttempts": 0,
      "timestamp": "2025-12-03T19:44:55.000Z"
    }
  ]
}
```

**Parse Strategy Values:**
- `json` - Clean JSON response (highest confidence)
- `pattern` - Pattern matching (e.g., "token 0")
- `digit` - Single digit extraction
- `fallback` - First valid move (lowest confidence)

**Move Outcome Values:**
- `capture` - Captured opponent token
- `home` - Token reached home
- `safe` - Moved to safe spot
- `normal` - Regular move

---

## 4. Live AI Errors

Track and analyze API errors for reliability monitoring.

```
GET /liveai/errors?period=week&limit=100
```

**Headers:**
```
X-API-Key: luddo_metrics_2024_secure_key
```

**Response:**
```json
{
  "timestamp": "2025-12-03T19:45:00.000Z",
  "period": "week",
  "summary": {
    "totalErrors": 35,
    "errorRate": 2.8,
    "byType": {
      "rate_limit": 2,
      "timeout": 18,
      "invalid_response": 10,
      "network_error": 5,
      "api_error": 0
    },
    "recoveryRate": 94
  },
  "recentErrors": [
    {
      "gameId": "game_xyz789",
      "turnNumber": 8,
      "errorCode": "timeout",
      "errorMessage": "Request timed out after 10000ms",
      "retryAttempts": 2,
      "recovered": true,
      "timestamp": "2025-12-03T19:40:00.000Z"
    }
  ]
}
```

---

## 5. Recent Live AI Games

List recent Live AI mode games with outcomes.

```
GET /liveai/games/recent?limit=20
```

**Headers:**
```
X-API-Key: luddo_metrics_2024_secure_key
```

**Response:**
```json
{
  "timestamp": "2025-12-03T19:45:00.000Z",
  "count": 20,
  "games": [
    {
      "id": "game_xyz789",
      "startedAt": "2025-12-03T19:30:00.000Z",
      "endedAt": "2025-12-03T19:42:00.000Z",
      "durationMinutes": 12,
      "status": "completed",
      "playerCount": 4,
      "players": [
        { "color": "red", "name": "Asif", "type": "human" },
        { "color": "blue", "name": "GPT-Nova", "type": "openai" },
        { "color": "yellow", "name": "GPT-Sage", "type": "openai" },
        { "color": "green", "name": "Player 4", "type": "human" }
      ],
      "winner": {
        "color": "red",
        "name": "Asif",
        "type": "human"
      },
      "totalTurns": 85,
      "aiTurns": 42,
      "totalTokensUsed": 18500,
      "totalAPICalls": 42,
      "totalErrors": 0,
      "estimatedCostUSD": 0.028
    }
  ]
}
```

---

## 6. Record Live AI Decision (POST)

Record each GPT decision for analytics.

```
POST /events/liveai/decision
```

**Headers:**
```
X-API-Key: luddo_metrics_2024_secure_key
Content-Type: application/json
```

**Request Body:**
```json
{
  "gameId": "game_xyz789",
  "turnNumber": 15,
  "playerColor": "red",
  "playerName": "GPT-Nova",
  "diceValue": 4,
  "validMoves": [0, 2],
  "selectedToken": 0,
  "parseStrategy": "json",
  "confidence": 0.95,
  "tokensUsed": {
    "prompt": 380,
    "completion": 12,
    "total": 392
  },
  "responseTimeMs": 1150,
  "moveOutcome": "capture",
  "retryAttempts": 0
}
```

**Response:**
```json
{
  "success": true,
  "id": "dec_abc123",
  "timestamp": "2025-12-03T19:44:55.000Z"
}
```

---

## 7. Record Live AI Error (POST)

Record API errors for reliability tracking.

```
POST /events/liveai/error
```

**Headers:**
```
X-API-Key: luddo_metrics_2024_secure_key
Content-Type: application/json
```

**Request Body:**
```json
{
  "gameId": "game_xyz789",
  "turnNumber": 8,
  "errorCode": "timeout",
  "errorMessage": "Request timed out after 10000ms",
  "retryAttempt": 1,
  "recovered": true
}
```

**Response:**
```json
{
  "success": true,
  "id": "err_def456",
  "timestamp": "2025-12-03T19:40:00.000Z"
}
```

---

## Swift Models for Live AI

```swift
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

struct LiveAIDecision: Codable {
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

struct LiveAIError: Codable {
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

struct LiveAIGame: Codable {
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
```

---

## Swift API Client Extension

```swift
extension LuddoMetricsAPI {

    // MARK: - Live AI Endpoints

    func liveAIStats(period: String = "all") async throws -> LiveAIStats {
        try await request(endpoint: "/liveai/stats?period=\(period)")
    }

    func liveAICosts(period: String = "month") async throws -> LiveAICosts {
        try await request(endpoint: "/liveai/costs?period=\(period)")
    }

    func liveAIDecisions(limit: Int = 50, gameId: String? = nil) async throws -> LiveAIDecisionsResponse {
        var endpoint = "/liveai/decisions?limit=\(limit)"
        if let gameId = gameId { endpoint += "&gameId=\(gameId)" }
        return try await request(endpoint: endpoint)
    }

    func liveAIErrors(period: String = "week", limit: Int = 100) async throws -> LiveAIErrorsResponse {
        try await request(endpoint: "/liveai/errors?period=\(period)&limit=\(limit)")
    }

    func liveAIGamesRecent(limit: Int = 20) async throws -> LiveAIGamesResponse {
        try await request(endpoint: "/liveai/games/recent?limit=\(limit)")
    }

    // MARK: - Live AI Event Recording

    func recordLiveAIDecision(_ decision: LiveAIDecisionEvent) async throws -> RecordResponse {
        try await postRequest(endpoint: "/events/liveai/decision", body: decision)
    }

    func recordLiveAIError(_ error: LiveAIErrorEvent) async throws -> RecordResponse {
        try await postRequest(endpoint: "/events/liveai/error", body: error)
    }
}

// MARK: - Event Models

struct LiveAIDecisionEvent: Codable {
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

    struct TokensUsed: Codable {
        let prompt: Int
        let completion: Int
        let total: Int
    }
}

struct LiveAIErrorEvent: Codable {
    let gameId: String
    let turnNumber: Int
    let errorCode: String
    let errorMessage: String
    let retryAttempt: Int
    let recovered: Bool
}

struct RecordResponse: Codable {
    let success: Bool
    let id: String
    let timestamp: String
}
```

---

## Live AI Notes

- **Model used**: `gpt-4o-mini` (cost-effective, fast)
- **Pricing** (as of Dec 2025):
  - Input: $0.00015 per 1K tokens
  - Output: $0.0006 per 1K tokens
- **Avg cost per game**: ~$0.01-0.05
- **Avg tokens per turn**: ~400-500
- **Response timeout**: 10 seconds
- **Retry attempts**: 2 (with exponential backoff)
- **GPT Character Names**: GPT-Alpha, GPT-Nova, GPT-Sage, GPT-Oracle, GPT-Titan, GPT-Phoenix
- **Parse strategies** (in order of confidence):
  1. JSON parsing (95% confidence)
  2. Pattern matching (80% confidence)
  3. Digit extraction (60% confidence)
  4. Fallback to first valid move (10% confidence)
