//
//  CreatePeerView.swift
//  WireGuardManager
//
//  Created by Claude on 2026-02-01.
//

import SwiftUI

struct CreatePeerView: View {
    
    @ObservedObject var viewModel: PeerViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var name = ""
    @State private var description = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Device Name", text: $name)
                        .autocapitalization(.words)
                    
                    TextField("Description (optional)", text: $description)
                        .autocapitalization(.sentences)
                } header: {
                    Text("Peer Information")
                } footer: {
                    Text("Give your device a recognizable name")
                }
                
                Section {
                    Text("A new WireGuard configuration will be automatically generated for this device.")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle("New Peer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isLoading)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        Task {
                            await createPeer()
                        }
                    }
                    .disabled(name.isEmpty || isLoading)
                }
            }
            .overlay {
                if isLoading {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        
                        ProgressView("Creating peer...")
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(10)
                    }
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func createPeer() async {
        isLoading = true
        
        await viewModel.createPeer(
            name: name,
            description: description.isEmpty ? nil : description
        )
        
        isLoading = false
        
        if viewModel.errorMessage == nil {
            dismiss()
        }
    }
}

#Preview {
    CreatePeerView(viewModel: PeerViewModel())
}
