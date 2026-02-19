//
//  PeerListView.swift
//  WireGuardManager
//
//  Created by Claude on 2026-02-01.
//

import SwiftUI

struct PeerListView: View {
    
    @StateObject private var viewModel = PeerViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingCreateSheet = false
    @State private var showingSettings = false
    @State private var showingError = false
    
    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isLoading && viewModel.peers.isEmpty {
                    ProgressView("Loading peers...")
                } else if viewModel.peers.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "network.slash")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.gray)
                        
                        Text("No Peers")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Create your first VPN peer")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Button(action: {
                            showingCreateSheet = true
                        }) {
                            Label("Create Peer", systemImage: "plus.circle.fill")
                                .fontWeight(.semibold)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                } else {
                    List {
                        // Server Stats Section
                        if let stats = viewModel.serverStats {
                            Section("Server Statistics") {
                                HStack {
                                    Label("Total Peers", systemImage: "number")
                                    Spacer()
                                    Text("\(stats.totalPeers)")
                                        .foregroundColor(.gray)
                                }
                                
                                HStack {
                                    Label("Online", systemImage: "circle.fill")
                                        .foregroundColor(.green)
                                    Spacer()
                                    Text("\(stats.onlinePeers)")
                                        .foregroundColor(.gray)
                                }
                                
                                HStack {
                                    Label("Downloaded", systemImage: "arrow.down.circle")
                                    Spacer()
                                    Text(stats.totalRxFormatted)
                                        .foregroundColor(.gray)
                                }
                                
                                HStack {
                                    Label("Uploaded", systemImage: "arrow.up.circle")
                                    Spacer()
                                    Text(stats.totalTxFormatted)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        
                        // Peers Section
                        Section("My Devices") {
                            ForEach(viewModel.peers) { peer in
                                NavigationLink(destination: PeerDetailView(peer: peer, viewModel: viewModel)) {
                                    PeerRowView(peer: peer, viewModel: viewModel)
                                }
                            }
                            .onDelete(perform: deletePeers)
                        }
                    }
                    .refreshable {
                        await refreshData()
                    }
                }
            }
            .navigationTitle("VPN Manager")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingCreateSheet = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gear")
                    }
                }
            }
            .sheet(isPresented: $showingCreateSheet) {
                CreatePeerView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .task {
                await refreshData()
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
            .onChange(of: viewModel.errorMessage) { _, newValue in
                showingError = newValue != nil
            }
        }
    }
    
    // MARK: - Actions
    
    private func refreshData() async {
        await viewModel.fetchPeers()
        await viewModel.fetchServerStats()
    }
    
    private func deletePeers(at offsets: IndexSet) {
        for index in offsets {
            let peer = viewModel.peers[index]
            Task {
                await viewModel.deletePeer(peer)
            }
        }
    }
}

// MARK: - Peer Row View
struct PeerRowView: View {
    let peer: Peer
    @ObservedObject var viewModel: PeerViewModel
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(peer.name)
                    .font(.headline)
                
                Text(peer.ipAddress)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                HStack(spacing: 15) {
                    Label(peer.formattedRx, systemImage: "arrow.down")
                        .font(.caption2)
                        .foregroundColor(.blue)
                    
                    Label(peer.formattedTx, systemImage: "arrow.up")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
            }
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { peer.isEnabled },
                set: { _ in
                    Task {
                        await viewModel.togglePeer(peer)
                    }
                }
            ))
            .labelsHidden()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    PeerListView()
        .environmentObject(AuthViewModel())
}
