// MARK: - WinePost.swift
// VinCircle - iOS Social Wine App
// Structured wine posting model with attributes and comparison data

import Foundation

// MARK: - WinePost Model

struct WinePost: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let authorId: UUID
    
    // Wine identification (from API search)
    let wineId: String           // Wine-Searcher API ID
    let wineName: String         // Official name
    let producer: String         // Winery/Producer
    let region: String           // Geographic region
    let country: String          // Country of origin
    let vintage: Int             // Year
    let varietal: String         // Grape variety (e.g., Cabernet Sauvignon)
    let wineType: WineType       // Red, White, Rosé, etc.
    
    // User-provided structured data (NO free-text headers)
    let attributes: WineAttributes
    let subjectiveScore: Int     // 1-100 scale
    
    // Media
    let imageURLs: [URL]
    let thumbnailURL: URL?
    
    // Pairwise comparison data for Elo
    var comparisonWineId: UUID?  // The wine user compared against
    var preferredOverComparison: Bool?
    
    // Metadata
    let createdAt: Date
    var updatedAt: Date?
    var likeCount: Int
    var commentCount: Int
    
    // Location context (optional)
    var purchaseLocation: String?
    var purchasePrice: Decimal?
    var currency: String?
    
    // MARK: - Initialization
    
    init(
        id: UUID = UUID(),
        authorId: UUID,
        wineId: String,
        wineName: String,
        producer: String,
        region: String,
        country: String,
        vintage: Int,
        varietal: String,
        wineType: WineType,
        attributes: WineAttributes,
        subjectiveScore: Int,
        imageURLs: [URL] = [],
        thumbnailURL: URL? = nil
    ) {
        self.id = id
        self.authorId = authorId
        self.wineId = wineId
        self.wineName = wineName
        self.producer = producer
        self.region = region
        self.country = country
        self.vintage = vintage
        self.varietal = varietal
        self.wineType = wineType
        self.attributes = attributes
        self.subjectiveScore = min(100, max(1, subjectiveScore))
        self.imageURLs = imageURLs
        self.thumbnailURL = thumbnailURL
        self.createdAt = Date()
        self.likeCount = 0
        self.commentCount = 0
    }
}

// MARK: - Wine Type

enum WineType: String, Codable, CaseIterable {
    case red = "Red"
    case white = "White"
    case rosé = "Rosé"
    case sparkling = "Sparkling"
    case dessert = "Dessert"
    case fortified = "Fortified"
    case orange = "Orange"
    
    var iconName: String {
        switch self {
        case .red: return "drop.fill"
        case .white: return "drop"
        case .rosé: return "drop.halffull"
        case .sparkling: return "bubble.left.and.bubble.right.fill"
        case .dessert: return "birthday.cake.fill"
        case .fortified: return "shield.fill"
        case .orange: return "circle.fill"
        }
    }
    
    var color: String {
        switch self {
        case .red: return "#722F37"
        case .white: return "#F7E7CE"
        case .rosé: return "#FFB6C1"
        case .sparkling: return "#FFD700"
        case .dessert: return "#DAA520"
        case .fortified: return "#8B4513"
        case .orange: return "#FFA500"
        }
    }
}

// MARK: - Wine Attributes (Sliders/Checkboxes)

struct WineAttributes: Codable, Hashable, Sendable {
    /// 0.0 - 1.0 scale for each attribute
    var acidity: Double       // Low to High
    var sweetness: Double     // Dry to Sweet
    var tannin: Double        // Low to High (for reds)
    var body: Double          // Light to Full
    var alcohol: Double       // Light to Heavy
    
    // Aroma/Flavor checkboxes
    var flavorNotes: [FlavorNote]
    
    // Optional detailed notes
    var finish: FinishLength?
    var oakInfluence: OakLevel?
    
    init(
        acidity: Double = 0.5,
        sweetness: Double = 0.2,
        tannin: Double = 0.5,
        body: Double = 0.5,
        alcohol: Double = 0.5,
        flavorNotes: [FlavorNote] = [],
        finish: FinishLength? = nil,
        oakInfluence: OakLevel? = nil
    ) {
        self.acidity = acidity
        self.sweetness = sweetness
        self.tannin = tannin
        self.body = body
        self.alcohol = alcohol
        self.flavorNotes = flavorNotes
        self.finish = finish
        self.oakInfluence = oakInfluence
    }
}

// MARK: - Flavor Notes

enum FlavorNote: String, Codable, CaseIterable {
    // Fruits
    case cherry, blackberry, raspberry, strawberry
    case apple, pear, peach, apricot
    case citrus, lemon, lime, grapefruit
    case tropical, mango, pineapple
    
    // Earth & Minerals
    case earthy, mineral, slate, flint
    
    // Spice
    case pepper, vanilla, cinnamon, clove
    
    // Other
    case oak, smoke, tobacco, leather
    case floral, rose, violet, honeysuckle
    case herbal, mint, eucalyptus
    case butter, cream, toast
    
    var category: FlavorCategory {
        switch self {
        case .cherry, .blackberry, .raspberry, .strawberry,
             .apple, .pear, .peach, .apricot,
             .citrus, .lemon, .lime, .grapefruit,
             .tropical, .mango, .pineapple:
            return .fruit
        case .earthy, .mineral, .slate, .flint:
            return .earthMineral
        case .pepper, .vanilla, .cinnamon, .clove:
            return .spice
        case .oak, .smoke, .tobacco, .leather:
            return .oakSmoke
        case .floral, .rose, .violet, .honeysuckle:
            return .floral
        case .herbal, .mint, .eucalyptus:
            return .herbal
        case .butter, .cream, .toast:
            return .dairy
        }
    }
}

enum FlavorCategory: String, Codable, CaseIterable {
    case fruit = "Fruit"
    case earthMineral = "Earth & Mineral"
    case spice = "Spice"
    case oakSmoke = "Oak & Smoke"
    case floral = "Floral"
    case herbal = "Herbal"
    case dairy = "Dairy & Bread"
}

enum FinishLength: String, Codable, CaseIterable {
    case short = "Short"
    case medium = "Medium"
    case long = "Long"
    case veryLong = "Very Long"
}

enum OakLevel: String, Codable, CaseIterable {
    case none = "None"
    case light = "Light"
    case medium = "Medium"
    case heavy = "Heavy"
}

// MARK: - Elo Rating Model

struct EloRating: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let winePostId: UUID
    var rating: Double          // Elo score
    var comparisonCount: Int    // Number of comparisons
    var wins: Int
    var losses: Int
    
    init(winePostId: UUID, initialRating: Double = 1000) {
        self.id = UUID()
        self.winePostId = winePostId
        self.rating = initialRating
        self.comparisonCount = 0
        self.wins = 0
        self.losses = 0
    }
    
    var winRate: Double {
        guard comparisonCount > 0 else { return 0 }
        return Double(wins) / Double(comparisonCount)
    }
}

// MARK: - Wine Search Result (from API)

struct WineSearchResult: Identifiable, Codable, Hashable, Sendable {
    let id: String              // API wine ID
    let name: String
    let producer: String
    let region: String
    let country: String
    let varietal: String
    let type: WineType
    let vintages: [Int]         // Available vintages
    let averagePrice: Decimal?
    let criticScore: Int?       // Professional critic score
    let imageURL: URL?
}
