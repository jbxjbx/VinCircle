// MARK: - MockDataService.swift
// VinCircle - iOS Social Wine App
// Provides mock data for development and demo purposes

import Foundation
import CoreLocation
import Combine

// MARK: - Mock Data Service

@MainActor
class MockDataService: ObservableObject {
    
    static let shared = MockDataService()
    
    // MARK: - Published Properties
    
    @Published var currentUser: User
    @Published var friends: [User]
    @Published var posts: [WinePost]
    @Published var eloRatings: [UUID: [EloRating]]  // userId -> their ratings
    @Published var comments: [UUID: [Comment]] = [:] // postId -> comments
    
    // MARK: - Post Management
    
    func deletePost(id: UUID) {
        posts.removeAll { $0.id == id }
    }
    
    func addComment(postId: UUID, text: String, authorId: UUID) {
        let authorName = getAuthorName(for: authorId)
        let comment = Comment(postId: postId, authorId: authorId, authorName: authorName, text: text)
        
        var postComments = comments[postId] ?? []
        postComments.append(comment)
        comments[postId] = postComments
        
        // Update comment count on post
        if let index = posts.firstIndex(where: { $0.id == postId }) {
            var post = posts[index]
            post.commentCount += 1
            posts[index] = post
        }
    }
    
    func getComments(for postId: UUID) -> [Comment] {
        comments[postId]?.sorted { $0.createdAt < $1.createdAt } ?? []
    }
    
    func isTier1Friend(userId: UUID) -> Bool {
        currentUser.friendIds.contains(userId) || userId == currentUser.id
    }
    
    // MARK: - Initialization
    
    private init() {
        // Create current user
        let user = User(
            id: UUID(),
            displayName: "John Sommelier",
            email: "john@example.com",
            profileImageURL: nil,
            authProvider: .apple
        )
        
        // Generate mock friends
        let friends = MockDataService.generateMockFriends()
        
        // Generate posts for each friend
        let posts = MockDataService.generateMockPosts(for: friends)
        
        // Generate Elo ratings
        let eloRatings = MockDataService.generateEloRatings(for: posts, friends: friends)
        
        // Assign to properties
        self.currentUser = user
        self.friends = friends
        self.posts = posts
        self.eloRatings = eloRatings
    }
    
    // MARK: - Mock Friend Generation
    
    private static func generateMockFriends() -> [User] {
        let friendData: [(name: String, initials: String, tastings: Int)] = [
            ("Emma Martinez", "EM", 89),
            ("Alex Chen", "AC", 156),
            ("Sophie Williams", "SW", 42),
            ("Marcus Johnson", "MJ", 234),
            ("Isabella Romano", "IR", 67),
            ("David Kim", "DK", 103)
        ]
        
        return friendData.enumerated().map { index, data in
            var user = User(
                id: UUID(),
                displayName: data.name,
                email: "\(data.name.lowercased().replacingOccurrences(of: " ", with: "."))@email.com",
                profileImageURL: nil,
                authProvider: .apple
            )
            user.tastingCount = data.tastings
            user.createdAt = Calendar.current.date(byAdding: .month, value: -(index + 3), to: Date())!
            return user
        }
    }
    
    // MARK: - Mock Post Generation
    
