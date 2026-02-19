//
//  Extensions.swift
//  WireGuardManager
//
//  Useful extensions for common tasks
//

import Foundation
import SwiftUI

// MARK: - Date Extensions

extension Date {
    /// Format date as relative time ago (e.g., "2 hours ago")
    func timeAgoDisplay() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }
    
    /// Format date as short string
    var shortFormat: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
}

// MARK: - String Extensions

extension String {
    /// Check if string is a valid email
    var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return predicate.evaluate(with: self)
    }
    
    /// Trim whitespace and newlines
    var trimmed: String {
        self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Int Extensions

extension Int {
    /// Format bytes to human readable string (e.g., "1.5 GB")
    func formatBytes() -> String {
        let bytes = Double(self)
        let units = ["B", "KB", "MB", "GB", "TB"]
        
        if bytes < 1024 {
            return String(format: "%.0f %@", bytes, units[0])
        }
        
        var unitIndex = 0
        var value = bytes
        
        while value >= 1024 && unitIndex < units.count - 1 {
            value /= 1024
            unitIndex += 1
        }
        
        return String(format: "%.2f %@", value, units[unitIndex])
    }
}

// MARK: - View Extensions

extension View {
    /// Apply a conditional modifier
    @ViewBuilder
    func `if`<Transform: View>(
        _ condition: Bool,
        transform: (Self) -> Transform
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    /// Hide keyboard
    func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}

// MARK: - Color Extensions

extension Color {
    /// App theme colors
    static let appPrimary = Color.blue
    static let appSecondary = Color.gray
    static let appSuccess = Color.green
    static let appDanger = Color.red
    static let appWarning = Color.orange
    
    /// Status colors
    static let statusConnected = Color.green
    static let statusDisconnected = Color.gray
    static let statusConnecting = Color.orange
    static let statusError = Color.red
}

// MARK: - URL Extensions

extension URL {
    /// Check if URL is reachable
    var isReachable: Bool {
        guard let reachability = try? Reachability(hostname: self.host ?? "") else {
            return false
        }
        return reachability.connection != .unavailable
    }
}

// MARK: - Optional Extensions

extension Optional where Wrapped == String {
    /// Return empty string if nil
    var orEmpty: String {
        self ?? ""
    }
}

// MARK: - Array Extensions

extension Array where Element: Identifiable {
    /// Find element by ID
    func first(withId id: Element.ID) -> Element? {
        first { $0.id == id }
    }
    
    /// Remove element by ID
    mutating func remove(withId id: Element.ID) {
        removeAll { $0.id == id }
    }
}

// MARK: - Task Extensions

extension Task where Success == Never, Failure == Never {
    /// Sleep for specified seconds
    static func sleep(seconds: Double) async throws {
        try await sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }
}

// MARK: - Reachability Helper

/// Simple reachability check
class Reachability {
    enum Connection {
        case unavailable
        case wifi
        case cellular
    }
    
    var connection: Connection = .unavailable
    
    init(hostname: String) {
        // Simplified reachability check
        // In production, use a proper reachability library
        connection = .wifi
    }
}
