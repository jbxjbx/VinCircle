// MARK: - Wine.swift
// FRIDAYRED - Wine Ranking App
// Wine model representing the enduring wine product (not vintage-specific)

import Foundation

// MARK: - Wine Model
/// Represents a wine product (Producer + Wine Name + Grape + Region).
/// Rankings are at this level, not the vintage level.
struct Wine: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let name: String           // e.g., "Adrianna Vineyard"
    let producer: String       // e.g., "Catena Zapata"
    let primaryGrapeId: UUID   // FK to GrapeVariety
    let regionId: UUID         // FK to WineRegion
    let externalId: String?    // External API reference (Wine-Searcher, etc.)
    let createdByUserId: UUID? // Null if from external DB
    let createdAt: Date
    
    init(
        id: UUID = UUID(),
        name: String,
        producer: String,
        primaryGrapeId: UUID,
        regionId: UUID,
        externalId: String? = nil,
        createdByUserId: UUID? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.producer = producer
        self.primaryGrapeId = primaryGrapeId
        self.regionId = regionId
        self.externalId = externalId
        self.createdByUserId = createdByUserId
        self.createdAt = createdAt
    }
    
    /// Full display name: "Producer Wine Name"
    var fullName: String {
        "\(producer) \(name)"
    }
}

// MARK: - Wine Extensions for Lookups
extension Wine {
    /// Get the grape variety for this wine
    func grape(from varieties: [GrapeVariety] = GrapeVariety.standardVarieties) -> GrapeVariety? {
        varieties.first { $0.id == primaryGrapeId }
    }
    
    /// Get the region for this wine
    func region(from regions: [WineRegion] = WineRegion.commonRegions) -> WineRegion? {
        regions.first { $0.id == regionId }
    }
}
