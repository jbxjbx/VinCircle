// MARK: - InviteCode.swift
// FRIDAYRED - Wine Ranking App
// Invite code model for invite-only access

import Foundation

// MARK: - Invite Code Model
struct InviteCode: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let ownerUserId: UUID
    let code: String           // e.g., "WINE-A3X9"
    var usedByUserId: UUID?
    var usedAt: Date?
    let createdAt: Date
    var isActive: Bool
    
    init(
        id: UUID = UUID(),
        ownerUserId: UUID,
        code: String? = nil,
        usedByUserId: UUID? = nil,
        usedAt: Date? = nil,
        createdAt: Date = Date(),
        isActive: Bool = true
    ) {
        self.id = id
        self.ownerUserId = ownerUserId
        self.code = code ?? InviteCode.generateCode()
        self.usedByUserId = usedByUserId
        self.usedAt = usedAt
        self.createdAt = createdAt
        self.isActive = isActive
    }
    
    /// Whether this code has been used
    var isUsed: Bool {
        usedByUserId != nil
    }
    
    /// Generate a random invite code
    static func generateCode() -> String {
        let letters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"  // Exclude confusing chars
        let random = (0..<4).map { _ in letters.randomElement()! }
        return "WINE-\(String(random))"
    }
    
    /// Generate initial 5 invite codes for a new user
    static func generateInitialCodes(for userId: UUID) -> [InviteCode] {
        (0..<5).map { _ in InviteCode(ownerUserId: userId) }
    }
}

// MARK: - User Invite Extensions
extension Array where Element == InviteCode {
    /// Count of remaining (unused) invite codes
    var remainingCount: Int {
        filter { !$0.isUsed && $0.isActive }.count
    }
    
    /// Count of used invite codes
    var usedCount: Int {
        filter { $0.isUsed }.count
    }
}
