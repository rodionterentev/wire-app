//
//  AuthViewModel.swift
//  WireGuardManager
//
//  Created by Claude on 2026-02-01.
//

import Foundation
import SwiftUI

@MainActor
class AuthViewModel: ObservableObject {
    
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiService = APIService.shared
    
    init() {
        // Проверяем есть ли сохраненный токен
        checkAuthentication()
    }
    
    // MARK: - Check Authentication
    func checkAuthentication() {
        isAuthenticated = apiService.authToken != nil
        
        if isAuthenticated {
            Task {
                await fetchCurrentUser()
            }
        }
    }
    
    // MARK: - Login
    func login(username: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            _ = try await apiService.login(username: username, password: password)
            await fetchCurrentUser()
            isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
            isAuthenticated = false
        }
        
        isLoading = false
    }
    
    // MARK: - Fetch Current User
    func fetchCurrentUser() async {
        do {
            currentUser = try await apiService.getCurrentUser()
        } catch {
            print("Failed to fetch user: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Logout
    func logout() {
        apiService.logout()
        currentUser = nil
        isAuthenticated = false
    }
}
