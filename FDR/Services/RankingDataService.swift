// MARK: - RankingDataService.swift
// FRIDAYRED - Wine Ranking App
// Mock data service for rankings, wines, and social features

import Foundation
import Combine

@MainActor
class RankingDataService: ObservableObject {
    
    static let shared = RankingDataService()
    
    // MARK: - Published Properties
    @Published var currentUser: User
    @Published var wines: [Wine] = []
    @Published var rankings: [Ranking] = []
    @Published var feedEvents: [FeedEvent] = []
    @Published var users: [User] = []
    
    // MARK: - Initialization
    private init() {
        // Initialize current user
        self.currentUser = User(
            id: UUID(uuidString: "AAAAAAAA-0000-0000-0000-000000000001")!,
            displayName: "You",
            email: "user@fridayred.com",
            uniqueCode: "FRIDAY",
            username: "winelover",
            phoneNumber: "+1234567890",
            inviteCodes: InviteCode.generateInitialCodes(for: UUID(uuidString: "AAAAAAAA-0000-0000-0000-000000000001")!)
        )
        
        // Generate mock data
        generateMockData()
    }
    
    // MARK: - Mock Data Generation
    private func generateMockData() {
        // Create sample wines
        let malbecGrapeId = UUID(uuidString: "00000001-0000-0000-0000-000000000004")!
        let pinotNoirGrapeId = UUID(uuidString: "00000001-0000-0000-0000-000000000003")!
        let chardonnayGrapeId = UUID(uuidString: "00000002-0000-0000-0000-000000000001")!
        
        let mendozaRegionId = UUID(uuidString: "10000004-0000-0000-0000-000000000001")!
        let burgundyRegionId = UUID(uuidString: "10000001-0000-0000-0000-000000000002")!
        let napaRegionId = UUID(uuidString: "10000003-0000-0000-0000-000000000001")!
        
        wines = [
            Wine(id: UUID(), name: "Adrianna Vineyard", producer: "Catena Zapata", primaryGrapeId: malbecGrapeId, regionId: mendozaRegionId),
            Wine(id: UUID(), name: "Finca Altamira", producer: "Achával-Ferrer", primaryGrapeId: malbecGrapeId, regionId: mendozaRegionId),
            Wine(id: UUID(), name: "Clos de los Siete", producer: "Michel Rolland", primaryGrapeId: malbecGrapeId, regionId: mendozaRegionId),
            Wine(id: UUID(), name: "Luján de Cuyo", producer: "Bramare", primaryGrapeId: malbecGrapeId, regionId: mendozaRegionId),
            Wine(id: UUID(), name: "Terroir Series", producer: "Trapiche", primaryGrapeId: malbecGrapeId, regionId: mendozaRegionId),
            
            Wine(id: UUID(), name: "Clos de la Roche", producer: "Domaine Dujac", primaryGrapeId: pinotNoirGrapeId, regionId: burgundyRegionId),
            Wine(id: UUID(), name: "Richebourg", producer: "Domaine Leroy", primaryGrapeId: pinotNoirGrapeId, regionId: burgundyRegionId),
            
            Wine(id: UUID(), name: "Reserve", producer: "Far Niente", primaryGrapeId: chardonnayGrapeId, regionId: napaRegionId),
            Wine(id: UUID(), name: "Hyde Vineyard", producer: "Kistler", primaryGrapeId: chardonnayGrapeId, regionId: napaRegionId)
        ]
        
        // Create mock users (friends)
        let friend1Id = UUID()
        let friend2Id = UUID()
        let friend3Id = UUID()
        
        users = [
            currentUser,
            User(id: friend1Id, displayName: "Sarah", email: "sarah@test.com", uniqueCode: "SARAH1", username: "sarahwine"),
            User(id: friend2Id, displayName: "Alex", email: "alex@test.com", uniqueCode: "ALEX11", username: "alexvino"),
            User(id: friend3Id, displayName: "James", email: "james@test.com", uniqueCode: "JAMES1", username: "jameswines")
        ]
        
        // Update current user's friends
        currentUser.friendIds = [friend1Id, friend2Id, friend3Id]
        
        // Create sample ranking for current user
        var malbecRanking = Ranking(userId: currentUser.id, grapeId: malbecGrapeId)
        let malbecWines = wines.filter { $0.primaryGrapeId == malbecGrapeId }
        
        for (index, wine) in malbecWines.prefix(3).enumerated() {
            let tasting = VintageTasting(vintageYear: 2019 + index, isBestVintage: true)
            let entry = RankEntry(
                wineId: wine.id,
                position: index + 1,
                sentimentBucket: index == 0 ? .loved : .okay,
                bestVintageTastingId: tasting.id,
                vintageTastings: [tasting]
            )
            malbecRanking.entries.append(entry)
        }
        
        rankings.append(malbecRanking)
        
        // Create sample feed events
        feedEvents = [
            FeedEvent(actorUserId: friend1Id, eventType: .wineRated, wineId: wines[0].id, grapeId: malbecGrapeId, vintageYear: 2019, rankPosition: 1, totalInList: 8),
            FeedEvent(actorUserId: friend2Id, eventType: .wineRated, wineId: wines[5].id, grapeId: pinotNoirGrapeId, vintageYear: 2018, rankPosition: 4, totalInList: 12),
            FeedEvent(actorUserId: friend3Id, eventType: .newVintageTried, wineId: wines[7].id, grapeId: chardonnayGrapeId, vintageYear: 2020, rankPosition: 2, totalInList: 6)
        ]
    }
    