    private static func generateMockPosts(for friends: [User]) -> [WinePost] {
        let wineData: [(name: String, producer: String, region: String, country: String, vintage: Int, varietal: String, type: WineType, score: Int)] = [
            // Emma's wines
            ("Opus One", "Opus One Winery", "Napa Valley", "USA", 2019, "Cabernet Blend", .red, 95),
            ("Cloudy Bay Sauvignon Blanc", "Cloudy Bay", "Marlborough", "New Zealand", 2022, "Sauvignon Blanc", .white, 88),
            ("Dom Pérignon", "Moët & Chandon", "Champagne", "France", 2012, "Chardonnay/Pinot Noir", .sparkling, 97),
            
            // Alex's wines
            ("Caymus Cabernet Sauvignon", "Caymus Vineyards", "Napa Valley", "USA", 2020, "Cabernet Sauvignon", .red, 91),
            ("Château Margaux", "Château Margaux", "Margaux", "France", 2015, "Cabernet Blend", .red, 98),
            ("Whispering Angel", "Caves d'Esclans", "Provence", "France", 2023, "Grenache/Cinsault", .rosé, 85),
            
            // Sophie's wines
            ("Silver Oak Alexander Valley", "Silver Oak", "Alexander Valley", "USA", 2018, "Cabernet Sauvignon", .red, 92),
            ("Rombauer Chardonnay", "Rombauer Vineyards", "Carneros", "USA", 2021, "Chardonnay", .white, 87),
            ("Veuve Clicquot Yellow Label", "Veuve Clicquot", "Champagne", "France", 0, "Champagne Blend", .sparkling, 89),
            
            // Marcus's wines  
            ("Penfolds Grange", "Penfolds", "South Australia", "Australia", 2017, "Shiraz", .red, 96),
            ("Sassicaia", "Tenuta San Guido", "Bolgheri", "Italy", 2018, "Cabernet Blend", .red, 94),
            ("Cloudy Bay Te Koko", "Cloudy Bay", "Marlborough", "New Zealand", 2019, "Sauvignon Blanc", .white, 90),
            
            // Isabella's wines
            ("Tignanello", "Antinori", "Tuscany", "Italy", 2019, "Sangiovese Blend", .red, 93),
            ("Gaja Barbaresco", "Gaja", "Piedmont", "Italy", 2016, "Nebbiolo", .red, 95),
            ("Planeta Chardonnay", "Planeta", "Sicily", "Italy", 2020, "Chardonnay", .white, 86),
            
            // David's wines
            ("Screaming Eagle", "Screaming Eagle", "Napa Valley", "USA", 2019, "Cabernet Sauvignon", .red, 99),
            ("Krug Grande Cuvée", "Krug", "Champagne", "France", 0, "Champagne Blend", .sparkling, 96),
            ("Domaine de la Romanée-Conti", "DRC", "Burgundy", "France", 2018, "Pinot Noir", .red, 98)
        ]
        
        var posts: [WinePost] = []
        
        for (friendIndex, friend) in friends.enumerated() {
            let startIndex = friendIndex * 3
            let endIndex = min(startIndex + 3, wineData.count)
            
            for wineIndex in startIndex..<endIndex {
                let wine = wineData[wineIndex]
                let daysAgo = Int.random(in: 1...30)
                let hoursAgo = Int.random(in: 0...23)
                
                let postDate = Calendar.current.date(
                    byAdding: .hour,
                    value: -hoursAgo,
                    to: Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!
                )!
                
                let attributes = WineAttributes(
                    acidity: Double.random(in: 0.3...0.9),
                    sweetness: wine.type == .dessert ? Double.random(in: 0.6...1.0) : Double.random(in: 0.1...0.4),
                    tannin: wine.type == .red ? Double.random(in: 0.4...0.9) : Double.random(in: 0.0...0.2),
                    body: Double.random(in: 0.4...0.9),
                    alcohol: Double.random(in: 0.4...0.8),
                    flavorNotes: randomFlavorNotes(for: wine.type),
                    finish: FinishLength.allCases.randomElement(),
                    oakInfluence: OakLevel.allCases.randomElement()
                )
                
                var post = WinePost(
                    authorId: friend.id,
                    wineId: "wine_\(wineIndex)",
                    wineName: wine.name,
                    producer: wine.producer,
                    region: wine.region,
                    country: wine.country,
                    vintage: wine.vintage == 0 ? 2020 : wine.vintage,
                    varietal: wine.varietal,
                    wineType: wine.type,
                    attributes: attributes,
                    subjectiveScore: wine.score,
                    imageURLs: []
                )
                
                // Manually set the createdAt by recreating with modified date
                post = WinePost(
                    id: post.id,
                    authorId: friend.id,
                    wineId: post.wineId,
                    wineName: post.wineName,
                    producer: post.producer,
                    region: post.region,
                    country: post.country,
                    vintage: post.vintage,
                    varietal: post.varietal,
                    wineType: post.wineType,
                    attributes: attributes,
                    subjectiveScore: post.subjectiveScore,
                    imageURLs: post.imageURLs,
                    thumbnailURL: nil,
                    createdAt: postDate,
                    likeCount: Int.random(in: 2...25),
                    commentCount: Int.random(in: 0...8)
                )
                
                posts.append(post)
            }
        }
        
        return posts.sorted { $0.createdAt > $1.createdAt }
    }
    
