//
//  PeerViewModel.swift
//  WireGuardManager
//
//  Created by Claude on 2026-02-01.
//

import Foundation
import SwiftUI

@MainActor
class PeerViewModel: ObservableObject {
    
    @Published var peers: [Peer] = []
    @Published var serverStats: ServerStatistics?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiService = APIService.shared
    
    // MARK: - Fetch Peers
    func fetchPeers() async {
        isLoading = true
        errorMessage = nil
        
        do {
            peers = try await apiService.getPeers()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Create Peer
    func createPeer(name: String, description: String?) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let newPeer = try await apiService.createPeer(name: name, description: description)
            peers.append(newPeer)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Toggle Peer
    func togglePeer(_ peer: Peer) async {
        do {
            let updatedPeer = try await apiService.togglePeer(peerId: peer.id)
            
            if let index = peers.firstIndex(where: { $0.id == peer.id }) {
                peers[index] = updatedPeer
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Delete Peer
    func deletePeer(_ peer: Peer) async {
        do {
            try await apiService.deletePeer(peerId: peer.id)
            peers.removeAll { $0.id == peer.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Get Peer Config
    func getPeerConfig(peerId: Int) async -> PeerConfigResponse? {
        do {
            return try await apiService.getPeerConfig(peerId: peerId)
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
    
    // MARK: - Fetch Server Stats
    func fetchServerStats() async {
        do {
            serverStats = try await apiService.getServerStatistics()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
