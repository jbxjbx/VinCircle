// MARK: - FeedEvent.swift
// FRIDAYRED - Wine Ranking App
// Feed event model for friend activity tracking

import Foundation

// MARK: - Feed Event Type
enum FeedEventType: String, Codable, CaseIterable, Sendable {
    case wineRated = "wine_rated"
    case wineReranked = "wine_reranked"
    case newVintageTried = "new_vintage_tried"
    
    var actionText: String {
        switch self {
        case .wineRated: return "ranked"
        case .wineReranked: return "re-ranked"
        case .newVintageTried: return "tried a new vintage of"
        }
    }
}

// MARK: - Feed Event Model
struct FeedEvent: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let actorUserId: UUID
    let eventType: FeedEventType
    let wineId: UUID
    let grapeId: UUID
    let vintageYear: Int?
    let rankPosition: Int
    let totalInList: Int
    let createdAt: Date
    
    init(
        id: UUID = UUID(),
        actorUserId: UUID,
        eventType: FeedEventType,
        wineId: UUID,
        grapeId: UUID,
        vintageYear: Int?,
        rankPosition: Int,
        totalInList: Int,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.actorUserId = actorUserId
        self.eventType = eventType
        self.wineId = wineId
        self.grapeId = grapeId
        self.vintageYear = vintageYear
        self.rankPosition = rankPosition
        self.totalInList = totalInList
        self.createdAt = createdAt
    }
    
    /// Display text for position: "#2 of 15"
    var positionDisplay: String {
        "#\(rankPosition) of \(totalInList)"
    }
    
    /// Vintage display or "NV"
    var vintageDisplay: String {
        if let year = vintageYear {
            return String(year)
        }
        return "NV"
    }
}

// MARK: - Composite Score (cached or calculated)
struct CompositeScore: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let wineId: UUID
    let grapeId: UUID
    let scope: CompositeScope
    var totalRaters: Int
    var weightedPercentile: Double  // 0-100
    var lastCalculatedAt: Date
    
    init(
        id: UUID = UUID(),
        wineId: UUID,
        grapeId: UUID,
        scope: CompositeScope,
        totalRaters: Int,
        weightedPercentile: Double,
        lastCalculatedAt: Date = Date()
    ) {
        self.id = id
        self.wineId = wineId
        self.grapeId = grapeId
        self.scope = scope
        self.totalRaters = totalRaters
        self.weightedPercentile = weightedPercentile
        self.lastCalculatedAt = lastCalculatedAt
    }
    
    /// Display text: "77th percentile across 5 raters"
    var displayText: String {
        let percentile = Int(weightedPercentile.rounded())
        let suffix = ordinalSuffix(for: percentile)
        return "\(percentile)\(suffix) percentile across \(totalRaters) raters"
    }
    
    private func ordinalSuffix(for number: Int) -> String {
        let tens = number % 100
        if tens >= 11 && tens <= 13 { return "th" }
        switch number % 10 {
        case 1: return "st"
        case 2: return "nd"
        case 3: return "rd"
        default: return "th"
        }
    }
}

enum CompositeScope: String, Codable, CaseIterable, Sendable {
    case global = "global"
    case friends = "friends"
}
