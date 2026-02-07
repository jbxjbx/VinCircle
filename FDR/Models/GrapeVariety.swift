// MARK: - GrapeVariety.swift
// FRIDAYRED - Wine Ranking App
// Grape variety model for categorizing rankings

import Foundation

// MARK: - Wine Color
enum WineColor: String, Codable, CaseIterable, Sendable {
    case red
    case white
    case rosé
    case orange
}

// MARK: - Grape Variety Model
struct GrapeVariety: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let name: String
    let color: WineColor
    
    init(id: UUID = UUID(), name: String, color: WineColor) {
        self.id = id
        self.name = name
        self.color = color
    }
}

// MARK: - Standard Grape Varieties (approximately 30 for launch)
extension GrapeVariety {
    static let standardVarieties: [GrapeVariety] = [
        // Red Grapes
        GrapeVariety(id: UUID(uuidString: "00000001-0000-0000-0000-000000000001")!, name: "Cabernet Sauvignon", color: .red),
        GrapeVariety(id: UUID(uuidString: "00000001-0000-0000-0000-000000000002")!, name: "Merlot", color: .red),
        GrapeVariety(id: UUID(uuidString: "00000001-0000-0000-0000-000000000003")!, name: "Pinot Noir", color: .red),
        GrapeVariety(id: UUID(uuidString: "00000001-0000-0000-0000-000000000004")!, name: "Malbec", color: .red),
        GrapeVariety(id: UUID(uuidString: "00000001-0000-0000-0000-000000000005")!, name: "Syrah/Shiraz", color: .red),
        GrapeVariety(id: UUID(uuidString: "00000001-0000-0000-0000-000000000006")!, name: "Nebbiolo", color: .red),
        GrapeVariety(id: UUID(uuidString: "00000001-0000-0000-0000-000000000007")!, name: "Sangiovese", color: .red),
        GrapeVariety(id: UUID(uuidString: "00000001-0000-0000-0000-000000000008")!, name: "Tempranillo", color: .red),
        GrapeVariety(id: UUID(uuidString: "00000001-0000-0000-0000-000000000009")!, name: "Zinfandel", color: .red),
        GrapeVariety(id: UUID(uuidString: "00000001-0000-0000-0000-00000000000A")!, name: "Grenache", color: .red),
        GrapeVariety(id: UUID(uuidString: "00000001-0000-0000-0000-00000000000B")!, name: "Mourvèdre", color: .red),
        GrapeVariety(id: UUID(uuidString: "00000001-0000-0000-0000-00000000000C")!, name: "Barbera", color: .red),
        GrapeVariety(id: UUID(uuidString: "00000001-0000-0000-0000-00000000000D")!, name: "Carménère", color: .red),
        GrapeVariety(id: UUID(uuidString: "00000001-0000-0000-0000-00000000000E")!, name: "Petite Sirah", color: .red),
        
        // White Grapes
        GrapeVariety(id: UUID(uuidString: "00000002-0000-0000-0000-000000000001")!, name: "Chardonnay", color: .white),
        GrapeVariety(id: UUID(uuidString: "00000002-0000-0000-0000-000000000002")!, name: "Sauvignon Blanc", color: .white),
        GrapeVariety(id: UUID(uuidString: "00000002-0000-0000-0000-000000000003")!, name: "Riesling", color: .white),
        GrapeVariety(id: UUID(uuidString: "00000002-0000-0000-0000-000000000004")!, name: "Pinot Grigio/Gris", color: .white),
        GrapeVariety(id: UUID(uuidString: "00000002-0000-0000-0000-000000000005")!, name: "Gewürztraminer", color: .white),
        GrapeVariety(id: UUID(uuidString: "00000002-0000-0000-0000-000000000006")!, name: "Viognier", color: .white),
        GrapeVariety(id: UUID(uuidString: "00000002-0000-0000-0000-000000000007")!, name: "Chenin Blanc", color: .white),
        GrapeVariety(id: UUID(uuidString: "00000002-0000-0000-0000-000000000008")!, name: "Grüner Veltliner", color: .white),
        GrapeVariety(id: UUID(uuidString: "00000002-0000-0000-0000-000000000009")!, name: "Albariño", color: .white),
        GrapeVariety(id: UUID(uuidString: "00000002-0000-0000-0000-00000000000A")!, name: "Moscato/Muscat", color: .white),
        GrapeVariety(id: UUID(uuidString: "00000002-0000-0000-0000-00000000000B")!, name: "Sémillon", color: .white),
        
        // Rosé & Sparkling (often blends)
        GrapeVariety(id: UUID(uuidString: "00000003-0000-0000-0000-000000000001")!, name: "Rosé Blend", color: .rosé),
        GrapeVariety(id: UUID(uuidString: "00000003-0000-0000-0000-000000000002")!, name: "Champagne Blend", color: .white),
        GrapeVariety(id: UUID(uuidString: "00000003-0000-0000-0000-000000000003")!, name: "Prosecco (Glera)", color: .white),
        
        // Other/Blend
        GrapeVariety(id: UUID(uuidString: "00000004-0000-0000-0000-000000000001")!, name: "Red Blend", color: .red),
        GrapeVariety(id: UUID(uuidString: "00000004-0000-0000-0000-000000000002")!, name: "White Blend", color: .white),
        GrapeVariety(id: UUID(uuidString: "00000004-0000-0000-0000-000000000003")!, name: "Other", color: .red)
    ]
    
    static func find(byName name: String) -> GrapeVariety? {
        standardVarieties.first { $0.name.lowercased() == name.lowercased() }
    }
}
