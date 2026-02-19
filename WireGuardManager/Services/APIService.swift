//
//  APIService.swift
//  WireGuardManager
//
//  HTTP client for communicating with the WireGuard management API
//

import Foundation

/// Service for making API requests to the backend
class APIService {
    
    static let shared = APIService()
    
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    
    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = Constants.Network.requestTimeout
        self.session = URLSession(configuration: configuration)
        
        // Configure JSON decoder to handle ISO8601 dates
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
        
        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
    }
    
    // MARK: - Authentication
    
    /// Login with username and password
    /// - Parameters:
    ///   - username: User's username
    ///   - password: User's password
    /// - Returns: Access token
    func login(username: String, password: String) async throws -> String {
        let url = try makeURL(endpoint: Constants.Endpoints.login)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let body = "username=\(username)&password=\(password)"
        request.httpBody = body.data(using: .utf8)
        
        let response: TokenResponse = try await perform(request)
        
        // Save token to keychain
        KeychainService.shared.saveAccessToken(response.accessToken)
        KeychainService.shared.saveUsername(username)
        
        return response.accessToken
    }
    
    /// Get current user information
    /// - Returns: Current user
    func getCurrentUser() async throws -> User {
        let url = try makeURL(endpoint: Constants.Endpoints.me)
        let request = try makeAuthenticatedRequest(url: url, method: "GET")
        return try await perform(request)
    }
    
    /// Logout (clear local credentials)
    func logout() {
        KeychainService.shared.logout()
    }
    
    // MARK: - Peers
    
    /// Get list of all peers
    /// - Returns: Array of peers
    func getPeers() async throws -> [Peer] {
        let url = try makeURL(endpoint: Constants.Endpoints.peers)
        let request = try makeAuthenticatedRequest(url: url, method: "GET")
        return try await perform(request)
    }
    
    /// Get a specific peer by ID
    /// - Parameter id: Peer ID
    /// - Returns: Peer details
    func getPeer(id: Int) async throws -> Peer {
        let url = try makeURL(endpoint: Constants.Endpoints.peer(id))
        let request = try makeAuthenticatedRequest(url: url, method: "GET")
        return try await perform(request)
    }
    
    /// Create a new peer
    /// - Parameters:
    ///   - name: Peer name
    ///   - description: Optional description
    ///   - deviceName: Optional device name
    ///   - deviceIdentifier: Optional device identifier
    /// - Returns: Created peer
    func createPeer(
        name: String,
        description: String? = nil,
        deviceName: String? = nil,
        deviceIdentifier: String? = nil
    ) async throws -> Peer {
        let url = try makeURL(endpoint: Constants.Endpoints.peers)
        
        let body = CreatePeerRequest(
            name: name,
            description: description,
            deviceName: deviceName,
            deviceIdentifier: deviceIdentifier
        )
        
        var request = try makeAuthenticatedRequest(url: url, method: "POST")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(body)
        
        return try await perform(request)
    }
    
    /// Update an existing peer
    /// - Parameters:
    ///   - id: Peer ID
    ///   - name: New name (optional)
    ///   - description: New description (optional)
    ///   - isEnabled: Enable/disable status (optional)
    ///   - deviceName: New device name (optional)
    /// - Returns: Updated peer
    func updatePeer(
        id: Int,
        name: String? = nil,
        description: String? = nil,
        isEnabled: Bool? = nil,
        deviceName: String? = nil
    ) async throws -> Peer {
        let url = try makeURL(endpoint: Constants.Endpoints.peer(id))
        
        let body = UpdatePeerRequest(
            name: name,
            description: description,
            isEnabled: isEnabled,
            deviceName: deviceName
        )
        
        var request = try makeAuthenticatedRequest(url: url, method: "PATCH")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(body)
        
        return try await perform(request)
    }
    
    /// Delete a peer
    /// - Parameter id: Peer ID
    func deletePeer(id: Int) async throws {
        let url = try makeURL(endpoint: Constants.Endpoints.peer(id))
        let request = try makeAuthenticatedRequest(url: url, method: "DELETE")
        let _: EmptyResponse = try await perform(request)
    }
    
    /// Toggle peer enabled/disabled status
    /// - Parameter id: Peer ID
    /// - Returns: Toggle response with new status
    func togglePeer(id: Int) async throws -> PeerToggleResponse {
        let url = try makeURL(endpoint: Constants.Endpoints.peerToggle(id))
        let request = try makeAuthenticatedRequest(url: url, method: "POST")
        return try await perform(request)
    }
    
    /// Get peer configuration (WireGuard config + QR code)
    /// - Parameter id: Peer ID
    /// - Returns: Configuration with text and QR code
    func getPeerConfig(id: Int) async throws -> PeerConfigResponse {
        let url = try makeURL(endpoint: Constants.Endpoints.peerConfig(id))
        let request = try makeAuthenticatedRequest(url: url, method: "GET")
        return try await perform(request)
    }
    
    // MARK: - Statistics
    
    /// Get statistics for a specific peer
    /// - Parameter id: Peer ID
    /// - Returns: Peer statistics
    func getPeerStats(id: Int) async throws -> PeerStatistics {
        let url = try makeURL(endpoint: Constants.Endpoints.peerStats(id))
        let request = try makeAuthenticatedRequest(url: url, method: "GET")
        return try await perform(request)
    }
    
    /// Get server-wide statistics
    /// - Returns: Server statistics
    func getServerStats() async throws -> ServerStatistics {
        let url = try makeURL(endpoint: Constants.Endpoints.serverStats)
        let request = try makeAuthenticatedRequest(url: url, method: "GET")
        return try await perform(request)
    }
    
    // MARK: - Health Check
    
    /// Check if API is reachable and healthy
    /// - Returns: True if healthy
    func healthCheck() async throws -> Bool {
        let url = try makeURL(endpoint: Constants.Endpoints.health)
        let request = URLRequest(url: url)
        
        do {
            let (_, response) = try await session.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                return httpResponse.statusCode == 200
            }
            return false
        } catch {
            return false
        }
    }
    
    // MARK: - Private Helpers
    
    /// Create URL from endpoint
    private func makeURL(endpoint: String) throws -> URL {
        guard let url = URL(string: Constants.baseURL + endpoint) else {
            throw APIError.invalidURL
        }
        return url
    }
    
    /// Create authenticated request with JWT token
    private func makeAuthenticatedRequest(url: URL, method: String) throws -> URLRequest {
        guard let token = KeychainService.shared.getAccessToken() else {
            throw APIError.unauthorized
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        return request
    }
    
    /// Perform HTTP request and decode response
    private func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            // Handle different status codes
            switch httpResponse.statusCode {
            case 200...299:
                // Success - decode response
                do {
                    return try decoder.decode(T.self, from: data)
                } catch {
                    throw APIError.decodingError(error)
                }
                
            case 401:
                // Unauthorized - clear token and throw
                KeychainService.shared.logout()
                throw APIError.unauthorized
                
            case 400...499:
                // Client error - try to decode error message
                if let errorResponse = try? decoder.decode(APIErrorResponse.self, from: data) {
                    throw APIError.serverError(errorResponse.detail)
                }
                throw APIError.serverError("Client error: \(httpResponse.statusCode)")
                
            case 500...599:
                // Server error
                if let errorResponse = try? decoder.decode(APIErrorResponse.self, from: data) {
                    throw APIError.serverError(errorResponse.detail)
                }
                throw APIError.serverError("Server error: \(httpResponse.statusCode)")
                
            default:
                throw APIError.invalidResponse
            }
            
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }
}

// MARK: - Empty Response

/// Empty response for DELETE requests
private struct EmptyResponse: Codable {}