    private static func randomFlavorNotes(for type: WineType) -> [FlavorNote] {
        let redNotes: [FlavorNote] = [.cherry, .blackberry, .vanilla, .pepper, .oak, .tobacco]
        let whiteNotes: [FlavorNote] = [.citrus, .apple, .pear, .butter, .floral, .mineral]
        let roseNotes: [FlavorNote] = [.strawberry, .cherry, .floral, .citrus]
        let sparklingNotes: [FlavorNote] = [.citrus, .apple, .toast, .cream]
        
        let notes: [FlavorNote]
        switch type {
        case .red: notes = redNotes
        case .white: notes = whiteNotes
        case .rosé: notes = roseNotes
        case .sparkling: notes = sparklingNotes
        default: notes = redNotes
        }
        
        let count = Int.random(in: 2...4)
        return Array(notes.shuffled().prefix(count))
    }
    
    // MARK: - Elo Rating Generation
    
    private static func generateEloRatings(for posts: [WinePost], friends: [User]) -> [UUID: [EloRating]] {
        var ratingsDict: [UUID: [EloRating]] = [:]
        
        for friend in friends {
            let friendPosts = posts.filter { $0.authorId == friend.id }
            var ratings: [EloRating] = []
            
            for post in friendPosts {
                var rating = EloRating(winePostId: post.id, initialRating: 1000)
                // Adjust rating based on score
                let adjustment = Double(post.subjectiveScore - 85) * 15
                rating.rating = 1000 + adjustment + Double.random(in: -50...50)
                rating.comparisonCount = Int.random(in: 3...15)
                rating.wins = Int.random(in: 1...rating.comparisonCount)
                rating.losses = rating.comparisonCount - rating.wins
                ratings.append(rating)
            }
            
            ratingsDict[friend.id] = ratings.sorted { $0.rating > $1.rating }
        }
        
        return ratingsDict
    }
    
    // MARK: - Helper Methods
    
    func getFriendPosts(for userId: UUID) -> [WinePost] {
        posts.filter { $0.authorId == userId }.sorted { $0.createdAt > $1.createdAt }
    }
    
    func getLeaderboard(for userId: UUID) -> [LeaderboardEntry] {
        guard let ratings = eloRatings[userId] else { return [] }
        
        return ratings.enumerated().compactMap { index, rating in
            guard let post = posts.first(where: { $0.id == rating.winePostId }) else { return nil }
            return LeaderboardEntry(
                rank: index + 1,
                winePost: post,
                eloRating: rating,
                previousRank: nil
            )
        }
    }
    
    func getFriend(by id: UUID) -> User? {
        friends.first { $0.id == id }
    }
    
    func getAuthorName(for authorId: UUID) -> String {
        if authorId == currentUser.id {
            return currentUser.displayName
        }
        return friends.first { $0.id == authorId }?.displayName ?? "Unknown"
    }
    
    func getInitials(for name: String) -> String {
        let components = name.components(separatedBy: " ")
        let initials = components.compactMap { $0.first }.prefix(2)
        return String(initials).uppercased()
    }
}

// MARK: - Extended WinePost Initializer

extension WinePost {
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
        imageURLs: [URL],
        thumbnailURL: URL?,
        createdAt: Date,
        likeCount: Int,
        commentCount: Int
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
        self.subjectiveScore = subjectiveScore
        self.imageURLs = imageURLs
        self.thumbnailURL = thumbnailURL
        self.createdAt = createdAt
        self.likeCount = likeCount
        self.commentCount = commentCount
    }
}

// MARK: - Mock Wine Search Results

extension MockDataService {
    
