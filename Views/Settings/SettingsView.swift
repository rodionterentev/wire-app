//
//  SettingsView.swift
//  WireGuardManager
//
//  Created by Claude on 2026-02-01.
//

import SwiftUI

struct SettingsView: View {
    
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                // User Section
                Section("Account") {
                    if let user = authViewModel.currentUser {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.title)
                                .foregroundColor(.blue)
                            
                            VStack(alignment: .leading) {
                                Text(user.username)
                                    .font(.headline)
                                
                                Text(user.email)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    
                    Button(role: .destructive, action: {
                        authViewModel.logout()
                        dismiss()
                    }) {
                        Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
                
                // App Info Section
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Text("Build")
                        Spacer()
                        Text("1")
                            .foregroundColor(.gray)
                    }
                }
                
                // Support Section
                Section("Support") {
                    Link(destination: URL(string: "https://github.com/YOUR_USERNAME/wireguard-ios-client")!) {
                        Label("GitHub Repository", systemImage: "link")
                    }
                    
                    Button(action: {
                        // TODO: Add support action
                    }) {
                        Label("Report Issue", systemImage: "exclamationmark.bubble")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthViewModel())
}
