//
//  User.swift
//  WireGuardManager
//
//  User model and related structures
//

import Foundation

/// User account model
struct User: Codable, Identifiable {
    let id: Int
    let username: String
    let email: String
    let isActive: Bool
    let isSuperuser: Bool
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case email
        case isActive = "is_active"
        case isSuperuser = "is_superuser"
        case createdAt = "created_at"
    }
    
    /// Display name for UI
    var displayName: String {
        username
    }
    
    /// Check if user has admin privileges
    var isAdmin: Bool {
        isSuperuser
    }
}

/// User registration request
struct UserRegistration: Codable {
    let username: String
    let email: String
    let password: String
}
