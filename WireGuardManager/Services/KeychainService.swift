//
//  KeychainService.swift
//  WireGuardManager
//
//  Secure storage for sensitive data using iOS Keychain
//

import Foundation
import Security

/// Service for securely storing and retrieving data from iOS Keychain
class KeychainService {
    
    static let shared = KeychainService()
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Save a string value to keychain
    /// - Parameters:
    ///   - value: String value to save
    ///   - key: Key identifier
    /// - Returns: Success status
    @discardableResult
    func save(_ value: String, forKey key: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        
        // Delete any existing value first
        delete(forKey: key)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Constants.Keychain.serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    /// Retrieve a string value from keychain
    /// - Parameter key: Key identifier
    /// - Returns: Stored string value or nil if not found
    func get(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Constants.Keychain.serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return value
    }
    
    /// Delete a value from keychain
    /// - Parameter key: Key identifier
    /// - Returns: Success status
    @discardableResult
    func delete(forKey key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Constants.Keychain.serviceName,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    /// Clear all keychain items for this app
    @discardableResult
    func clearAll() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Constants.Keychain.serviceName
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    // MARK: - Convenience Methods
    
    /// Save access token
    func saveAccessToken(_ token: String) -> Bool {
        save(token, forKey: Constants.Keychain.accessTokenKey)
    }
    
    /// Get access token
    func getAccessToken() -> String? {
        get(forKey: Constants.Keychain.accessTokenKey)
    }
    
    /// Delete access token
    func deleteAccessToken() -> Bool {
        delete(forKey: Constants.Keychain.accessTokenKey)
    }
    
    /// Save username
    func saveUsername(_ username: String) -> Bool {
        save(username, forKey: Constants.Keychain.usernameKey)
    }
    
    /// Get username
    func getUsername() -> String? {
        get(forKey: Constants.Keychain.usernameKey)
    }
    
    /// Check if user is logged in (has access token)
    var isLoggedIn: Bool {
        getAccessToken() != nil
    }
    
    /// Logout (clear all credentials)
    func logout() {
        deleteAccessToken()
        delete(forKey: Constants.Keychain.usernameKey)
    }
}