    static func searchWines(query: String) -> [WineSearchResult] {
        let allWines = [
            WineSearchResult(id: "opus_one", name: "Opus One", producer: "Opus One Winery", region: "Napa Valley", country: "USA", varietal: "Cabernet Blend", type: .red, vintages: [2019, 2018, 2017, 2016, 2015], averagePrice: 400, criticScore: 97, imageURL: nil),
            WineSearchResult(id: "caymus", name: "Caymus Cabernet Sauvignon", producer: "Caymus Vineyards", region: "Napa Valley", country: "USA", varietal: "Cabernet Sauvignon", type: .red, vintages: [2020, 2019, 2018], averagePrice: 90, criticScore: 92, imageURL: nil),
            WineSearchResult(id: "cloudy_bay", name: "Cloudy Bay Sauvignon Blanc", producer: "Cloudy Bay", region: "Marlborough", country: "New Zealand", varietal: "Sauvignon Blanc", type: .white, vintages: [2022, 2021, 2020], averagePrice: 28, criticScore: 90, imageURL: nil),
            WineSearchResult(id: "dom_perignon", name: "Dom Pérignon", producer: "Moët & Chandon", region: "Champagne", country: "France", varietal: "Champagne Blend", type: .sparkling, vintages: [2013, 2012, 2010], averagePrice: 200, criticScore: 96, imageURL: nil),
            WineSearchResult(id: "chateau_margaux", name: "Château Margaux", producer: "Château Margaux", region: "Margaux", country: "France", varietal: "Cabernet Blend", type: .red, vintages: [2018, 2016, 2015, 2010], averagePrice: 650, criticScore: 98, imageURL: nil),
            WineSearchResult(id: "silver_oak", name: "Silver Oak Alexander Valley", producer: "Silver Oak", region: "Alexander Valley", country: "USA", varietal: "Cabernet Sauvignon", type: .red, vintages: [2018, 2017, 2016], averagePrice: 85, criticScore: 91, imageURL: nil),
            WineSearchResult(id: "rombauer", name: "Rombauer Chardonnay", producer: "Rombauer Vineyards", region: "Carneros", country: "USA", varietal: "Chardonnay", type: .white, vintages: [2021, 2020, 2019], averagePrice: 40, criticScore: 88, imageURL: nil),
            WineSearchResult(id: "penfolds_grange", name: "Penfolds Grange", producer: "Penfolds", region: "South Australia", country: "Australia", varietal: "Shiraz", type: .red, vintages: [2017, 2016, 2015], averagePrice: 850, criticScore: 97, imageURL: nil),
            WineSearchResult(id: "sassicaia", name: "Sassicaia", producer: "Tenuta San Guido", region: "Bolgheri", country: "Italy", varietal: "Cabernet Blend", type: .red, vintages: [2019, 2018, 2017], averagePrice: 250, criticScore: 95, imageURL: nil),
            WineSearchResult(id: "tignanello", name: "Tignanello", producer: "Antinori", region: "Tuscany", country: "Italy", varietal: "Sangiovese Blend", type: .red, vintages: [2019, 2018, 2017], averagePrice: 120, criticScore: 93, imageURL: nil),
            WineSearchResult(id: "whispering_angel", name: "Whispering Angel", producer: "Caves d'Esclans", region: "Provence", country: "France", varietal: "Grenache Blend", type: .rosé, vintages: [2023, 2022, 2021], averagePrice: 25, criticScore: 88, imageURL: nil),
            WineSearchResult(id: "veuve_clicquot", name: "Veuve Clicquot Yellow Label", producer: "Veuve Clicquot", region: "Champagne", country: "France", varietal: "Champagne Blend", type: .sparkling, vintages: [], averagePrice: 55, criticScore: 90, imageURL: nil),
            WineSearchResult(id: "screaming_eagle", name: "Screaming Eagle", producer: "Screaming Eagle", region: "Napa Valley", country: "USA", varietal: "Cabernet Sauvignon", type: .red, vintages: [2019, 2018, 2017], averagePrice: 3500, criticScore: 99, imageURL: nil),
            WineSearchResult(id: "krug", name: "Krug Grande Cuvée", producer: "Krug", region: "Champagne", country: "France", varietal: "Champagne Blend", type: .sparkling, vintages: [], averagePrice: 200, criticScore: 96, imageURL: nil),
            WineSearchResult(id: "drc", name: "Domaine de la Romanée-Conti", producer: "DRC", region: "Burgundy", country: "France", varietal: "Pinot Noir", type: .red, vintages: [2019, 2018, 2017], averagePrice: 15000, criticScore: 99, imageURL: nil)
        ]
        
        let lowercaseQuery = query.lowercased()
        return allWines.filter { wine in
            wine.name.lowercased().contains(lowercaseQuery) ||
            wine.producer.lowercased().contains(lowercaseQuery) ||
            wine.region.lowercased().contains(lowercaseQuery) ||
            wine.varietal.lowercased().contains(lowercaseQuery)
        }
    }
}
