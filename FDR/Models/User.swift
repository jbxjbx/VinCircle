// MARK: - User.swift
// VinCircle - iOS Social Wine App
// Core user data model with achievements and friendship management

import Foundation

// MARK: - User Model

struct User: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var displayName: String
    var email: String?
    var profileImageURL: URL?
    
    /// 6-digit unique code for friend invitations
    var uniqueCode: String
    
    /// Timestamps
    var createdAt: Date
    var lastLoginAt: Date?
    
    /// Statistics
    var tastingCount: Int
    var joinedInnerCircle: Date?
    
    /// Relationships (stored separately, referenced here for convenience)
    var friendIds: [UUID]
    var pendingFriendRequests: [UUID]
    
    /// Achievements unlocked
    var achievements: [Achievement]
    
    /// Sign in method tracking
    var authProvider: AuthProvider
    
    // MARK: - Computed Properties
    
    /// Check if user can add more friends (max 10)
    var canAddMoreFriends: Bool {
        friendIds.count < 10
    }
    
    /// Remaining friend slots
    var remainingFriendSlots: Int {
        max(0, 10 - friendIds.count)
    }
    
    // MARK: - Initialization
    
    init(
        id: UUID = UUID(),
        displayName: String,
        email: String? = nil,
        profileImageURL: URL? = nil,
        authProvider: AuthProvider = .apple
    ) {
        self.id = id
        self.displayName = displayName
        self.email = email
        self.profileImageURL = profileImageURL
        self.uniqueCode = User.generateUniqueCode()
        self.createdAt = Date()
        self.lastLoginAt = Date()
        self.tastingCount = 0
        self.friendIds = []
        self.pendingFriendRequests = []
        self.achievements = []
        self.authProvider = authProvider
    }
    
    // MARK: - Helper Methods
    
    static func generateUniqueCode() -> String {
        String(format: "%06d", Int.random(in: 0...999999))
    }
}

// MARK: - Auth Provider

enum AuthProvider: String, Codable {
    case apple = "apple"
    case passkey = "passkey"
}

// MARK: - Achievement Model

struct Achievement: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let type: AchievementType
    let unlockedAt: Date
    let description: String
    
    init(type: AchievementType) {
        self.id = UUID()
        self.type = type
        self.unlockedAt = Date()
        self.description = type.description
    }
}

enum AchievementType: String, Codable, CaseIterable {
    case firstTasting = "first_tasting"
    case tenTastings = "ten_tastings"
    case fiftyTastings = "fifty_tastings"
    case hundredTastings = "hundred_tastings"
    case wineExplorer = "wine_explorer"        // 5 different regions
    case vintageHunter = "vintage_hunter"      // Tasted 10+ year old wine
    case socialButterfly = "social_butterfly"  // Added 5 friends
    case innerCircleComplete = "inner_circle"  // 10 friends
    case topSommelier = "top_sommelier"        // 100+ Elo rating on any wine
    case globeTrotter = "globe_trotter"        // Wines from 10 countries
    
    var description: String {
        switch self {
        case .firstTasting: return "Logged your first wine tasting"
        case .tenTastings: return "Tasted 10 different wines"
        case .fiftyTastings: return "Tasted 50 different wines"
        case .hundredTastings: return "Centurion: 100 wines tasted"
        case .wineExplorer: return "Explored 5 different wine regions"
        case .vintageHunter: return "Tasted a wine 10+ years old"
        case .socialButterfly: return "Added 5 friends to your circle"
        case .innerCircleComplete: return "Completed your Inner Circle of 10"
        case .topSommelier: return "Achieved 100+ Elo on a single wine"
        case .globeTrotter: return "Tasted wines from 10 countries"
        }
    }
    
    var iconName: String {
        switch self {
        case .firstTasting: return "wineglass"
        case .tenTastings: return "10.circle.fill"
        case .fiftyTastings: return "50.circle.fill"
        case .hundredTastings: return "star.circle.fill"
        case .wineExplorer: return "map.fill"
        case .vintageHunter: return "clock.arrow.circlepath"
        case .socialButterfly: return "person.3.fill"
        case .innerCircleComplete: return "circle.hexagongrid.fill"
        case .topSommelier: return "crown.fill"
        case .globeTrotter: return "globe.americas.fill"
        }
    }
    
    var tier: AchievementTier {
        switch self {
        case .firstTasting: return .bronze
        case .tenTastings, .wineExplorer, .socialButterfly: return .silver
        case .fiftyTastings, .vintageHunter: return .gold
        case .hundredTastings, .innerCircleComplete, .topSommelier, .globeTrotter: return .platinum
        }
    }
}

enum AchievementTier: String, Codable {
    case bronze, silver, gold, platinum
    
    var color: String {
        switch self {
        case .bronze: return "#CD7F32"
        case .silver: return "#C0C0C0"
        case .gold: return "#FFD700"
        case .platinum: return "#E5E4E2"
        }
    }
}

// MARK: - User Profile Stats (for PlayStation-style view)

struct UserProfileStats: Codable, Sendable {
    let user: User
    let totalTastings: Int
    let averageScore: Double
    let favoriteRegion: String?
    let favoriteVarietal: String?
    let topWines: [EloRating]
    let recentActivity: [WinePost]
    let achievementProgress: [AchievementProgress]
}

struct AchievementProgress: Codable, Identifiable, Sendable {
    let id: UUID
    let type: AchievementType
    let currentProgress: Int
    let requiredProgress: Int
    var isUnlocked: Bool { currentProgress >= requiredProgress }
    var progressPercentage: Double { Double(currentProgress) / Double(requiredProgress) }
}
