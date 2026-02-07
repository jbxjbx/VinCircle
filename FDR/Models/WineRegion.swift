// MARK: - WineRegion.swift
// FRIDAYRED - Wine Ranking App
// Wine region model with geographic data for maps

import Foundation
import CoreLocation

// MARK: - Wine Region Model
struct WineRegion: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let name: String
    let country: String
    let parentRegionId: UUID?
    let latitude: Double
    let longitude: Double
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    init(
        id: UUID = UUID(),
        name: String,
        country: String,
        parentRegionId: UUID? = nil,
        latitude: Double,
        longitude: Double
    ) {
        self.id = id
        self.name = name
        self.country = country
        self.parentRegionId = parentRegionId
        self.latitude = latitude
        self.longitude = longitude
    }
}

// MARK: - Common Wine Regions
extension WineRegion {
    static let commonRegions: [WineRegion] = [
        // France
        WineRegion(id: UUID(uuidString: "10000001-0000-0000-0000-000000000001")!, name: "Bordeaux", country: "France", latitude: 44.8378, longitude: -0.5792),
        WineRegion(id: UUID(uuidString: "10000001-0000-0000-0000-000000000002")!, name: "Burgundy", country: "France", latitude: 47.0525, longitude: 4.3837),
        WineRegion(id: UUID(uuidString: "10000001-0000-0000-0000-000000000003")!, name: "Champagne", country: "France", latitude: 49.0423, longitude: 4.0220),
        WineRegion(id: UUID(uuidString: "10000001-0000-0000-0000-000000000004")!, name: "Rhône Valley", country: "France", latitude: 44.0833, longitude: 4.8167),
        WineRegion(id: UUID(uuidString: "10000001-0000-0000-0000-000000000005")!, name: "Loire Valley", country: "France", latitude: 47.3814, longitude: 0.6892),
        WineRegion(id: UUID(uuidString: "10000001-0000-0000-0000-000000000006")!, name: "Provence", country: "France", latitude: 43.5283, longitude: 5.4497),
        
        // Italy
        WineRegion(id: UUID(uuidString: "10000002-0000-0000-0000-000000000001")!, name: "Tuscany", country: "Italy", latitude: 43.7711, longitude: 11.2486),
        WineRegion(id: UUID(uuidString: "10000002-0000-0000-0000-000000000002")!, name: "Piedmont", country: "Italy", latitude: 44.6947, longitude: 8.0353),
        WineRegion(id: UUID(uuidString: "10000002-0000-0000-0000-000000000003")!, name: "Veneto", country: "Italy", latitude: 45.4419, longitude: 11.0020),
        WineRegion(id: UUID(uuidString: "10000002-0000-0000-0000-000000000004")!, name: "Sicily", country: "Italy", latitude: 37.5994, longitude: 14.0154),
        
        // USA
        WineRegion(id: UUID(uuidString: "10000003-0000-0000-0000-000000000001")!, name: "Napa Valley", country: "USA", latitude: 38.5025, longitude: -122.2654),
        WineRegion(id: UUID(uuidString: "10000003-0000-0000-0000-000000000002")!, name: "Sonoma", country: "USA", latitude: 38.5110, longitude: -122.8473),
        WineRegion(id: UUID(uuidString: "10000003-0000-0000-0000-000000000003")!, name: "Willamette Valley", country: "USA", latitude: 45.0500, longitude: -123.0586),
        WineRegion(id: UUID(uuidString: "10000003-0000-0000-0000-000000000004")!, name: "Paso Robles", country: "USA", latitude: 35.6264, longitude: -120.6910),
        
        // Argentina
        WineRegion(id: UUID(uuidString: "10000004-0000-0000-0000-000000000001")!, name: "Mendoza", country: "Argentina", latitude: -32.8908, longitude: -68.8272),
        WineRegion(id: UUID(uuidString: "10000004-0000-0000-0000-000000000002")!, name: "Salta", country: "Argentina", latitude: -24.7821, longitude: -65.4232),
        
        // Spain
        WineRegion(id: UUID(uuidString: "10000005-0000-0000-0000-000000000001")!, name: "Rioja", country: "Spain", latitude: 42.4627, longitude: -2.4449),
        WineRegion(id: UUID(uuidString: "10000005-0000-0000-0000-000000000002")!, name: "Ribera del Duero", country: "Spain", latitude: 41.6561, longitude: -3.7046),
        WineRegion(id: UUID(uuidString: "10000005-0000-0000-0000-000000000003")!, name: "Priorat", country: "Spain", latitude: 41.2097, longitude: 0.7556),
        
        // Australia
        WineRegion(id: UUID(uuidString: "10000006-0000-0000-0000-000000000001")!, name: "Barossa Valley", country: "Australia", latitude: -34.5330, longitude: 138.9500),
        WineRegion(id: UUID(uuidString: "10000006-0000-0000-0000-000000000002")!, name: "Margaret River", country: "Australia", latitude: -33.9536, longitude: 115.0753),
        
        // New Zealand
        WineRegion(id: UUID(uuidString: "10000007-0000-0000-0000-000000000001")!, name: "Marlborough", country: "New Zealand", latitude: -41.5134, longitude: 173.9612),
        WineRegion(id: UUID(uuidString: "10000007-0000-0000-0000-000000000002")!, name: "Central Otago", country: "New Zealand", latitude: -45.0312, longitude: 169.1280),
        
        // Chile
        WineRegion(id: UUID(uuidString: "10000008-0000-0000-0000-000000000001")!, name: "Maipo Valley", country: "Chile", latitude: -33.7500, longitude: -70.6667),
        WineRegion(id: UUID(uuidString: "10000008-0000-0000-0000-000000000002")!, name: "Colchagua Valley", country: "Chile", latitude: -34.4167, longitude: -71.2167),
        
        // South Africa
        WineRegion(id: UUID(uuidString: "10000009-0000-0000-0000-000000000001")!, name: "Stellenbosch", country: "South Africa", latitude: -33.9346, longitude: 18.8602),
        
        // Portugal
        WineRegion(id: UUID(uuidString: "1000000A-0000-0000-0000-000000000001")!, name: "Douro Valley", country: "Portugal", latitude: 41.1579, longitude: -7.8006),
        
        // Germany
        WineRegion(id: UUID(uuidString: "1000000B-0000-0000-0000-000000000001")!, name: "Mosel", country: "Germany", latitude: 49.9667, longitude: 7.1167)
    ]
    
    static func find(byName name: String) -> WineRegion? {
        commonRegions.first { $0.name.lowercased() == name.lowercased() }
    }
}
