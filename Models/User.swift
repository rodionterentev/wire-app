//
//  User.swift
//  WireGuardManager
//
//  Created by Claude on 2026-02-01.
//

import Foundation

// MARK: - User Model
struct User: Codable, Identifiable {
    let id: Int
    let username: String
    let email: String
    let isActive: Bool
    let isSuperuser: Bool
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, username, email
        case isActive = "is_active"
        case isSuperuser = "is_superuser"
        case createdAt = "created_at"
    }
}

// MARK: - Token Response
struct TokenResponse: Codable {
    let accessToken: String
    let tokenType: String
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
    }
}

// MARK: - Login Request
struct LoginRequest: Codable {
    let username: String
    let password: String
}
