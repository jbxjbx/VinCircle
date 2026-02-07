// MARK: - AdaptiveRankingEngine.swift
// FRIDAYRED - Wine Ranking App
// Core ranking engine with adaptive binary insertion algorithm

import Foundation

// MARK: - Comparison Result
enum ComparisonResult: String, Codable, Sendable {
    case preferFirst = "prefer_first"
    case preferSecond = "prefer_second"
    case tie = "tie"
}

// MARK: - Comparison Request
/// A request for the user to compare two wines
struct ComparisonRequest: Identifiable, Sendable {
    let id: UUID
    let firstWineId: UUID
    let secondWineId: UUID
    let comparisonNumber: Int
    let totalComparisons: Int  // Estimated max
    
    init(
        id: UUID = UUID(),
        firstWineId: UUID,
        secondWineId: UUID,
        comparisonNumber: Int,
        totalComparisons: Int
    ) {
        self.id = id
        self.firstWineId = firstWineId
        self.secondWineId = secondWineId
        self.comparisonNumber = comparisonNumber
        self.totalComparisons = totalComparisons
    }
}

// MARK: - Adaptive Ranking Engine
@MainActor
final class AdaptiveRankingEngine: ObservableObject {
    
    // MARK: - Singleton
    static let shared = AdaptiveRankingEngine()
    
    private init() {}
    
    // MARK: - Calculate Max Comparisons
    /// Calculate maximum comparisons needed for binary insertion
    func maxComparisons(forListSize size: Int) -> Int {
        if size <= 0 { return 0 }
        if size == 1 { return 1 }
        // log2(n) rounded up + 1 for safety
        return Int(ceil(log2(Double(size)))) + 1
    }
    
    // MARK: - Place First Wine (Initial Sentiment)
    /// Place the first wine in a new grape ranking with sentiment
    func placeFirstWine(
        in ranking: inout Ranking,
        wineId: UUID,
        vintageYear: Int?,
        sentiment: SentimentBucket,
        notes: String? = nil,
        photos: [URL] = []
    ) {
        let tasting = VintageTasting(
            vintageYear: vintageYear,
            photoURLs: photos,
            tastingNotes: notes,
            isBestVintage: true
        )
        
        let entry = RankEntry(
            wineId: wineId,
            position: 1,  // First wine is always #1
            sentimentBucket: sentiment,
            bestVintageTastingId: tasting.id,
            vintageTastings: [tasting]
        )
        
        ranking.entries.append(entry)
        ranking.updatedAt = Date()
    }
    
    // MARK: - Generate Comparison Sequence
    /// Generate the sequence of comparisons needed for binary insertion
    func generateComparisonSequence(
        existingEntries: [RankEntry],
        sentiment: SentimentBucket?
    ) -> [UUID] {
        // Sort by position
        let sorted = existingEntries.sorted { $0.position < $1.position }
        
        // If we have sentiment hints, narrow the search space
        var searchSpace = sorted.map { $0.wineId }
        
        if let sentiment = sentiment, !sorted.isEmpty {
            // Use sentiment to seed initial bucket
            switch sentiment {
            case .loved:
                // Compare against top wines first
                let topHalf = sorted.prefix(max(1, sorted.count / 2))
                searchSpace = topHalf.map { $0.wineId }
            case .didntLove:
                // Compare against bottom wines first
                let bottomHalf = sorted.suffix(max(1, sorted.count / 2))
                searchSpace = bottomHalf.map { $0.wineId }
            case .okay:
                // Start from the middle
                searchSpace = sorted.map { $0.wineId }
            }
        }
        
        // Return binary search order (middle, then halves recursively)
        return binarySearchOrder(searchSpace)
    }
    
    /// Generate binary search comparison order
    private func binarySearchOrder(_ wineIds: [UUID]) -> [UUID] {
        guard !wineIds.isEmpty else { return [] }
        if wineIds.count == 1 { return wineIds }
        
        var result: [UUID] = []
        var queue: [(Int, Int)] = [(0, wineIds.count - 1)]
        
        while !queue.isEmpty {
            let (low, high) = queue.removeFirst()
            if low > high { continue }
            
            let mid = (low + high) / 2
            result.append(wineIds[mid])
            
            if low < mid {
                queue.append((low, mid - 1))
            }
            if mid < high {
                queue.append((mid + 1, high))
            }
        }
        
        return result
    }
    
