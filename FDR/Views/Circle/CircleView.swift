// MARK: - CircleView.swift
// VinCircle - iOS Social Wine App
// Inner Circle view with wine-red theme and animations

import SwiftUI

struct CircleView: View {
    
    @StateObject private var mockData = MockDataService.shared
    @State private var showingAddFriend = false
    @State private var selectedFriend: User?
    @State private var hasAppeared = false
    @State private var ringProgress: Double = 0
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Inner Circle Progress
                circleProgress
                    .padding(.vertical, 20)
                
                // Friend List
                friendList
            }
            .navigationTitle("Inner Circle")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddFriend = true
                    } label: {
                        Image(systemName: "person.badge.plus")
                    }
                    .tint(Color.wineRed)
                }
            }
            .sheet(isPresented: $showingAddFriend) {
                AddFriendSheet()
            }
            .sheet(item: $selectedFriend) { friend in
                FriendDetailSheet(friend: friend)
            }
            .onAppear {
                withAnimation(WineAnimations.ringFill) {
                    ringProgress = Double(mockData.friends.count) / 10.0
                    hasAppeared = true
                }
            }
        }
    }
    
    // MARK: - Circle Progress
    
    private var circleProgress: some View {
        VStack(spacing: 12) {
            ZStack {
                // Background Circle
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                    .frame(width: 140, height: 140)
                
                // Animated Progress Circle
                Circle()
                    .trim(from: 0, to: ringProgress)
                    .stroke(
                        WineGradients.accent,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: Color.wineRed.opacity(0.4), radius: 8)
                
                // Center Text
                VStack(spacing: 2) {
                    Text("\(mockData.friends.count)/10")
                        .font(.title.bold())
                        .foregroundStyle(Color.wineRed)
                    Text("Friends")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Text("Your Inner Circle")
                .font(.headline)
            
            if mockData.friends.count < 10 {
                Text("\(10 - mockData.friends.count) spots remaining")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Label("Circle Complete!", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(Color.champagneGold)
            }
        }
    }
    
    // MARK: - Friend List
    
    private var friendList: some View {
        List {
            ForEach(Array(mockData.friends.enumerated()), id: \.element.id) { index, friend in
                FriendRow(friend: friend) {
                    selectedFriend = friend
                }
                .listRowBackground(Color.clear)
                .staggeredAppear(index: index, isVisible: hasAppeared)
            }
        }
        .listStyle(.plain)
    }
}

// MARK: - Friend Row

struct FriendRow: View {
    let friend: User
    let onView: () -> Void
    
    var body: some View {
        HStack(spacing: 14) {
            // Avatar with wine gradient
            Circle()
                .fill(WineGradients.primary)
                .frame(width: 50, height: 50)
                .overlay {
                    Text(initials)
                        .font(.headline)
                        .foregroundStyle(.white)
                }
                .shadow(color: Color.wineRed.opacity(0.3), radius: 4)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(friend.displayName)
                    .font(.subheadline.bold())
                
                HStack(spacing: 8) {
                    Label("\(friend.tastingCount)", systemImage: "wineglass.fill")
                        .foregroundStyle(Color.wineRed)
                    
                    Text("•")
                    
                    Text("Member since \(memberSince)")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button("View") {
                onView()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .tint(Color.wineRed)
        }
        .padding(.vertical, 4)
    }
    
    private var initials: String {
        let components = friend.displayName.components(separatedBy: " ")
        let initials = components.compactMap { $0.first }.prefix(2)
        return String(initials).uppercased()
    }
    
    private var memberSince: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: friend.createdAt)
    }
}

// MARK: - Friend Detail Sheet

struct FriendDetailSheet: View {
    let friend: User
    @Environment(\.dismiss) private var dismiss
    @StateObject private var mockData = MockDataService.shared
    @State private var hasAppeared = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Friend Header
                    friendHeader
                    
                    // Stats
                    statsGrid
                    
                    // Wine Leaderboard
                    leaderboardSection
                    
                    // Recent Posts
                    recentPostsSection
                }
                .padding()
            }
            .navigationTitle(friend.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .tint(Color.wineRed)
                }
            }
            .onAppear {
                withAnimation(WineAnimations.cardAppear.delay(0.2)) {
                    hasAppeared = true
                }
            }
        }
    }
    
    private var friendHeader: some View {
        VStack(spacing: 12) {
            Circle()
                .fill(WineGradients.primary)
                .frame(width: 80, height: 80)
                .overlay {
                    Text(initials)
                        .font(.title.bold())
                        .foregroundStyle(.white)
                }
                .shadow(color: Color.wineRed.opacity(0.4), radius: 10)
                .scaleEffect(hasAppeared ? 1 : 0.8)
                .opacity(hasAppeared ? 1 : 0)
            
            Text(friend.displayName)
                .font(.title2.bold())
            
            Text("Wine enthusiast since \(memberSince)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
    
    private var statsGrid: some View {
        HStack(spacing: 16) {
            StatCardMini(title: "Tastings", value: "\(friend.tastingCount)", icon: "wineglass.fill", color: Color.wineRed)
            StatCardMini(title: "Top Score", value: "97", icon: "star.fill", color: Color.champagneGold)
            StatCardMini(title: "Countries", value: "8", icon: "globe", color: .roseGold)
        }
    }
    
    private var leaderboardSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(friend.displayName.components(separatedBy: " ").first ?? "")'s Top Wines")
                .font(.headline)
            
            let leaderboard = mockData.getLeaderboard(for: friend.id)
            
            ForEach(Array(leaderboard.enumerated()), id: \.element.id) { index, entry in
                LeaderboardRow(entry: entry)
                    .staggeredAppear(index: index, isVisible: hasAppeared)
            }
        }
    }
    
    private var recentPostsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Tastings")
                .font(.headline)
            
            let posts = mockData.getFriendPosts(for: friend.id)
            
            ForEach(Array(posts.enumerated()), id: \.element.id) { index, post in
                RecentPostRow(post: post)
                    .staggeredAppear(index: index + 5, isVisible: hasAppeared)
            }
        }
    }
    
    private var initials: String {
        let components = friend.displayName.components(separatedBy: " ")
        let initials = components.compactMap { $0.first }.prefix(2)
        return String(initials).uppercased()
    }
    
    private var memberSince: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: friend.createdAt)
    }
}

// MARK: - Supporting Views

struct StatCardMini: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            
            Text(value)
                .font(.title3.bold())
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct LeaderboardRow: View {
    let entry: LeaderboardEntry
    
    var body: some View {
        HStack(spacing: 12) {
            Text("#\(entry.rank)")
                .font(.headline)
                .foregroundStyle(Color.wineRed)
                .frame(width: 35)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.winePost.wineName)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                
                Text("\(entry.winePost.region) • \(entry.winePost.vintage)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(entry.eloRating.rating))")
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.champagneGold)
                
                Text("ELO")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct RecentPostRow: View {
    let post: WinePost
    
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(WineGradients.primary.opacity(0.3))
                .frame(width: 50, height: 50)
                .overlay {
                    Image(systemName: "wineglass.fill")
                        .foregroundStyle(Color.wineRed)
                }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(post.wineName)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                
                Text(post.createdAt.timeAgoDisplay())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .foregroundStyle(Color.champagneGold)
                Text("\(post.subjectiveScore)")
            }
            .font(.subheadline)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    CircleView()
}
