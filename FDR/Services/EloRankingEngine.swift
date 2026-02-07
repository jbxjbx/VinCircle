// MARK: - EloRankingEngine.swift
// VinCircle - iOS Social Wine App
// Elo Rating Algorithm for personal wine leaderboard with pairwise comparisons

import Foundation

// MARK: - Elo Ranking Engine

@MainActor
final class EloRankingEngine {
    
    // MARK: - Configuration
    
    /// K-factor determines how much ratings change per comparison
    /// Higher = more volatile, Lower = more stable
    private let kFactor: Double = 32.0
    
    /// Initial Elo rating for new wines
    private let initialRating: Double = 1000.0
    
    // MARK: - Core Update Method
    
    /// Update Elo ratings after a pairwise comparison
    /// - Parameters:
    ///   - winner: The wine the user preferred
    ///   - loser: The wine that lost the comparison
    /// - Returns: Updated ratings for both wines
    func updateRatings(
        winner: inout EloRating,
        loser: inout EloRating
    ) -> (winnerNewRating: Double, loserNewRating: Double) {
        // Calculate expected scores
        let expectedWinner = expectedScore(rating: winner.rating, opponentRating: loser.rating)
        let expectedLoser = expectedScore(rating: loser.rating, opponentRating: winner.rating)
        
        // Winner gets score of 1.0, loser gets 0.0
        let winnerNewRating = winner.rating + kFactor * (1.0 - expectedWinner)
        let loserNewRating = loser.rating + kFactor * (0.0 - expectedLoser)
        
        // Update the ratings
        winner.rating = winnerNewRating
        winner.comparisonCount += 1
        winner.wins += 1
        
        loser.rating = loserNewRating
        loser.comparisonCount += 1
        loser.losses += 1
        
        return (winnerNewRating, loserNewRating)
    }
    
    /// Calculate expected score using Elo formula
    private func expectedScore(rating: Double, opponentRating: Double) -> Double {
        1.0 / (1.0 + pow(10.0, (opponentRating - rating) / 400.0))
    }
    
    // MARK: - Leaderboard Generation
    
    /// Generate a filtered leaderboard from user's wine ratings
    func generateLeaderboard(
        ratings: [EloRating],
        posts: [WinePost],
        filter: LeaderboardFilter? = nil,
        limit: Int = 10
    ) -> [LeaderboardEntry] {
        // Create a mapping of post IDs to posts
        let postDict = Dictionary(uniqueKeysWithValues: posts.map { ($0.id, $0) })
        
        // Filter and sort ratings
        var filteredRatings = ratings
        
        if let filter = filter {
            filteredRatings = ratings.filter { rating in
                guard let post = postDict[rating.winePostId] else { return false }
                return filter.matches(post: post)
            }
        }
        
        // Sort by Elo rating (descending)
        let sortedRatings = filteredRatings.sorted { $0.rating > $1.rating }
        
        // Create leaderboard entries
        var entries: [LeaderboardEntry] = []
        
        for (index, rating) in sortedRatings.prefix(limit).enumerated() {
            guard let post = postDict[rating.winePostId] else { continue }
            
            let entry = LeaderboardEntry(
                rank: index + 1,
                winePost: post,
                eloRating: rating,
                previousRank: nil // Could be calculated from historical data
            )
            entries.append(entry)
        }
        
        return entries
    }
    
    // MARK: - Comparison Selection
    
    /// Select an optimal wine for comparison based on similar Elo ratings
    /// This creates more meaningful comparisons
    func selectComparisonWine(
        newWine: WinePost,
        existingRatings: [EloRating],
        posts: [WinePost],
        filter: LeaderboardFilter? = nil
    ) -> WinePost? {
        let postDict = Dictionary(uniqueKeysWithValues: posts.map { ($0.id, $0) })
        
        // Get wines with similar ratings (within 200 Elo of initial)
        let targetRating = initialRating
        
        var candidates = existingRatings.compactMap { rating -> (EloRating, WinePost)? in
            guard let post = postDict[rating.winePostId] else { return nil }
            // Exclude the same wine
            if post.wineId == newWine.wineId { return nil }
            // Apply filter if provided
            if let filter = filter, !filter.matches(post: post) { return nil }
            return (rating, post)
        }
        
        // Sort by closeness to target rating
        candidates.sort { abs($0.0.rating - targetRating) < abs($1.0.rating - targetRating) }
        
        // Return the closest match, or a random one from top 5
        if candidates.isEmpty {
            return nil
        }
        
        let topCandidates = Array(candidates.prefix(5))
        return topCandidates.randomElement()?.1
    }
    
