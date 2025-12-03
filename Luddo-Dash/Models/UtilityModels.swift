//
//  UtilityModels.swift
//  Luddo-Dash
//
//  API Models for /utils endpoints
//

import Foundation

// MARK: - Version Response (/utils/version)
struct VersionResponse: Codable {
    let name: String
    let version: String
    let timestamp: String
    let capabilities: [String]
    let endpoints: [String: [String]]
}

// MARK: - Time Response (/utils/time)
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

// MARK: - Ping Response (/utils/ping)
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

// MARK: - Location Response (/utils/location)
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
