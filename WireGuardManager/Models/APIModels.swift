//
//  APIModels.swift
//  WireGuardManager
//
//  Models for API requests and responses
//

import Foundation

// MARK: - Authentication Models

/// Login request body
struct LoginRequest: Codable {
    let username: String
    let password: String
    
    /// Convert to form URL encoded string
    var formEncoded: String {
        "username=\(username)&password=\(password)"
    }
}

/// Token response from login
struct TokenResponse: Codable {
    let accessToken: String
    let tokenType: String
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
    }
}

// MARK: - Peer Models

/// Request to create a new peer
struct CreatePeerRequest: Codable {
    let name: String
    let description: String?
    let deviceName: String?
    let deviceIdentifier: String?
    
    enum CodingKeys: String, CodingKey {
        case name
        case description
        case deviceName = "device_name"
        case deviceIdentifier = "device_identifier"
    }
}

/// Request to update a peer
struct UpdatePeerRequest: Codable {
    let name: String?
    let description: String?
    let isEnabled: Bool?
    let deviceName: String?
    
    enum CodingKeys: String, CodingKey {
        case name
        case description
        case isEnabled = "is_enabled"
        case deviceName = "device_name"
    }
}

/// Peer configuration with WireGuard config and QR code
struct PeerConfigResponse: Codable {
    let configText: String
    let qrCodeBase64: String?
    
    enum CodingKeys: String, CodingKey {
        case configText = "config_text"
        case qrCodeBase64 = "qr_code_base64"
    }
}

/// Peer toggle response
struct PeerToggleResponse: Codable {
    let peerId: Int
    let name: String
    let isEnabled: Bool
    let message: String
    
    enum CodingKeys: String, CodingKey {
        case peerId = "peer_id"
        case name
        case isEnabled = "is_enabled"
        case message
    }
}

// MARK: - Statistics Models

/// Individual peer statistics
struct PeerStatistics: Codable, Identifiable {
    let peerId: Int
    let name: String
    let publicKey: String
    let ipAddress: String
    let isEnabled: Bool
    let totalRx: Int
    let totalTx: Int
    let totalRxFormatted: String
    let totalTxFormatted: String
    let lastHandshake: Date?
    let lastHandshakeAgo: String?
    let isOnline: Bool
    
    var id: Int { peerId }
    
    enum CodingKeys: String, CodingKey {
        case peerId = "peer_id"
        case name
        case publicKey = "public_key"
        case ipAddress = "ip_address"
        case isEnabled = "is_enabled"
        case totalRx = "total_rx"
        case totalTx = "total_tx"
        case totalRxFormatted = "total_rx_formatted"
        case totalTxFormatted = "total_tx_formatted"
        case lastHandshake = "last_handshake"
        case lastHandshakeAgo = "last_handshake_ago"
        case isOnline = "is_online"
    }
}

/// Server-wide statistics
struct ServerStatistics: Codable {
    let totalPeers: Int
    let activePeers: Int
    let enabledPeers: Int
    let disabledPeers: Int
    let onlinePeers: Int
    let totalRx: Int
    let totalTx: Int
    let totalRxFormatted: String
    let totalTxFormatted: String
    let serverUptime: String?
    let interface: String
    
    enum CodingKeys: String, CodingKey {
        case totalPeers = "total_peers"
        case activePeers = "active_peers"
        case enabledPeers = "enabled_peers"
        case disabledPeers = "disabled_peers"
        case onlinePeers = "online_peers"
        case totalRx = "total_rx"
        case totalTx = "total_tx"
        case totalRxFormatted = "total_rx_formatted"
        case totalTxFormatted = "total_tx_formatted"
        case serverUptime = "server_uptime"
        case interface
    }
}

// MARK: - Error Models

/// API error response
struct APIErrorResponse: Codable {
    let detail: String
}

/// Custom API error
enum APIError: LocalizedError {
    case unauthorized
    case networkError(Error)
    case decodingError(Error)
    case serverError(String)
    case invalidURL
    case noData
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Unauthorized. Please login again."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .serverError(let message):
            return message
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received from server"
        case .invalidResponse:
            return "Invalid response from server"
        }
    }
}

// MARK: - Health Check

/// Health check response
struct HealthResponse: Codable {
    let status: String
    let timestamp: Date
}
