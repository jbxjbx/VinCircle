// MARK: - Ranking.swift
// FRIDAYRED - Wine Ranking App
// User ranking model with position-based wine entries

import Foundation

// MARK: - Sentiment Bucket (for first wine in a grape variety)
enum SentimentBucket: String, Codable, CaseIterable, Sendable {
    case loved = "loved"
    case okay = "okay"
    case didntLove = "didnt_love"
    
    var displayText: String {
        switch self {
        case .loved: return "Loved it ❤️"
        case .okay: return "It was okay 👌"
        case .didntLove: return "Didn't love it 👎"
        }
    }
    
    var emoji: String {
        switch self {
        case .loved: return "❤️"
        case .okay: return "👌"
        case .didntLove: return "👎"
        }
    }
}

// MARK: - Ranking (one per user per grape variety)
struct Ranking: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let userId: UUID
    let grapeId: UUID
    var entries: [RankEntry]
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        userId: UUID,
        grapeId: UUID,
        entries: [RankEntry] = [],
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.grapeId = grapeId
        self.entries = entries
        self.updatedAt = updatedAt
    }
    
    /// Total wines in this ranking
    var totalWines: Int {
        entries.count
    }
    
    /// Get entry for a specific wine
    func entry(for wineId: UUID) -> RankEntry? {
        entries.first { $0.wineId == wineId }
    }
    
    /// Get position for a wine (nil if not ranked)
    func position(for wineId: UUID) -> Int? {
        entry(for: wineId)?.position
    }
    
    /// Sorted entries by position (best first)
    var sortedEntries: [RankEntry] {
        entries.sorted { $0.position < $1.position }
    }
}

// MARK: - RankEntry (one wine's position in a ranking)
struct RankEntry: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let wineId: UUID
    var position: Int  // 1 = best; ties share same position
    var sentimentBucket: SentimentBucket?
    var bestVintageTastingId: UUID?
    var vintageTastings: [VintageTasting]
    let createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        wineId: UUID,
        position: Int,
        sentimentBucket: SentimentBucket? = nil,
        bestVintageTastingId: UUID? = nil,
        vintageTastings: [VintageTasting] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.wineId = wineId
        self.position = position
        self.sentimentBucket = sentimentBucket
        self.bestVintageTastingId = bestVintageTastingId
        self.vintageTastings = vintageTastings
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    /// The best vintage tasting (if any)
    var bestVintage: VintageTasting? {
        if let bestId = bestVintageTastingId {
            return vintageTastings.first { $0.id == bestId }
        }
        return vintageTastings.first { $0.isBestVintage }
    }
    
    /// Best vintage year (or "NV" if unknown)
    var bestVintageDisplay: String {
        if let year = bestVintage?.vintageYear {
            return String(year)
        }
        return "NV"
    }
    
    /// Count of vintages tried
    var vintagesTried: Int {
        vintageTastings.count
    }
}

// MARK: - VintageTasting (a specific experience of a wine)
struct VintageTasting: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let vintageYear: Int?  // nil = NV or unknown
    var photoURLs: [URL]
    var tastingNotes: String?
    var isBestVintage: Bool
    let tastedAt: Date
    let createdAt: Date
    
    init(
        id: UUID = UUID(),
        vintageYear: Int?,
        photoURLs: [URL] = [],
        tastingNotes: String? = nil,
        isBestVintage: Bool = true,
        tastedAt: Date = Date(),
        createdAt: Date = Date()
    ) {
        self.id = id
        self.vintageYear = vintageYear
        self.photoURLs = photoURLs
        self.tastingNotes = tastingNotes
        self.isBestVintage = isBestVintage
        self.tastedAt = tastedAt
        self.createdAt = createdAt
    }
    
    /// Display string for vintage
    var vintageDisplay: String {
        if let year = vintageYear {
            return String(year)
        }
        return "NV"
    }
}
