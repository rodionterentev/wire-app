# iOS Project Structure - Complete File List

## ✅ Files Already Created

### Configuration
- `.gitignore` - Git ignore rules
- `README.md` - Project documentation

### Utilities
- `WireGuardManager/Utilities/Constants.swift` - App constants
- `WireGuardManager/Utilities/Extensions.swift` - Helper extensions

### Models
- `WireGuardManager/Models/User.swift` - User model
- `WireGuardManager/Models/Peer.swift` - Peer model
- `WireGuardManager/Models/APIModels.swift` - API request/response models

### Services
- `WireGuardManager/Services/KeychainService.swift` - Secure storage
- `WireGuardManager/Services/APIService.swift` - HTTP API client

## 📝 Files to Create in Xcode

You'll need to create these files manually in Xcode:

### 1. App Entry Point
```swift
// WireGuardManager/WireGuardManagerApp.swift
import SwiftUI

@main
struct WireGuardManagerApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some Scene {
        WindowGroup {
            if authViewModel.isAuthenticated {
                PeerListView()
                    .environmentObject(authViewModel)
            } else {
                LoginView()
                    .environmentObject(authViewModel)
            }
        }
    }
}
```

### 2. ViewModels

**AuthViewModel.swift:**
```swift
import Foundation
import Combine

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiService = APIService.shared
    
    init() {
        checkAuthStatus()
    }
    
    func checkAuthStatus() {
        isAuthenticated = KeychainService.shared.isLoggedIn
        if isAuthenticated {
            Task {
                await loadCurrentUser()
            }
        }
    }
    
    func login(username: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            _ = try await apiService.login(username: username, password: password)
            await loadCurrentUser()
            isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func logout() {
        apiService.logout()
        isAuthenticated = false
        currentUser = nil
    }
    
    private func loadCurrentUser() async {
        do {
            currentUser = try await apiService.getCurrentUser()
        } catch {
            print("Failed to load user: \(error)")
        }
    }
}
```

**PeerViewModel.swift:**
```swift
import Foundation
import Combine

@MainActor
class PeerViewModel: ObservableObject {
    @Published var peers: [Peer] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var serverStats: ServerStatistics?
    
    private let apiService = APIService.shared
    
    func loadPeers() async {
        isLoading = true
        errorMessage = nil
        
        do {
            peers = try await apiService.getPeers()
            await loadServerStats()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func createPeer(name: String, description: String) async throws {
        let peer = try await apiService.createPeer(
            name: name,
            description: description
        )
        peers.append(peer)
        await loadServerStats()
    }
    
    func togglePeer(_ peer: Peer) async {
        do {
            let response = try await apiService.togglePeer(id: peer.id)
            if let index = peers.firstIndex(where: { $0.id == peer.id }) {
                // Update local peer
                var updatedPeer = peers[index]
                updatedPeer = try await apiService.getPeer(id: peer.id)
                peers[index] = updatedPeer
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func deletePeer(_ peer: Peer) async {
        do {
            try await apiService.deletePeer(id: peer.id)
            peers.removeAll { $0.id == peer.id }
            await loadServerStats()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func loadServerStats() async {
        do {
            serverStats = try await apiService.getServerStats()
        } catch {
            print("Failed to load stats: \(error)")
        }
    }
}
```

### 3. Views

**LoginView.swift:**
```swift
import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var username = ""
    @State private var password = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Logo/Icon
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                    .padding(.bottom, 30)
                
                // Title
                Text("WireGuard Manager")
                    .font(.title)
                    .fontWeight(.bold)
                
                // Input fields
                VStack(spacing: 15) {
                    TextField("Username", text: $username)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.username)
                        .autocapitalization(.none)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.password)
                }
                .padding(.horizontal)
                
                // Error message
                if let error = authViewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Login button
                Button(action: { Task { await login() } }) {
                    if authViewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                    } else {
                        Text("Login")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.horizontal)
                .disabled(authViewModel.isLoading || !isFormValid)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Login")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var isFormValid: Bool {
        !username.isEmpty && !password.isEmpty
    }
    
    private func login() async {
        await authViewModel.login(username: username, password: password)
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthViewModel())
}
```

