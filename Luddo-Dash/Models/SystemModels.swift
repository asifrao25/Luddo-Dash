//
//  SystemModels.swift
//  Luddo-Dash
//
//  API Models for /system endpoints
//

import Foundation

// MARK: - System Live Metrics (/system/live)
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

// MARK: - System History Response (/system/history)
struct SystemHistoryResponse: Codable {
    let timestamp: String
    let requestedSeconds: Int
    let dataPoints: Int
    let metrics: [MetricPoint]

    struct MetricPoint: Codable, Identifiable {
        var id: String { timestamp }

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
