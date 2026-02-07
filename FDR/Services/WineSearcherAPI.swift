// MARK: - WineSearcherAPI.swift
// VinCircle - iOS Social Wine App
// API Service Layer for Wine-Searcher integration and inventory cross-referencing

import Foundation
import CoreLocation
import MapKit

// MARK: - Wine Searcher API Client

@MainActor
final class WineSearcherAPI {
    
    // MARK: - Configuration
    
    private let baseURL = "https://api.wine-searcher.com/v1"
    private let apiKey: String
    private let urlSession: URLSession
    
    private let jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
    
    // MARK: - Initialization
    
    init(apiKey: String) {
        self.apiKey = apiKey
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.urlSession = URLSession(configuration: config)
    }
    
    // MARK: - Wine Search
    
    /// Search for wines by name, producer, or region
    func searchWines(
        query: String,
        type: WineType? = nil,
        country: String? = nil,
        region: String? = nil,
        minPrice: Decimal? = nil,
        maxPrice: Decimal? = nil,
        limit: Int = 20
    ) async throws -> [WineSearchResult] {
        var components = URLComponents(string: "\(baseURL)/search")!
        
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        
        if let type = type {
            queryItems.append(URLQueryItem(name: "wine_type", value: type.rawValue))
        }
        if let country = country {
            queryItems.append(URLQueryItem(name: "country", value: country))
        }
        if let region = region {
            queryItems.append(URLQueryItem(name: "region", value: region))
        }
        if let minPrice = minPrice {
            queryItems.append(URLQueryItem(name: "min_price", value: "\(minPrice)"))
        }
        if let maxPrice = maxPrice {
            queryItems.append(URLQueryItem(name: "max_price", value: "\(maxPrice)"))
        }
        
        components.queryItems = queryItems
        
        let request = URLRequest(url: components.url!)
        let (data, response) = try await urlSession.data(for: request)
        
        try validateResponse(response)
        
        let apiResponse = try jsonDecoder.decode(WineSearchAPIResponse.self, from: data)
        return apiResponse.wines
    }
    
    /// Get wine details by ID including available vintages
    func getWineDetails(wineId: String) async throws -> WineSearchResult {
        let url = URL(string: "\(baseURL)/wine/\(wineId)?api_key=\(apiKey)")!
        let request = URLRequest(url: url)
        
        let (data, response) = try await urlSession.data(for: request)
        try validateResponse(response)
        
        return try jsonDecoder.decode(WineSearchResult.self, from: data)
    }
    
    // MARK: - Store Inventory
    
    /// Fetch nearby stores with inventory
    func getStoreInventory(
        location: CLLocationCoordinate2D,
        radiusMiles: Double = 25,
        wineIds: [String]? = nil
    ) async throws -> [Store] {
        var components = URLComponents(string: "\(baseURL)/stores")!
        
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "lat", value: String(location.latitude)),
            URLQueryItem(name: "lng", value: String(location.longitude)),
            URLQueryItem(name: "radius", value: String(radiusMiles))
        ]
        
        if let wineIds = wineIds, !wineIds.isEmpty {
            queryItems.append(URLQueryItem(name: "wine_ids", value: wineIds.joined(separator: ",")))
        }
        
        components.queryItems = queryItems
        
        let request = URLRequest(url: components.url!)
        let (data, response) = try await urlSession.data(for: request)
        
        try validateResponse(response)
        
        let apiResponse = try jsonDecoder.decode(StoreAPIResponse.self, from: data)
        
        // Calculate distances from user location
        return apiResponse.stores.map { store in
            var storeWithDistance = store
            let storeLocation = CLLocation(latitude: store.latitude, longitude: store.longitude)
            let userLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
            storeWithDistance.distance = storeLocation.distance(from: userLocation) / 1609.34 // meters to miles
            return storeWithDistance
        }
    }
    
    /// Fetch stores by ZIP code
    func getStoresByZipCode(
        zipCode: String,
        radiusMiles: Double = 25
    ) async throws -> [Store] {
        // First, geocode the ZIP code to coordinates
        let coordinates = try await geocodeZipCode(zipCode)
        return try await getStoreInventory(location: coordinates, radiusMiles: radiusMiles)
    }
    
    // MARK: - Cross-Reference Logic
    
    /// Cross-reference store inventory with friends' recent posts
    /// This is the core "Smart Recommendation Logic" from requirements
    func crossReference(
        stores: [Store],
        friendPosts: [WinePost],
        recencyDays: Int = 30
    ) async throws -> [Store] {
        // Filter posts to recent ones only
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -recencyDays, to: Date())!
        let recentPosts = friendPosts.filter { $0.createdAt >= cutoffDate }
        
        // Create a lookup dictionary for quick wine ID matching
        let postsByWineId = Dictionary(grouping: recentPosts) { $0.wineId }
        
        // Process each store concurrently
        return await withTaskGroup(of: Store.self) { group in
            for store in stores {
                group.addTask {
                    var updatedStore = store
                    var matches: [StoreWineMatch] = []
                    
                    // For each store, we need to check its inventory
                    // This would typically involve another API call or cached data
                    // For now, we'll match based on the store's existing matchedWines
                    
                    // Find matches between store inventory and friends' posts
                    // In production, this would cross-reference actual inventory data
                    for (wineId, posts) in postsByWineId {
                        // Check if store has this wine (simulated - in production would check inventory)
                        // For now, we'll create matches based on high-rated posts
                        for post in posts where post.subjectiveScore >= 75 {
                            let match = StoreWineMatch(
                                wineId: wineId,
                                wineName: post.wineName,
                                vintage: post.vintage,
                                price: post.purchasePrice ?? Decimal(50), // Default price
                                currency: post.currency ?? "USD",
                                friendId: post.authorId,
                                friendName: "", // Would be populated from user lookup
                                friendPostId: post.id,
                                friendRating: post.subjectiveScore,
                                friendPostDate: post.createdAt
                            )
                            matches.append(match)
                        }
                    }
                    
                    updatedStore.matchedWines = matches.sorted { $0.relevanceScore > $1.relevanceScore }
                    return updatedStore
                }
            }
            
            var result: [Store] = []
            for await store in group {
                result.append(store)
            }
            
            // Sort by match quality first, then distance
            return result.sorted { store1, store2 in
                let score1 = store1.bestMatch?.relevanceScore ?? 0
                let score2 = store2.bestMatch?.relevanceScore ?? 0
                
                if score1 != score2 {
                    return score1 > score2
                }
                return (store1.distance ?? .infinity) < (store2.distance ?? .infinity)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return
        case 401:
            throw APIError.unauthorized
        case 404:
            throw APIError.notFound
        case 429:
            throw APIError.rateLimited
        case 500...599:
            throw APIError.serverError(httpResponse.statusCode)
        default:
            throw APIError.unknown(httpResponse.statusCode)
        }
    }
    
    private func geocodeZipCode(_ zipCode: String) async throws -> CLLocationCoordinate2D {
        // Use MapKit local search for ZIP code lookup
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = zipCode
        let search = MKLocalSearch(request: request)
        
        do {
            let response = try await search.start()
            // Use boundingRegion.center to avoid deprecated 'placemark' property usage
            return response.boundingRegion.center
        } catch {
            throw APIError.geocodingFailed
        }
    }
}