**PeerListView.swift:**
```swift
import SwiftUI

struct PeerListView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = PeerViewModel()
    @State private var showingCreatePeer = false
    
    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isLoading && viewModel.peers.isEmpty {
                    ProgressView("Loading peers...")
                } else if viewModel.peers.isEmpty {
                    emptyState
                } else {
                    peersList
                }
            }
            .navigationTitle("VPN Peers")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button(action: { authViewModel.logout() }) {
                            Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } label: {
                        Image(systemName: "person.circle")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreatePeer = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .refreshable {
                await viewModel.loadPeers()
            }
            .sheet(isPresented: $showingCreatePeer) {
                CreatePeerView(viewModel: viewModel)
            }
            .task {
                await viewModel.loadPeers()
            }
        }
    }
    
    private var peersList: some View {
        List {
            // Server stats section
            if let stats = viewModel.serverStats {
                Section("Server Status") {
                    HStack {
                        Text("Total Peers")
                        Spacer()
                        Text("\(stats.totalPeers)")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Online")
                        Spacer()
                        Text("\(stats.onlinePeers)")
                            .foregroundColor(.green)
                    }
                    HStack {
                        Text("Total Data")
                        Spacer()
                        Text("↓ \(stats.totalRxFormatted) ↑ \(stats.totalTxFormatted)")
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Peers section
            Section("Devices") {
                ForEach(viewModel.peers) { peer in
                    PeerRow(peer: peer, viewModel: viewModel)
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        let peer = viewModel.peers[index]
                        Task {
                            await viewModel.deletePeer(peer)
                        }
                    }
                }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No VPN Peers")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Create your first peer to get started")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: { showingCreatePeer = true }) {
                Label("Create Peer", systemImage: "plus.circle.fill")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
}

struct PeerRow: View {
    let peer: Peer
    let viewModel: PeerViewModel
    
    var body: some View {
        HStack {
            // Status indicator
            Circle()
                .fill(peer.isOnline ? Color.green : Color.gray)
                .frame(width: 10, height: 10)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(peer.name)
                    .font(.headline)
                
                Text(peer.shortIpAddress)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 12) {
                    Label(peer.formattedRx, systemImage: "arrow.down.circle")
                    Label(peer.formattedTx, systemImage: "arrow.up.circle")
                }
                .font(.caption2)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Enable/Disable toggle
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
```

**CreatePeerView.swift:**
```swift
import SwiftUI

struct CreatePeerView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: PeerViewModel
    
    @State private var name = ""
    @State private var description = ""
    @State private var isCreating = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            Form {
                Section("Device Information") {
                    TextField("Name", text: $name)
                        .autocapitalization(.words)
                    
                    TextField("Description (optional)", text: $description)
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("New Peer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: create) {
                        if isCreating {
                            ProgressView()
                        } else {
                            Text("Create")
                        }
                    }
                    .disabled(!isFormValid || isCreating)
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    private func create() {
        Task {
            isCreating = true
            errorMessage = nil
            
            do {
                try await viewModel.createPeer(
                    name: name,
                    description: description.isEmpty ? nil : description
                )
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            
            isCreating = false
        }
    }
}
```

## 🔧 Dependencies to Add

In Xcode, add these Swift Package Dependencies:

### Optional (for future VPN functionality):
- **WireGuardKit**: `https://github.com/WireGuard/wireguard-apple`
  - Note: Requires Network Extension entitlement
  - Only needed for actual VPN tunneling

## 📋 Xcode Setup Steps

1. **Create New Project**
   - File → New → Project
   - iOS → App
   - Product Name: WireGuardManager
   - Interface: SwiftUI
   - Language: Swift

2. **Add Files**
   - Copy all created files into the project
   - Ensure they're in correct folders

3. **Update Info.plist** (if needed)
   - Add URL schemes
   - Add network permissions

4. **Build Settings**
   - Set minimum deployment target: iOS 15.0
   - Configure signing

5. **Run**
   - Select simulator or device
   - Build and run (⌘R)

## 🎯 Next Steps

After creating the project:

1. Test login with your backend
2. Create a peer
3. View peer list
4. Add VPN functionality (WireGuardKit)
5. Add more features (statistics, settings, etc.)
