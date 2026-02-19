//
//  APIService.swift
//  WireGuardManager
//
//  Created by Claude on 2026-02-01.
//

import Foundation

// MARK: - API Error
enum APIError: LocalizedError {
    case invalidURL
    case noData
    case decodingError
    case unauthorized
    case serverError(String)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .decodingError:
            return "Failed to decode response"
        case .unauthorized:
            return "Unauthorized. Please login again."
        case .serverError(let message):
            return "Server error: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

// MARK: - API Service
@MainActor
class APIService: ObservableObject {
    
    // MARK: - Properties
    static let shared = APIService()
    
    // TODO: Замени на адрес твоего сервера
    private let baseURL = "http://localhost:8000"
    
    @Published var authToken: String? {
        didSet {
            if let token = authToken {
                KeychainService.shared.save(token: token)
            } else {
                KeychainService.shared.deleteToken()
            }
        }
    }
    
    private init() {
        // Загружаем токен из Keychain при инициализации
        self.authToken = KeychainService.shared.getToken()
    }
    
    // MARK: - Authentication
    
    /// Login пользователя
    func login(username: String, password: String) async throws -> String {
        let url = URL(string: "\(baseURL)/api/auth/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "username", value: username),
            URLQueryItem(name: "password", value: password)
        ]
        request.httpBody = components.query?.data(using: .utf8)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.noData
            }
            
            if httpResponse.statusCode == 401 {
                throw APIError.unauthorized
            }
            
            guard httpResponse.statusCode == 200 else {
                if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    throw APIError.serverError(errorResponse.detail)
                }
                throw APIError.serverError("HTTP \(httpResponse.statusCode)")
            }
            
            let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
            self.authToken = tokenResponse.accessToken
            return tokenResponse.accessToken
            
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }
    
    /// Получить информацию о текущем пользователе
    func getCurrentUser() async throws -> User {
        guard let token = authToken else {
            throw APIError.unauthorized
        }
        
        let url = URL(string: "\(baseURL)/api/auth/me")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }

        return try JSONDecoder().decode(User.self, from: data)
    }
    
    /// Logout
    func logout() {
        authToken = nil
    }
    
    // MARK: - Peers Management
    
    /// Получить список всех peers
    func getPeers() async throws -> [Peer] {
        guard let token = authToken else {
            throw APIError.unauthorized
        }
        
        let url = URL(string: "\(baseURL)/api/peers/")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.noData
        }
        
        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }
        
        return try JSONDecoder().decode([Peer].self, from: data)
    }
    
    /// Создать новый peer
    func createPeer(name: String, description: String?) async throws -> Peer {
        guard let token = authToken else {
            throw APIError.unauthorized
        }
        
        let url = URL(string: "\(baseURL)/api/peers/")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = CreatePeerRequest(name: name, description: description)
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.noData
        }
        
        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }
        
        guard httpResponse.statusCode == 201 else {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw APIError.serverError(errorResponse.detail)
            }
            throw APIError.serverError("HTTP \(httpResponse.statusCode)")
        }
        
        return try JSONDecoder().decode(Peer.self, from: data)
    }
    
    /// Получить конфигурацию peer
    func getPeerConfig(peerId: Int) async throws -> PeerConfigResponse {
        guard let token = authToken else {
            throw APIError.unauthorized
        }
        
        let url = URL(string: "\(baseURL)/api/peers/\(peerId)/config")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(PeerConfigResponse.self, from: data)
    }
    
    /// Toggle peer (включить/выключить)
    func togglePeer(peerId: Int) async throws -> Peer {
        guard let token = authToken else {
            throw APIError.unauthorized
        }
        
        let url = URL(string: "\(baseURL)/api/peers/\(peerId)/toggle")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(Peer.self, from: data)
    }
    
    /// Удалить peer
    func deletePeer(peerId: Int) async throws {
        guard let token = authToken else {
            throw APIError.unauthorized
        }
        
        let url = URL(string: "\(baseURL)/api/peers/\(peerId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.noData
        }
        
        guard httpResponse.statusCode == 204 else {
            throw APIError.serverError("Failed to delete peer")
        }
    }
    
    /// Получить статистику сервера
    func getServerStatistics() async throws -> ServerStatistics {
        guard let token = authToken else {
            throw APIError.unauthorized
        }
        
        let url = URL(string: "\(baseURL)/api/peers/stats/server")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(ServerStatistics.self, from: data)
    }
}

// MARK: - Error Response
struct ErrorResponse: Codable {
    let detail: String
}
