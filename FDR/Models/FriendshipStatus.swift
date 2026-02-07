// MARK: - FriendshipStatus.swift
// VinCircle - iOS Social Wine App
// Friendship model with status tracking and OTP invitation system

import Foundation

// MARK: - Friendship Status Enum

enum FriendshipStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case accepted = "accepted"
    case blocked = "blocked"
    case declined = "declined"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .accepted: return "Friend"
        case .blocked: return "Blocked"
        case .declined: return "Declined"
        }
    }
    
    var iconName: String {
        switch self {
        case .pending: return "clock"
        case .accepted: return "person.badge.check"
        case .blocked: return "person.badge.minus"
        case .declined: return "xmark.circle"
        }
    }
}

// MARK: - Friendship Model

struct Friendship: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let requesterId: UUID       // User who sent the request
    let requesteeId: UUID       // User who received the request
    var status: FriendshipStatus
    
    let createdAt: Date
    var updatedAt: Date
    var acceptedAt: Date?
    
    /// The method used to create this friendship
    let inviteMethod: FriendInviteMethod
    
    // MARK: - Computed Properties
    
    var isAccepted: Bool {
        status == .accepted
    }
    
    var isPending: Bool {
        status == .pending
    }
    
    // MARK: - Initialization
    
    init(
        id: UUID = UUID(),
        requesterId: UUID,
        requesteeId: UUID,
        inviteMethod: FriendInviteMethod = .userId
    ) {
        self.id = id
        self.requesterId = requesterId
        self.requesteeId = requesteeId
        self.status = .pending
        self.createdAt = Date()
        self.updatedAt = Date()
        self.inviteMethod = inviteMethod
    }
    
    // MARK: - Mutations
    
    mutating func accept() {
        status = .accepted
        acceptedAt = Date()
        updatedAt = Date()
    }
    
    mutating func decline() {
        status = .declined
        updatedAt = Date()
    }
    
    mutating func block() {
        status = .blocked
        updatedAt = Date()
    }
}

// MARK: - Friend Invite Method

enum FriendInviteMethod: String, Codable {
    case userId = "user_id"
    case otpCode = "otp_code"
    case qrCode = "qr_code"
}

// MARK: - OTP Invite

struct FriendInviteOTP: Identifiable, Codable, Sendable {
    let id: UUID
    let creatorId: UUID
    let code: String            // 6-digit code
    let createdAt: Date
    let expiresAt: Date
    var isUsed: Bool
    var usedByUserId: UUID?
    
    // MARK: - Computed Properties
    
    var isExpired: Bool {
        Date() > expiresAt
    }
    
    var isValid: Bool {
        !isExpired && !isUsed
    }
    
    var remainingTime: TimeInterval {
        max(0, expiresAt.timeIntervalSince(Date()))
    }
    
    var formattedRemainingTime: String {
        let minutes = Int(remainingTime / 60)
        let seconds = Int(remainingTime.truncatingRemainder(dividingBy: 60))
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - Initialization
    
    init(creatorId: UUID, expirationMinutes: Int = 10) {
        self.id = UUID()
        self.creatorId = creatorId
        self.code = FriendInviteOTP.generateCode()
        self.createdAt = Date()
        self.expiresAt = Date().addingTimeInterval(TimeInterval(expirationMinutes * 60))
        self.isUsed = false
    }
    
    // MARK: - Helper Methods
    
    static func generateCode() -> String {
        String(format: "%06d", Int.random(in: 0...999999))
    }
    
    mutating func markAsUsed(by userId: UUID) {
        isUsed = true
        usedByUserId = userId
    }
}

// MARK: - Friend with User Details

struct FriendWithDetails: Identifiable, Codable, Hashable, Sendable {
    let id: UUID                // Friendship ID
    let friend: User
    let friendshipStatus: FriendshipStatus
    let friendsSince: Date?
    
    /// Whether this user sent the friend request
    let isRequester: Bool
    
    /// Recent activity from this friend
    var recentPosts: [WinePost]?
    var recentPostCount: Int?
    
    // MARK: - Computed Properties
    
    var friendsSinceFormatted: String? {
        guard let date = friendsSince else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "Friends since \(formatter.string(from: date))"
    }
}

// MARK: - Inner Circle (max 10 friends)

struct InnerCircle: Codable, Sendable {
    let userId: UUID
    var friends: [FriendWithDetails]
    
    // MARK: - Computed Properties
    
    var count: Int {
        friends.count
    }
    
    var isFull: Bool {
        friends.count >= 10
    }
    
    var remainingSlots: Int {
        max(0, 10 - friends.count)
    }
    
    var acceptedFriends: [FriendWithDetails] {
        friends.filter { $0.friendshipStatus == .accepted }
    }
    
    var pendingRequests: [FriendWithDetails] {
        friends.filter { $0.friendshipStatus == .pending }
    }
    
    // MARK: - Methods
    
    func canAddFriend() -> Bool {
        acceptedFriends.count < 10
    }
    
    func isFriend(with userId: UUID) -> Bool {
        acceptedFriends.contains { $0.friend.id == userId }
    }
}

// MARK: - Validation Errors

enum FriendshipError: Error, LocalizedError {
    case innerCircleFull
    case alreadyFriends
    case pendingRequestExists
    case userBlocked
    case invalidOTP
    case expiredOTP
    case selfFriendRequest
    case userNotFound
    
    var errorDescription: String? {
        switch self {
        case .innerCircleFull:
            return "Your Inner Circle is full (max 10 friends)"
        case .alreadyFriends:
            return "You're already friends with this user"
        case .pendingRequestExists:
            return "A friend request is already pending"
        case .userBlocked:
            return "Cannot send request to blocked user"
        case .invalidOTP:
            return "Invalid invitation code"
        case .expiredOTP:
            return "This invitation code has expired"
        case .selfFriendRequest:
            return "You cannot add yourself as a friend"
        case .userNotFound:
            return "User not found"
        }
    }
}
