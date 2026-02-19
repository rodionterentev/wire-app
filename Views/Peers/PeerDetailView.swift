//
//  PeerDetailView.swift
//  WireGuardManager
//
//  Created by Claude on 2026-02-01.
//

import SwiftUI

struct PeerDetailView: View {

    let peer: Peer
    @ObservedObject var viewModel: PeerViewModel
    @State private var config: PeerConfigResponse?
    @State private var showingConfig = false
    @State private var isLoading = false
    
    var body: some View {
        List {
            // Status Section
            Section("Status") {
                HStack {
                    Text("Enabled")
                    Spacer()
                    Circle()
                        .fill(peer.isEnabled ? Color.green : Color.gray)
                        .frame(width: 12, height: 12)
                    Text(peer.isEnabled ? "Active" : "Disabled")
                        .foregroundColor(.gray)
                }
                
                HStack {
                    Text("IP Address")
                    Spacer()
                    Text(peer.ipAddress)
                        .foregroundColor(.gray)
                }
            }
            
            // Traffic Section
            Section("Traffic") {
                HStack {
                    Label("Downloaded", systemImage: "arrow.down.circle.fill")
                        .foregroundColor(.blue)
                    Spacer()
                    Text(peer.formattedRx)
                        .foregroundColor(.gray)
                }
                
                HStack {
                    Label("Uploaded", systemImage: "arrow.up.circle.fill")
                        .foregroundColor(.green)
                    Spacer()
                    Text(peer.formattedTx)
                        .foregroundColor(.gray)
                }
            }
            
            // Details Section
            Section("Details") {
                HStack {
                    Text("Name")
                    Spacer()
                    Text(peer.name)
                        .foregroundColor(.gray)
                }
                
                if let description = peer.description {
                    HStack {
                        Text("Description")
                        Spacer()
                        Text(description)
                            .foregroundColor(.gray)
                    }
                }
                
                HStack {
                    Text("Created")
                    Spacer()
                    Text(formatDate(peer.createdAt))
                        .foregroundColor(.gray)
                }
            }
            
            // Configuration Section
            Section("Configuration") {
                Button(action: {
                    Task {
                        await loadConfig()
                    }
                }) {
                    HStack {
                        Label("View Config", systemImage: "doc.text")
                        Spacer()
                        if isLoading {
                            ProgressView()
                        } else {
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Button(action: {
                    Task {
                        await loadConfig()
                        if config != nil {
                            shareConfig()
                        }
                    }
                }) {
                    Label("Share Config", systemImage: "square.and.arrow.up")
                }
            }
            
            // Actions Section
            Section {
                Button(role: .destructive, action: {
                    Task {
                        await viewModel.deletePeer(peer)
                    }
                }) {
                    Label("Delete Peer", systemImage: "trash")
                }
            }
        }
        .navigationTitle(peer.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingConfig) {
            if let config = config {
                ConfigView(config: config)
            }
        }
    }
    
    // MARK: - Actions
    
    private func loadConfig() async {
        isLoading = true
        config = await viewModel.getPeerConfig(peerId: peer.id)
        isLoading = false
        
        if config != nil {
            showingConfig = true
        }
    }
    
    private func shareConfig() {
        guard let config = config else { return }
        
        let activityVC = UIActivityViewController(
            activityItems: [config.configText],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        
        return dateString
    }
}

// MARK: - Config View
struct ConfigView: View {
    let config: PeerConfigResponse
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // QR Code
                    if let qrBase64 = config.qrCodeBase64,
                       let qrImage = base64ToImage(qrBase64) {
                        VStack {
                            Text("Scan QR Code")
                                .font(.headline)
                            
                            Image(uiImage: qrImage)
                                .resizable()
                                .interpolation(.none)
                                .scaledToFit()
                                .frame(width: 250, height: 250)
                                .padding()
                        }
                    }
                    
                    // Config Text
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Configuration")
                            .font(.headline)
                        
                        Text(config.configText)
                            .font(.system(.caption, design: .monospaced))
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    .padding()
                }
            }
            .navigationTitle("Peer Config")
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
    
    private func base64ToImage(_ base64String: String) -> UIImage? {
        // Remove data:image/png;base64, prefix if present
        let cleanBase64 = base64String.replacingOccurrences(of: "data:image/png;base64,", with: "")
        
        guard let data = Data(base64Encoded: cleanBase64) else {
            return nil
        }
        
        return UIImage(data: data)
    }
}

#Preview {
    NavigationView {
        PeerDetailView(
            peer: Peer(
                id: 1,
                name: "iPhone 15 Pro",
                description: "My phone",
                deviceName: nil,
                deviceIdentifier: nil,
                publicKey: "test123",
                ipAddress: "10.8.0.2/32",
                allowedIps: "0.0.0.0/0",
                persistentKeepalive: 25,
                isActive: true,
                isEnabled: true,
                totalRx: 1024000,
                totalTx: 512000,
                lastHandshake: nil,
                createdAt: "2026-02-01T20:00:00",
                updatedAt: "2026-02-01T20:00:00"
            ),
            viewModel: PeerViewModel()
        )
    }
}
