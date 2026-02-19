//
//  WireGuardManagerApp.swift
//  WireGuardManager
//
//  Created by Claude on 2026-02-01.
//

import SwiftUI

@main
struct WireGuardManagerApp: App {
    
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
        }
    }
}

// MARK: - Content View
struct ContentView: View {
    
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                PeerListView()
            } else {
                LoginView()
            }
        }
        .environmentObject(authViewModel)
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
}