    // MARK: - Ranking Methods
    
    /// Get ranking for a specific grape variety
    func ranking(for grapeId: UUID) -> Ranking? {
        rankings.first { $0.userId == currentUser.id && $0.grapeId == grapeId }
    }
    
    /// Get or create ranking for a grape variety
    func getOrCreateRanking(for grapeId: UUID) -> Ranking {
        if let existing = ranking(for: grapeId) {
            return existing
        }
        let newRanking = Ranking(userId: currentUser.id, grapeId: grapeId)
        rankings.append(newRanking)
        return newRanking
    }
    
    /// Update a ranking
    func updateRanking(_ ranking: Ranking) {
        if let index = rankings.firstIndex(where: { $0.id == ranking.id }) {
            rankings[index] = ranking
        } else {
            rankings.append(ranking)
        }
    }
    
    /// Get all grape varieties the user has ranked
    func rankedGrapes() -> [GrapeVariety] {
        let grapeIds = Set(rankings.filter { $0.userId == currentUser.id && !$0.entries.isEmpty }.map { $0.grapeId })
        return GrapeVariety.standardVarieties.filter { grapeIds.contains($0.id) }
    }
    
    // MARK: - Wine Methods
    
    /// Find wine by ID
    func wine(byId id: UUID) -> Wine? {
        wines.first { $0.id == id }
    }
    
    /// Search wines
    func searchWines(query: String) -> [Wine] {
        guard !query.isEmpty else { return wines }
        let lowercased = query.lowercased()
        return wines.filter {
            $0.name.lowercased().contains(lowercased) ||
            $0.producer.lowercased().contains(lowercased)
        }
    }
    
    /// Add a new wine
    func addWine(_ wine: Wine) {
        wines.append(wine)
    }
    
    // MARK: - User Methods
    
    /// Get user by ID
    func user(byId id: UUID) -> User? {
        users.first { $0.id == id }
    }
    
    /// Get friend list
    func friends() -> [User] {
        users.filter { currentUser.friendIds.contains($0.id) }
    }
    
    // MARK: - Feed Methods
    
    /// Get friend feed events
    func friendFeedEvents() -> [FeedEvent] {
        let friendIds = Set(currentUser.friendIds)
        return feedEvents
            .filter { friendIds.contains($0.actorUserId) }
            .sorted { $0.createdAt > $1.createdAt }
    }
    
    /// Add a feed event
    func addFeedEvent(_ event: FeedEvent) {
        feedEvents.insert(event, at: 0)
    }
    
    // MARK: - Invite Methods
    
    /// Remaining invite count
    var remainingInvites: Int {
        currentUser.inviteCodes.remainingCount
    }
    
    /// Use an invite code
    func useInviteCode(_ code: String) -> Bool {
        // In real app, this would validate and consume the code
        return true
    }
}

// MARK: - User Extensions for FRIDAYRED
extension User {
    var username: String {
        get { _username ?? displayName.lowercased().replacingOccurrences(of: " ", with: "") }
        set { _username = newValue }
    }
    
    var phoneNumber: String {
        get { _phoneNumber ?? "" }
        set { _phoneNumber = newValue }
    }
    
    var inviteCodes: [InviteCode] {
        get { _inviteCodes ?? [] }
        set { _inviteCodes = newValue }
    }
    
    private var _username: String? {
        get { nil }
        set { }
    }
    
    private var _phoneNumber: String? {
        get { nil }
        set { }
    }
    
    private var _inviteCodes: [InviteCode]? {
        get { nil }
        set { }
    }
    
    init(
        id: UUID = UUID(),
        displayName: String,
        email: String,
        uniqueCode: String,
        username: String,
        phoneNumber: String = "",
        inviteCodes: [InviteCode] = []
    ) {
        self.init(
            id: id,
            displayName: displayName,
            email: email,
            uniqueCode: uniqueCode,
            tastingCount: 0,
            friendIds: [],
            pendingFriendRequests: [],
            achievements: []
        )
    }
}
