// MARK: - HomeView.swift
// FRIDAYRED - Wine Ranking App
// Home tab with search, invite card, and friend activity feed

import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var dataService: RankingDataService
    @State private var searchText = ""
    @State private var showingWineSearch = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Search Bar
                    searchBar
                    
                    // Invite Card (persistent until all invites used)
                    if dataService.remainingInvites > 0 {
                        inviteCard
                    }
                    
                    // Friend Activity Feed
                    friendActivitySection
                }
                .padding()
            }
            .navigationTitle("Home")
            .background(Color(.systemGroupedBackground))
        }
        .sheet(isPresented: $showingWineSearch) {
            WineSearchView()
        }
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        Button {
            showingWineSearch = true
        } label: {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                Text("Search for a wine...")
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Invite Card
    private var inviteCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "wineglass.fill")
                    .font(.title2)
                    .foregroundStyle(Color.wineRed)
                
                Text("INVITE YOUR FRIENDS")
                    .font(.headline.bold())
                    .foregroundStyle(Color.wineRed)
            }
            
            Text("Wine is better with friends. Share your invites so they can join and start ranking too.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Text("\(dataService.remainingInvites) of 5 invites remaining")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Button {
                shareInviteLink()
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share Invite Link")
                }
                .font(.subheadline.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.wineRed)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
    
    // MARK: - Friend Activity Section
    private var friendActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("FRIEND ACTIVITY")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            
            let events = dataService.friendFeedEvents()
            
            if events.isEmpty {
                emptyFeedState
            } else {
                ForEach(events) { event in
                    FeedEventCard(event: event)
                }
            }
        }
    }
    
    // MARK: - Empty State
    private var emptyFeedState: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.2.slash")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            
            Text("Add friends to see what they're drinking!")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Text("Share your invite link above.")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    // MARK: - Actions
    private func shareInviteLink() {
        // Generate and share invite link
        let inviteCode = dataService.currentUser.inviteCodes.first { !$0.isUsed }?.code ?? "WINE-XXXX"
        let url = "https://fridayred.app/invite/\(inviteCode)"
        
        let activityVC = UIActivityViewController(
            activityItems: ["Join me on FRIDAYRED! Use my invite code: \(inviteCode)\n\(url)"],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

// MARK: - Feed Event Card
struct FeedEventCard: View {
    let event: FeedEvent
    @EnvironmentObject private var dataService: RankingDataService
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Avatar
            Circle()
                .fill(Color.wineRed.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay {
                    Text(initials)
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.wineRed)
                }
            
            VStack(alignment: .leading, spacing: 4) {
                // User action
                HStack(spacing: 4) {
                    Text(userName)
                        .font(.subheadline.bold())
                    Text(event.eventType.actionText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                // Wine name
                if let wine = dataService.wine(byId: event.wineId) {
                    Text(wine.fullName)
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.wineRed)
                }
                
                // Ranking info
                HStack(spacing: 4) {
                    Text(event.positionDisplay)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("in their \(grapeName)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("(tried \(event.vintageDisplay))")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                
                // Timestamp
                Text(event.createdAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var userName: String {
        dataService.user(byId: event.actorUserId)?.displayName ?? "Friend"
    }
    
    private var initials: String {
        let name = userName
        return String(name.prefix(1)).uppercased()
    }
    
    private var grapeName: String {
        GrapeVariety.standardVarieties.first { $0.id == event.grapeId }?.name ?? "wines"
    }
}

// MARK: - Wine Search View (Placeholder)
struct WineSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var dataService: RankingDataService
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(dataService.searchWines(query: searchText)) { wine in
                    NavigationLink {
                        WineDetailView(wine: wine)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(wine.producer)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(wine.name)
                                .font(.headline)
                            if let grape = wine.grape() {
                                Text(grape.name)
                                    .font(.caption)
                                    .foregroundStyle(Color.wineRed)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search wines...")
            .navigationTitle("Search Wines")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Wine Detail View (Placeholder)
struct WineDetailView: View {
    let wine: Wine
    @EnvironmentObject private var dataService: RankingDataService
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Wine Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(wine.producer)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text(wine.name)
                        .font(.largeTitle.bold())
                    
                    if let grape = wine.grape(), let region = wine.region() {
                        Text("\(grape.name) • \(region.name)")
                            .font(.subheadline)
                            .foregroundStyle(Color.wineRed)
                    }
                }
                .padding()
                
                // Rate Button
                NavigationLink {
                    RateWineView(wine: wine)
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Rate This Wine")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.wineRed)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
                
                Spacer()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    HomeView()
        .environmentObject(RankingDataService.shared)
}
