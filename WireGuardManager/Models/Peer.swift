//
//  Peer.swift
//  WireGuardManager
//
//  WireGuard peer (device) model
//

import Foundation

/// WireGuard peer (VPN client device)
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
    let lastHandshake: Date?
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
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
    
    /// Display title for the peer
    var displayName: String {
        name
    }
    
    /// Status emoji for UI
    var statusEmoji: String {
        if !isEnabled {
            return "⏸️" // Paused
        } else if isOnline {
            return "🟢" // Online
        } else {
            return "🔴" // Offline
        }
    }
    
    /// Check if peer is currently online (handshake within 3 minutes)
    var isOnline: Bool {
        guard let handshake = lastHandshake else { return false }
        let threeMinutesAgo = Date().addingTimeInterval(-180)
        return handshake > threeMinutesAgo
    }
    
    /// Formatted received data
    var formattedRx: String {
        totalRx.formatBytes()
    }
    
    /// Formatted transmitted data
    var formattedTx: String {
        totalTx.formatBytes()
    }
    
    /// Total data transferred (rx + tx)
    var totalData: Int {
        totalRx + totalTx
    }
    
    /// Formatted total data
    var formattedTotalData: String {
        totalData.formatBytes()
    }
    
    /// Time since last handshake
    var lastSeenText: String {
        guard let handshake = lastHandshake else {
            return "Never connected"
        }
        return handshake.timeAgoDisplay()
    }
    
    /// Connection status text
    var statusText: String {
        if !isEnabled {
            return "Disabled"
        } else if isOnline {
            return "Connected"
        } else {
            return "Disconnected"
        }
    }
    
    /// Short IP address (without CIDR)
    var shortIpAddress: String {
        ipAddress.components(separatedBy: "/").first ?? ipAddress
    }
}

// MARK: - Mock Data for Previews

#if DEBUG
extension Peer {
    /// Mock peer for SwiftUI previews
    static let mock = Peer(
        id: 1,
        name: "iPhone 15 Pro",
        description: "Personal iPhone",
        deviceName: "iPhone 15 Pro",
        deviceIdentifier: "ios-device-123",
        publicKey: "AbCdEf123456789==",
        ipAddress: "10.8.0.2/32",
        allowedIps: "0.0.0.0/0, ::/0",
        persistentKeepalive: 25,
        isActive: true,
        isEnabled: true,
        totalRx: 1024 * 1024 * 150, // 150 MB
        totalTx: 1024 * 1024 * 50,  // 50 MB
        lastHandshake: Date().addingTimeInterval(-60), // 1 minute ago
        createdAt: Date().addingTimeInterval(-86400 * 7), // 7 days ago
        updatedAt: Date()
    )
    
    /// Array of mock peers for previews
    static let mocks: [Peer] = [
        mock,
        Peer(
            id: 2,
            name: "MacBook Pro",
            description: "Work laptop",
            deviceName: "MacBook Pro 16",
            deviceIdentifier: "macos-device-456",
            publicKey: "XyZ987654321==",
            ipAddress: "10.8.0.3/32",
            allowedIps: "0.0.0.0/0, ::/0",
            persistentKeepalive: 25,
            isActive: true,
            isEnabled: true,
            totalRx: 1024 * 1024 * 1024 * 2, // 2 GB
            totalTx: 1024 * 1024 * 500,      // 500 MB
            lastHandshake: Date().addingTimeInterval(-300), // 5 minutes ago
            createdAt: Date().addingTimeInterval(-86400 * 30),
            updatedAt: Date()
        ),
        Peer(
            id: 3,
            name: "iPad Air",
            description: nil,
            deviceName: nil,
            deviceIdentifier: nil,
            publicKey: "QwErTy456789==",
            ipAddress: "10.8.0.4/32",
            allowedIps: "0.0.0.0/0, ::/0",
            persistentKeepalive: 25,
            isActive: true,
            isEnabled: false,
            totalRx: 0,
            totalTx: 0,
            lastHandshake: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    ]
}
#endif
