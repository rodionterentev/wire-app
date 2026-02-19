//
//  Constants.swift
//  WireGuardManager
//
//  App-wide constants and configuration
//

import Foundation

enum Constants {
    
    // MARK: - API Configuration
    
    /// Base URL for the WireGuard management API
    /// Change this to your server's IP address or domain
    /// Examples:
    /// - Local: "http://192.168.1.100:8000"
    /// - Production: "https://api.yourdomain.com"
    static let baseURL = "http://localhost:8000"
    
    /// API version prefix
    static let apiPrefix = "/api"
    
    // MARK: - API Endpoints
    
    enum Endpoints {
        // Authentication
        static let login = "\(apiPrefix)/auth/token"
        static let me = "\(apiPrefix)/auth/me"
        static let register = "\(apiPrefix)/auth/register"
        
        // Peers
        static let peers = "\(apiPrefix)/peers"
        static func peer(_ id: Int) -> String { "\(apiPrefix)/peers/\(id)" }
        static func peerConfig(_ id: Int) -> String { "\(apiPrefix)/peers/\(id)/config" }
        static func peerToggle(_ id: Int) -> String { "\(apiPrefix)/peers/\(id)/toggle" }
        static func peerStats(_ id: Int) -> String { "\(apiPrefix)/peers/\(id)/stats" }
        
        // Server
        static let serverStats = "\(apiPrefix)/peers/stats/server"
        static let health = "/health"
    }
    
    // MARK: - Keychain Configuration
    
    enum Keychain {
        /// Service name for keychain items
        static let serviceName = "com.wireguard.manager"
        
        /// Keys for storing data
        static let accessTokenKey = "access_token"
        static let usernameKey = "username"
    }
    
    // MARK: - VPN Configuration
    
    enum VPN {
        /// VPN tunnel display name
        static let tunnelName = "WireGuard Manager"
        
        /// Default DNS servers
        static let defaultDNS = ["1.1.1.1", "1.0.0.1"]
        
        /// Persistent keepalive interval (seconds)
        static let keepaliveInterval = 25
        
        /// Connection timeout (seconds)
        static let connectionTimeout: TimeInterval = 30
    }
    
    // MARK: - UI Configuration
    
    enum UI {
        /// Animation duration for transitions
        static let animationDuration: Double = 0.3
        
        /// Debounce time for search (seconds)
        static let searchDebounce: Double = 0.5
        
        /// Pull to refresh cooldown (seconds)
        static let refreshCooldown: TimeInterval = 2.0
    }
    
    // MARK: - Network Configuration
    
    enum Network {
        /// Request timeout interval
        static let requestTimeout: TimeInterval = 30
        
        /// Maximum retry attempts for failed requests
        static let maxRetries = 3
        
        /// Retry delay (seconds)
        static let retryDelay: TimeInterval = 1.0
    }
    
    // MARK: - Validation
    
    enum Validation {
        /// Minimum username length
        static let minUsernameLength = 3
        
        /// Maximum username length
        static let maxUsernameLength = 50
        
        /// Minimum password length
        static let minPasswordLength = 8
        
        /// Minimum peer name length
        static let minPeerNameLength = 1
        
        /// Maximum peer name length
        static let maxPeerNameLength = 100
    }
}
