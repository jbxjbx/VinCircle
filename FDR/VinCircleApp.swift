// MARK: - VinCircleApp.swift
// VinCircle - iOS Social Wine App
// Main app entry point with wine-red theme

import SwiftUI

@main
struct VinCircleApp: App {
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(MockDataService.shared)
        }
    }
}

// MARK: - Content View (Tab Navigation)

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var showingNewPost = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Feed Tab
            FeedView()
                .tabItem {
                    Label("Feed", systemImage: "square.grid.2x2")
                }
                .tag(0)
            
            // Discover Map Tab
            MapDiscoveryView()
                .tabItem {
                    Label("Discover", systemImage: "map")
                }
                .tag(1)
            
            // My Feed / Post Tab
            MyPostsView()
                .tabItem {
                    Label("My Cellar", systemImage: "wineglass.fill")
                }
                .tag(2)
            
            // Friends Tab
            CircleView()
                .tabItem {
                    Label("Circle", systemImage: "person.2")
                }
                .tag(3)
            
            // Profile Tab
            MainProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
                .tag(4)
        }
        .tint(Color.wineRed)

        .sheet(isPresented: $showingNewPost) {
            StructuredPostingView()
        }
    }
}

// MARK: - Main Profile View (Wine-themed)

struct MainProfileView: View {
    @StateObject private var mockData = MockDataService.shared
    @State private var hasAppeared = false
    @State private var showingSettings = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Wine-themed Header
                    profileHeader
                    
                    // Stats Grid
                    statsGrid
                    
                    // AI Leaderboard Section
                    leaderboardSection
                    
                    // Achievements
                    achievementsSection
                }
                .padding(.vertical)
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .tint(Color.wineRed)
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .onAppear {
                withAnimation(WineAnimations.cardAppear.delay(0.2)) {
                    hasAppeared = true
                }
            }
        }
    }
    
    // MARK: - Profile Header
    
    private var profileHeader: some View {
        VStack(spacing: 12) {
            Circle()
                .fill(WineGradients.primary)
                .frame(width: 100, height: 100)
                .overlay {
                    Text(mockData.getInitials(for: mockData.currentUser.displayName))
                        .font(.title.bold())
                        .foregroundStyle(.white)
                }
                .shadow(color: Color.wineRed.opacity(0.4), radius: 12)
                .scaleEffect(hasAppeared ? 1 : 0.8)
                .opacity(hasAppeared ? 1 : 0)
            
            Text(mockData.currentUser.displayName)
                .font(.title2.bold())
            
            Text("Wine Explorer since 2023")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            // Level Badge
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundStyle(Color.champagneGold)
                Text("Level 12 Sommelier")
                    .font(.caption.bold())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.champagneGold.opacity(0.15))
            .clipShape(Capsule())
        }
        .padding()
    }
    
    // MARK: - Stats Grid
    
    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            StatCard(title: "Tastings", value: "\(mockData.currentUser.tastingCount)", icon: "wineglass.fill", color: Color.wineRed)
            StatCard(title: "Avg Score", value: "78", icon: "star.fill", color: Color.champagneGold)
            StatCard(title: "Countries", value: "12", icon: "globe", color: .roseGold)
            StatCard(title: "Achievements", value: "8", icon: "trophy.fill", color: Color.champagneGold)
        }
        .padding(.horizontal)
    }
    
    // MARK: - Leaderboard Section
    
    private var leaderboardSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Your Top 10 Wines")
                    .font(.headline)
                
                Spacer()
                
                Menu {
                    Button("All Wines") {}
                    Button("Red Only") {}
                    Button("White Only") {}
                    Button("This Year") {}
                } label: {
                    Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                        .font(.caption)
                        .foregroundStyle(Color.wineRed)
                }
            }
            
            // Demo leaderboard entries
            ForEach(1...5, id: \.self) { rank in
                HStack {
                    ZStack {
                        Circle()
                            .fill(rankColor(rank))
                            .frame(width: 36, height: 36)
                        
                        Text("#\(rank)")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(["Opus One 2019", "Château Margaux 2015", "Silver Oak 2018", "Penfolds Grange 2017", "Sassicaia 2018"][rank - 1])
                            .font(.subheadline.bold())
                            .lineLimit(1)
                        Text(["Napa Valley • 2019", "Margaux • 2015", "Alexander Valley • 2018", "South Australia • 2017", "Bolgheri • 2018"][rank - 1])
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\([1250, 1198, 1156, 1123, 1089][rank - 1])")
                            .font(.subheadline.bold())
                            .foregroundStyle(.green)
                        
                        Text("ELO")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .staggeredAppear(index: rank, isVisible: hasAppeared)
            }
        }
        .padding(.horizontal)
    }
    
    private func rankColor(_ rank: Int) -> Color {
        switch rank {
        case 1: return .champagneGold
        case 2: return .gray
        case 3: return Color(hex: "#CD7F32")
        default: return .wineRed.opacity(0.7)
        }
    }
    
    // MARK: - Achievements Section
    
    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Achievements")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    AchievementBadge(icon: "wineglass.fill", title: "First Taste", color: .bronze)
                    AchievementBadge(icon: "10.circle.fill", title: "10 Wines", color: .silver)
                    AchievementBadge(icon: "map.fill", title: "Explorer", color: .gold)
                    AchievementBadge(icon: "person.3.fill", title: "Social", color: .silver)
                    AchievementBadge(icon: "100.circle.fill", title: "Century", color: .platinum)
                }
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            Text(value)
                .font(.title.bold())
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Achievement Badge

struct AchievementBadge: View {
    let icon: String
    let title: String
    let color: AchievementColor
    
    var body: some View {
        VStack(spacing: 8) {
            Circle()
                .fill(color.gradient)
                .frame(width: 60, height: 60)
                .overlay {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(.white)
                }
                .shadow(color: color.shadowColor.opacity(0.4), radius: 6)
            
            Text(title)
                .font(.caption)
        }
    }
    
    enum AchievementColor: Sendable {
        case bronze, silver, gold, platinum
        
        var gradient: LinearGradient {
            switch self {
            case .bronze:
                return LinearGradient(colors: [Color(hex: "#CD7F32"), Color(hex: "#A0522D")], startPoint: .top, endPoint: .bottom)
            case .silver:
                return LinearGradient(colors: [Color(hex: "#C0C0C0"), Color(hex: "#808080")], startPoint: .top, endPoint: .bottom)
            case .gold:
                return LinearGradient(colors: [.champagneGold, Color(hex: "#DAA520")], startPoint: .top, endPoint: .bottom)
            case .platinum:
                return LinearGradient(colors: [Color(hex: "#E5E4E2"), Color(hex: "#B4B4B4")], startPoint: .top, endPoint: .bottom)
            }
        }
        
        var shadowColor: Color {
            switch self {
            case .bronze: return Color(hex: "#CD7F32")
            case .silver: return Color(hex: "#C0C0C0")
            case .gold: return .champagneGold
            case .platinum: return Color(hex: "#E5E4E2")
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(MockDataService.shared)
}
