// MARK: - FridayRedApp.swift
// FRIDAYRED - Wine Ranking App
// Main app entry point with new tab structure

import SwiftUI

@main
struct VinCircleApp: App {
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(MockDataService.shared)
                .environmentObject(RankingDataService.shared)
        }
    }
}

// MARK: - Content View (FRIDAYRED Tab Navigation)

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab - Feed + Search + Invite Card
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            // My List Tab - Grape-segmented rankings
            MyListView()
                .tabItem {
                    Label("My List", systemImage: "list.number")
                }
                .tag(1)
            
            // Rate Tab - Manual wine search + comparison flow
            RateView()
                .tabItem {
                    Label("Rate", systemImage: "plus.circle.fill")
                }
                .tag(2)
            
            // Map Tab - Nearby stores
            MapDiscoveryView()
                .tabItem {
                    Label("Map", systemImage: "map.fill")
                }
                .tag(3)
            
            // Profile Tab - Wine Passport
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle.fill")
                }
                .tag(4)
        }
        .tint(Color.wineRed)
    }
}

#Preview {
    ContentView()
        .environmentObject(MockDataService.shared)
        .environmentObject(RankingDataService.shared)
}