    // MARK: - Process Comparison Result
    /// Process a single comparison result and return next comparison (if needed)
    func processComparison(
        in ranking: inout Ranking,
        newWineId: UUID,
        comparedToWineId: UUID,
        result: ComparisonResult,
        remainingComparisons: [UUID]
    ) -> (nextComparisonId: UUID?, insertPosition: Int?) {
        // Find the compared wine's position
        guard let comparedEntry = ranking.entry(for: comparedToWineId) else {
            return (nil, 1)  // Default to first position
        }
        
        var remaining = remainingComparisons
        
        switch result {
        case .preferFirst:  // New wine is preferred
            // New wine should be placed ABOVE the compared wine
            // Continue searching in upper half
            remaining = remaining.filter { wineId in
                guard let entry = ranking.entry(for: wineId) else { return false }
                return entry.position < comparedEntry.position
            }
            
        case .preferSecond:  // Compared wine is preferred
            // New wine should be placed BELOW the compared wine
            // Continue searching in lower half
            remaining = remaining.filter { wineId in
                guard let entry = ranking.entry(for: wineId) else { return false }
                return entry.position > comparedEntry.position
            }
            
        case .tie:
            // Place at same position as compared wine
            return (nil, comparedEntry.position)
        }
        
        // If more comparisons needed, return next
        if let next = remaining.first {
            return (next, nil)
        }
        
        // Calculate final position based on last comparison
        let position: Int
        switch result {
        case .preferFirst:
            position = comparedEntry.position
        case .preferSecond:
            position = comparedEntry.position + 1
        case .tie:
            position = comparedEntry.position
        }
        
        return (nil, position)
    }
    
    // MARK: - Insert Wine at Position
    /// Insert a wine at the given position, adjusting other entries
    func insertWine(
        in ranking: inout Ranking,
        wineId: UUID,
        atPosition position: Int,
        vintageYear: Int?,
        sentiment: SentimentBucket?,
        notes: String? = nil,
        photos: [URL] = [],
        isTie: Bool = false
    ) {
        // Shift existing entries if not a tie
        if !isTie {
            for i in 0..<ranking.entries.count {
                if ranking.entries[i].position >= position {
                    ranking.entries[i].position += 1
                }
            }
        }
        
        let tasting = VintageTasting(
            vintageYear: vintageYear,
            photoURLs: photos,
            tastingNotes: notes,
            isBestVintage: true
        )
        
        let entry = RankEntry(
            wineId: wineId,
            position: position,
            sentimentBucket: sentiment,
            bestVintageTastingId: tasting.id,
            vintageTastings: [tasting]
        )
        
        ranking.entries.append(entry)
        ranking.updatedAt = Date()
    }
    
    // MARK: - Calculate Percentile
    /// Calculate percentile for a wine in a ranking
    func percentile(position: Int, totalWines: Int) -> Double {
        guard totalWines > 1 else { return 100.0 }
        return Double(totalWines - position) / Double(totalWines - 1) * 100.0
    }
    
    // MARK: - Calculate Composite Score
    /// Calculate composite score across multiple raters
    func calculateComposite(
        wineId: UUID,
        rankings: [Ranking],
        grapeId: UUID
    ) -> CompositeScore? {
        // Filter rankings that contain this wine and grape
        let relevantRankings = rankings.filter { ranking in
            ranking.grapeId == grapeId && ranking.entry(for: wineId) != nil
        }
        
        guard relevantRankings.count >= 3 else {
            return nil  // Minimum 3 raters required
        }
        
        var totalWeight: Double = 0
        var weightedPercentileSum: Double = 0
        
        for ranking in relevantRankings {
            guard let entry = ranking.entry(for: wineId) else { continue }
            
            let totalWines = ranking.totalWines
            let pct = percentile(position: entry.position, totalWines: totalWines)
            
            // Weight = sqrt(total wines ranked in that grape)
            let weight = sqrt(Double(totalWines))
            
            totalWeight += weight
            weightedPercentileSum += pct * weight
        }
        
        guard totalWeight > 0 else { return nil }
        
        return CompositeScore(
            wineId: wineId,
            grapeId: grapeId,
            scope: .global,
            totalRaters: relevantRankings.count,
            weightedPercentile: weightedPercentileSum / totalWeight
        )
    }
    
    // MARK: - Calculate Friends Composite
    /// Calculate composite score among friends only
    func calculateFriendsComposite(
        wineId: UUID,
        grapeId: UUID,
        rankings: [Ranking],
        friendUserIds: Set<UUID>
    ) -> CompositeScore? {
        let friendRankings = rankings.filter { friendUserIds.contains($0.userId) }
        guard let composite = calculateComposite(wineId: wineId, rankings: friendRankings, grapeId: grapeId) else {
            return nil
        }
        
        return CompositeScore(
            id: UUID(),
            wineId: wineId,
            grapeId: grapeId,
            scope: .friends,
            totalRaters: composite.totalRaters,
            weightedPercentile: composite.weightedPercentile
        )
    }
}