    // MARK: - Initial Rating
    
    /// Create initial Elo rating for a new wine post
    func createInitialRating(for postId: UUID) -> EloRating {
        EloRating(winePostId: postId, initialRating: initialRating)
    }
    
    // MARK: - Statistics
    
    /// Calculate user's rating distribution statistics
    func calculateStatistics(ratings: [EloRating]) -> RatingStatistics {
        guard !ratings.isEmpty else {
            return RatingStatistics(
                averageRating: initialRating,
                highestRating: initialRating,
                lowestRating: initialRating,
                totalComparisons: 0,
                ratingDistribution: [:]
            )
        }
        
        let allRatings = ratings.map { $0.rating }
        let average = allRatings.reduce(0, +) / Double(allRatings.count)
        
        // Create distribution buckets (every 100 Elo points)
        var distribution: [String: Int] = [:]
        for rating in allRatings {
            let bucket = Int(rating / 100) * 100
            let key = "\(bucket)-\(bucket + 99)"
            distribution[key, default: 0] += 1
        }
        
        return RatingStatistics(
            averageRating: average,
            highestRating: allRatings.max() ?? initialRating,
            lowestRating: allRatings.min() ?? initialRating,
            totalComparisons: ratings.reduce(0) { $0 + $1.comparisonCount },
            ratingDistribution: distribution
        )
    }
}

// MARK: - Leaderboard Filter

struct LeaderboardFilter: Codable, Sendable {
    var wineType: WineType?
    var region: String?
    var country: String?
    var varietal: String?
    var minVintage: Int?
    var maxVintage: Int?
    var minScore: Int?
    
    func matches(post: WinePost) -> Bool {
        if let wineType = wineType, post.wineType != wineType {
            return false
        }
        if let region = region, !post.region.localizedCaseInsensitiveContains(region) {
            return false
        }
        if let country = country, !post.country.localizedCaseInsensitiveContains(country) {
            return false
        }
        if let varietal = varietal, !post.varietal.localizedCaseInsensitiveContains(varietal) {
            return false
        }
        if let minVintage = minVintage, post.vintage < minVintage {
            return false
        }
        if let maxVintage = maxVintage, post.vintage > maxVintage {
            return false
        }
        if let minScore = minScore, post.subjectiveScore < minScore {
            return false
        }
        return true
    }
    
    var isEmpty: Bool {
        wineType == nil && region == nil && country == nil && 
        varietal == nil && minVintage == nil && maxVintage == nil && minScore == nil
    }
    
    var description: String {
        var parts: [String] = []
        
        if let wineType = wineType {
            parts.append(wineType.rawValue)
        }
        if let region = region {
            parts.append("from \(region)")
        }
        if let country = country {
            parts.append(country)
        }
        if let varietal = varietal {
            parts.append(varietal)
        }
        
        return parts.isEmpty ? "All Wines" : parts.joined(separator: " • ")
    }
}

// MARK: - Leaderboard Entry

struct LeaderboardEntry: Identifiable, Codable, Sendable {
    var id: UUID { winePost.id }
    
    let rank: Int
    let winePost: WinePost
    let eloRating: EloRating
    let previousRank: Int?
    
    var rankChange: RankChange {
        guard let previous = previousRank else { return .new }
        if rank < previous { return .up(previous - rank) }
        if rank > previous { return .down(rank - previous) }
        return .same
    }
}

enum RankChange: Codable {
    case up(Int)
    case down(Int)
    case same
    case new
    
    var iconName: String {
        switch self {
        case .up: return "arrow.up.circle.fill"
        case .down: return "arrow.down.circle.fill"
        case .same: return "minus.circle.fill"
        case .new: return "star.circle.fill"
        }
    }
    
    var color: String {
        switch self {
        case .up: return "#34C759"   // Green
        case .down: return "#FF3B30" // Red
        case .same: return "#8E8E93" // Gray
        case .new: return "#FFD60A"  // Yellow
        }
    }
}

// MARK: - Rating Statistics

struct RatingStatistics: Codable, Sendable {
    let averageRating: Double
    let highestRating: Double
    let lowestRating: Double
    let totalComparisons: Int
    let ratingDistribution: [String: Int]
}

// MARK: - Comparison Prompt

struct ComparisonPrompt: Identifiable {
    let id = UUID()
    let newWine: WinePost
    let comparisonWine: WinePost
    let comparisonRating: EloRating
    
    var promptText: String {
        "Do you prefer this bottle over \(comparisonWine.wineName) (\(comparisonWine.vintage))?"
    }
}
