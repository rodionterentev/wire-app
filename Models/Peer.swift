//
//  Peer.swift
//  WireGuardManager
//
//  Created by Claude on 2026-02-01.
//

import Foundation

// MARK: - Peer Model
struct Peer: Codable, Identifiable {
    let id: Int
    let name: String
    let description: String?
    let deviceName: String?
    let deviceIdentifier: String?
    let publicKey: String
    let ipAddress: String
    let allowedIps: String
    let persistentKeepalive: Int
    let isActive: Bool
    let isEnabled: Bool
    let totalRx: Int
    let totalTx: Int
    let lastHandshake: String?
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, name, description
        case deviceName = "device_name"
        case deviceIdentifier = "device_identifier"
        case publicKey = "public_key"
        case ipAddress = "ip_address"
        case allowedIps = "allowed_ips"
        case persistentKeepalive = "persistent_keepalive"
        case isActive = "is_active"
        case isEnabled = "is_enabled"
        case totalRx = "total_rx"
        case totalTx = "total_tx"
        case lastHandshake = "last_handshake"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // MARK: - Computed Properties
    var formattedRx: String {
        ByteCountFormatter.string(fromByteCount: Int64(totalRx), countStyle: .binary)
    }
    
    var formattedTx: String {
        ByteCountFormatter.string(fromByteCount: Int64(totalTx), countStyle: .binary)
    }
    
    var statusColor: String {
        isEnabled ? "green" : "gray"
    }
}

// MARK: - Create Peer Request
struct CreatePeerRequest: Codable {
    let name: String
    let description: String?
    
    init(name: String, description: String? = nil) {
        self.name = name
        self.description = description
    }
}

// MARK: - Peer Config Response
struct PeerConfigResponse: Codable {
    let configText: String
    let qrCodeBase64: String?
    
    enum CodingKeys: String, CodingKey {
        case configText = "config_text"
        case qrCodeBase64 = "qr_code_base64"
    }
}

// MARK: - Server Statistics
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
        case interface
    }
}
