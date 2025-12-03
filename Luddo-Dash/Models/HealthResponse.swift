//
//  HealthResponse.swift
//  Luddo-Dash
//
//  API Models for /health and /status endpoints
//

import Foundation

// MARK: - Health Response (/health)
struct HealthResponse: Codable {
    let status: String
    let timestamp: String
    let uptime: Double
}

// MARK: - Status Response (/status)
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
