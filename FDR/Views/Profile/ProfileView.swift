// MARK: - ProfileView.swift
// FRIDAYRED - Wine Ranking App
// Profile tab with Wine Passport, world map, and stats

import SwiftUI
import MapKit

struct ProfileView: View {
    @EnvironmentObject private var dataService: RankingDataService
    @State private var selectedTimeFrame = 0  // 0 = All-Time, 1 = This Year
    @State private var showingFriends = false
    @State private var showingSettings = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Wine Map
                    wineMapSection
                    
                    // User Header
                    userHeader
                    
                    // Action Buttons
                    actionButtons
                    
                    // Wine Passport Card
                    winePassportCard
                    
                    // Share Passport Button
                    shareButton
                    
                    // Invite Section
                    inviteSection
                }
                .padding()
            }
            .navigationTitle("Profile")
            .background(Color(.systemGroupedBackground))
            .sheet(isPresented: $showingFriends) {
                FriendsListView()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }
    
    // MARK: - Wine Map Section
    private var wineMapSection: some View {
        Map {
            // Add annotations for regions with wines
            ForEach(visitedRegions) { region in
                Annotation(region.name, coordinate: region.coordinate) {
                    Circle()
                        .fill(Color.wineRed)
                        .frame(width: wineCountForRegion(region) * 4 + 12, height: wineCountForRegion(region) * 4 + 12)
                        .overlay {
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        }
                }
            }
        }
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - User Header
    private var userHeader: some View {
        VStack(spacing: 8) {
            Circle()
                .fill(WineGradients.primary)
                .frame(width: 80, height: 80)
                .overlay {
                    Text(initials)
                        .font(.title.bold())
                        .foregroundStyle(.white)
                }
            
            Text(dataService.currentUser.displayName)
                .font(.title2.bold())
            
            Text("@\(dataService.currentUser.username)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Text("My Wine Passport")
                .font(.caption)
                .foregroundStyle(Color.wineRed)
        }
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        HStack(spacing: 20) {
            Button {
                showingFriends = true
            } label: {
                VStack {
                    Image(systemName: "person.2.fill")
                        .font(.title2)
                    Text("Friends")
                        .font(.caption)
                }
                .foregroundStyle(Color.wineRed)
            }
            
            Button {
                showingSettings = true
            } label: {
                VStack {
                    Image(systemName: "gearshape.fill")
                        .font(.title2)
                    Text("Settings")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }
        }
    }
    
    // MARK: - Wine Passport Card
    private var winePassportCard: some View {
        VStack(spacing: 16) {
            // Time Frame Toggle
            Picker("Time Frame", selection: $selectedTimeFrame) {
                Text("ALL-TIME").tag(0)
                Text("2026").tag(1)
            }
            .pickerStyle(.segmented)
            
            // Passport Title
            HStack {
                Image(systemName: "wineglass.fill")
                    .foregroundStyle(Color.wineRed)
                Text("WINE PASSPORT")
                    .font(.headline.bold())
                    .foregroundStyle(Color.wineRed)
            }
            
            // Stats Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                StatItem(label: "WINES RATED", value: "\(totalWines)")
                StatItem(label: "REGIONS", value: "\(visitedRegions.count)")
                StatItem(label: "GRAPE VARIETIES", value: "\(rankedGrapes.count)")
                StatItem(label: "FRIENDS", value: "\(dataService.currentUser.friendIds.count)")
                StatItem(label: "VINTAGES TRIED", value: "\(totalVintages)")
                StatItem(label: "TOP GRAPE", value: topGrape?.name ?? "-")
            }
            
            // Top Region
            if let region = topRegion {
                HStack {
                    Text("TOP REGION")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(region.name) (\(wineCountForRegion(region)) wines)")
                        .font(.subheadline.bold())
                }
            }
            
            // View All Stats
            Button {
                // TODO: Navigate to detailed stats
            } label: {
                HStack {
                    Text("All Wine Stats")
                        .font(.subheadline)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                }
                .foregroundStyle(Color.wineRed)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Share Button
    private var shareButton: some View {
        Button {
            sharePassport()
        } label: {
            HStack {
                Image(systemName: "square.and.arrow.up")
                Text("Share Passport")
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.wineRed)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Invite Section
    private var inviteSection: some View {
        HStack {
            Text("INVITES REMAINING:")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text("\(dataService.remainingInvites) of 5")
                .font(.caption.bold())
            
            Spacer()
            
            Button("Share Invite Link") {
                // Share invite
            }
            .font(.caption.bold())
            .foregroundStyle(Color.wineRed)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Computed Properties
    private var initials: String {
        let name = dataService.currentUser.displayName
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }
    
    private var totalWines: Int {
        dataService.rankings
            .filter { $0.userId == dataService.currentUser.id }
            .reduce(0) { $0 + $1.entries.count }
    }
    
    private var totalVintages: Int {
        dataService.rankings
            .filter { $0.userId == dataService.currentUser.id }
            .flatMap { $0.entries }
            .reduce(0) { $0 + $1.vintageTastings.count }
    }
    
    private var rankedGrapes: [GrapeVariety] {
        dataService.rankedGrapes()
    }
    
    private var topGrape: GrapeVariety? {
        let counts = Dictionary(grouping: dataService.rankings.filter { $0.userId == dataService.currentUser.id }) { $0.grapeId }
            .mapValues { rankings in rankings.reduce(0) { $0 + $1.entries.count } }
        
        if let maxEntry = counts.max(by: { $0.value < $1.value }) {
            return GrapeVariety.standardVarieties.first { $0.id == maxEntry.key }
        }
        return nil
    }
    
    private var visitedRegions: [WineRegion] {
        let wineIds = dataService.rankings
            .filter { $0.userId == dataService.currentUser.id }
            .flatMap { $0.entries.map { $0.wineId } }
        
        let regionIds = Set(dataService.wines.filter { wineIds.contains($0.id) }.map { $0.regionId })
        
        return WineRegion.commonRegions.filter { regionIds.contains($0.id) }
    }
    
    private var topRegion: WineRegion? {
        let regionCounts = visitedRegions.map { region in
            (region, wineCountForRegion(region))
        }
        return regionCounts.max(by: { $0.1 < $1.1 })?.0
    }
    
    private func wineCountForRegion(_ region: WineRegion) -> Int {
        let wineIds = dataService.rankings
            .filter { $0.userId == dataService.currentUser.id }
            .flatMap { $0.entries.map { $0.wineId } }
        
        return dataService.wines.filter { wineIds.contains($0.id) && $0.regionId == region.id }.count
    }
    
    private func sharePassport() {
        // Generate shareable passport image
        let text = """
        🍷 My FRIDAYRED Wine Passport
        
        Wines Rated: \(totalWines)
        Regions: \(visitedRegions.count)
        Grape Varieties: \(rankedGrapes.count)
        Top Grape: \(topGrape?.name ?? "-")
        
        Join me on FRIDAYRED!
        """
        
        let activityVC = UIActivityViewController(
            activityItems: [text],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

// MARK: - Stat Item
struct StatItem: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.bold())
        }
    }
}

// MARK: - Friends List View
struct FriendsListView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var dataService: RankingDataService
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(dataService.friends()) { friend in
                    HStack {
                        Circle()
                            .fill(Color.wineRed.opacity(0.2))
                            .frame(width: 44, height: 44)
                            .overlay {
                                Text(String(friend.displayName.prefix(1)))
                                    .font(.headline)
                                    .foregroundStyle(Color.wineRed)
                            }
                        
                        VStack(alignment: .leading) {
                            Text(friend.displayName)
                                .font(.headline)
                            Text("@\(friend.username)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                }
            }
            .navigationTitle("Friends")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        // Add friend
                    } label: {
                        Image(systemName: "person.badge.plus")
                    }
                }
            }
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(RankingDataService.shared)
}
