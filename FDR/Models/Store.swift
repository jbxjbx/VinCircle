// MARK: - Store.swift
// VinCircle - iOS Social Wine App
// Store model with inventory and friend wine matches

import Foundation
import CoreLocation

// MARK: - Store Model

struct Store: Identifiable, Codable, Hashable, Sendable {
    let id: String              // Wine-Searcher store ID
    let name: String
    let address: String
    let city: String
    let state: String
    let zipCode: String
    let country: String
    let phoneNumber: String?
    let websiteURL: URL?
    
    // Location
    let latitude: Double
    let longitude: Double
    
    // Calculated at runtime
    var distance: Double?       // Distance from user in miles
    
    // Inventory matches with friends' wines
    var matchedWines: [StoreWineMatch]
    
    // Store metadata
    let storeType: StoreType
    let rating: Double?         // User rating if available
    let isOpen: Bool?           // Current open status
    let hours: [DayHours]?
    
    // MARK: - Computed Properties
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var hasMatchedWines: Bool {
        !matchedWines.isEmpty
    }
    
    var bestMatch: StoreWineMatch? {
        matchedWines.max(by: { $0.relevanceScore < $1.relevanceScore })
    }
    
    var formattedAddress: String {
        "\(address), \(city), \(state) \(zipCode)"
    }
    
    var formattedDistance: String? {
        guard let distance = distance else { return nil }
        if distance < 0.1 {
            return "< 0.1 mi"
        } else if distance < 10 {
            return String(format: "%.1f mi", distance)
        } else {
            return String(format: "%.0f mi", distance)
        }
    }
    
    // MARK: - Hashable
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Store, rhs: Store) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Store Wine Match

struct StoreWineMatch: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let wineId: String          // Wine-Searcher wine ID
    let wineName: String
    let vintage: Int?
    let price: Decimal
    let currency: String
    
    // Friend connection
    let friendId: UUID
    let friendName: String
    let friendPostId: UUID
    let friendRating: Int       // Their subjective score
    let friendPostDate: Date
    
    // Calculated relevance
    var relevanceScore: Double  // Higher = more relevant
    
    // MARK: - Computed Properties
    
    var formattedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: price as NSDecimalNumber) ?? "\(currency) \(price)"
    }
    
    var notificationText: String {
        "\(friendName) rated this \(friendRating)/100"
    }
    
    var detailedNotification: String {
        let timeAgo = friendPostDate.timeAgoDisplay()
        return "\(friendName) just drank \(wineName) (\(timeAgo)) and it's available here!"
    }
    
    // MARK: - Initialization
    
    nonisolated init(
        wineId: String,
        wineName: String,
        vintage: Int?,
        price: Decimal,
        currency: String = "USD",
        friendId: UUID,
        friendName: String,
        friendPostId: UUID,
        friendRating: Int,
        friendPostDate: Date
    ) {

        self.id = UUID()
        self.wineId = wineId
        self.wineName = wineName
        self.vintage = vintage
        self.price = price
        self.currency = currency
        self.friendId = friendId
        self.friendName = friendName
        self.friendPostId = friendPostId
        self.friendRating = friendRating
        self.friendPostDate = friendPostDate
        
        // Calculate relevance based on rating and recency
        let recencyDays = Date().timeIntervalSince(friendPostDate) / 86400
        let recencyFactor = max(0, 1 - (recencyDays / 30)) // 0-1, decreasing over 30 days
        let ratingFactor = Double(friendRating) / 100
        self.relevanceScore = (ratingFactor * 0.6) + (recencyFactor * 0.4)
    }
}

// MARK: - Store Type

enum StoreType: String, Codable, CaseIterable {
    case wineShop = "Wine Shop"
    case liquorStore = "Liquor Store"
    case supermarket = "Supermarket"
    case winery = "Winery"
    case online = "Online"
    case restaurant = "Restaurant"
    
    var iconName: String {
        switch self {
        case .wineShop: return "wineglass"
        case .liquorStore: return "storefront"
        case .supermarket: return "cart"
        case .winery: return "leaf"
        case .online: return "globe"
        case .restaurant: return "fork.knife"
        }
    }
}

// MARK: - Day Hours

struct DayHours: Codable, Hashable, Sendable {
    let dayOfWeek: Int          // 1 = Sunday, 7 = Saturday
    let openTime: String?       // "09:00"
    let closeTime: String?      // "21:00"
    let isClosed: Bool
    
    var displayString: String {
        if isClosed {
            return "Closed"
        }
        guard let open = openTime, let close = closeTime else {
            return "Hours unavailable"
        }
        return "\(open) - \(close)"
    }
}

// MARK: - Store Inventory Item

struct StoreInventoryItem: Identifiable, Codable, Sendable {
    let id: String
    let wineId: String
    let wineName: String
    let producer: String
    let vintage: Int?
    let price: Decimal
    let currency: String
    let inStock: Bool
    let quantity: Int?
}

// MARK: - Date Extension for Time Ago

extension Date {
    func timeAgoDisplay() -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day, .weekOfYear], from: self, to: now)
        
        if let weeks = components.weekOfYear, weeks > 0 {
            return weeks == 1 ? "1 week ago" : "\(weeks) weeks ago"
        }
        if let days = components.day, days > 0 {
            return days == 1 ? "yesterday" : "\(days) days ago"
        }
        if let hours = components.hour, hours > 0 {
            return hours == 1 ? "1 hour ago" : "\(hours) hours ago"
        }
        if let minutes = components.minute, minutes > 0 {
            return minutes == 1 ? "1 min ago" : "\(minutes) mins ago"
        }
        return "just now"
    }
}