// MARK: - API Response Models

private struct WineSearchAPIResponse: Codable {
    let wines: [WineSearchResult]
    let totalResults: Int
    let page: Int
    let pageSize: Int
}

private struct StoreAPIResponse: Codable {
    let stores: [Store]
    let totalResults: Int
}

// MARK: - API Errors

enum APIError: Error, LocalizedError {
    case invalidResponse
    case unauthorized
    case notFound
    case rateLimited
    case serverError(Int)
    case geocodingFailed
    case networkError(Error)
    case decodingError(Error)
    case unknown(Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid server response"
        case .unauthorized:
            return "API key is invalid or expired"
        case .notFound:
            return "Resource not found"
        case .rateLimited:
            return "Too many requests. Please try again later."
        case .serverError(let code):
            return "Server error (\(code))"
        case .geocodingFailed:
            return "Could not find location for ZIP code"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Data error: \(error.localizedDescription)"
        case .unknown(let code):
            return "Unknown error (\(code))"
        }
    }
}

// MARK: - Mock Data for Development

extension WineSearcherAPI {
    
    static func mockWineResults() -> [WineSearchResult] {
        [
            WineSearchResult(
                id: "wine_001",
                name: "Opus One 2019",
                producer: "Opus One Winery",
                region: "Napa Valley",
                country: "USA",
                varietal: "Cabernet Sauvignon Blend",
                type: .red,
                vintages: [2019, 2018, 2017, 2016],
                averagePrice: 400,
                criticScore: 97,
                imageURL: URL(string: "https://example.com/opus-one.jpg")
            ),
            WineSearchResult(
                id: "wine_002",
                name: "Caymus Cabernet Sauvignon 2020",
                producer: "Caymus Vineyards",
                region: "Napa Valley",
                country: "USA",
                varietal: "Cabernet Sauvignon",
                type: .red,
                vintages: [2020, 2019, 2018],
                averagePrice: 90,
                criticScore: 92,
                imageURL: URL(string: "https://example.com/caymus.jpg")
            ),
            WineSearchResult(
                id: "wine_003",
                name: "Cloudy Bay Sauvignon Blanc 2022",
                producer: "Cloudy Bay",
                region: "Marlborough",
                country: "New Zealand",
                varietal: "Sauvignon Blanc",
                type: .white,
                vintages: [2022, 2021, 2020],
                averagePrice: 28,
                criticScore: 90,
                imageURL: URL(string: "https://example.com/cloudy-bay.jpg")
            )
        ]
    }
    
    static func mockStores(near location: CLLocationCoordinate2D) -> [Store] {
        [
            Store(
                id: "store_001",
                name: "Wine & Spirits Emporium",
                address: "123 Main Street",
                city: "San Francisco",
                state: "CA",
                zipCode: "94102",
                country: "USA",
                phoneNumber: "(415) 555-0101",
                websiteURL: URL(string: "https://wineemporium.example.com"),
                latitude: location.latitude + 0.01,
                longitude: location.longitude + 0.005,
                distance: 0.8,
                matchedWines: [],
                storeType: .wineShop,
                rating: 4.7,
                isOpen: true,
                hours: nil
            ),
            Store(
                id: "store_002",
                name: "Total Wine & More",
                address: "456 Market Street",
                city: "San Francisco",
                state: "CA",
                zipCode: "94103",
                country: "USA",
                phoneNumber: "(415) 555-0202",
                websiteURL: URL(string: "https://totalwine.com"),
                latitude: location.latitude - 0.015,
                longitude: location.longitude + 0.01,
                distance: 1.2,
                matchedWines: [],
                storeType: .liquorStore,
                rating: 4.5,
                isOpen: true,
                hours: nil
            )
        ]
    }
}
