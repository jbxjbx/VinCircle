// MARK: - FeedView.swift
// VinCircle - iOS Social Wine App
// Feed showing posts from friends with photo carousel and wine-red theme

import SwiftUI

struct FeedView: View {
    
    @StateObject private var mockData = MockDataService.shared
    @State private var hasAppeared = false
    @State private var selectedPostForComments: WinePost?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 20) {
                    ForEach(Array(mockData.posts.enumerated()), id: \.element.id) { index, post in
                        FeedPostCard(
                            post: post,
                            authorName: mockData.getAuthorName(for: post.authorId),
                            authorInitials: mockData.getInitials(for: mockData.getAuthorName(for: post.authorId)),
                            onCommentTap: {
                                selectedPostForComments = post
                            }
                        )
                        .staggeredAppear(index: index, isVisible: hasAppeared)
                    }
                }
                .padding()
            }
            .navigationTitle("Feed")
            .refreshable {
                // Simulate refresh
                try? await Task.sleep(nanoseconds: 500_000_000)
            }
            .onAppear {
                withAnimation(WineAnimations.cardAppear) {
                    hasAppeared = true
                }
            }
            .sheet(item: $selectedPostForComments) { post in
                CommentsSheet(post: post)
            }
        }
    }
}

// MARK: - Feed Post Card

struct FeedPostCard: View {
    let post: WinePost
    let authorName: String
    let authorInitials: String
    let onCommentTap: () -> Void
    
    @State private var currentImageIndex = 0
    @State private var isLiked = false
    @State private var animateHeart = false
    
    // Wine-themed placeholder colors
    private let placeholderColors: [Color] = [
        .deepBurgundy.opacity(0.4),
        Color.wineRed.opacity(0.4),
        .roseGold.opacity(0.4)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // User Header
            userHeader
            
            // Photo Carousel
            photoCarousel
            
            // Wine Info
            wineInfo
            
            // Attributes Preview
            attributesPreview
            
            // Engagement Bar
            engagementBar
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - User Header
    
    private var userHeader: some View {
        HStack(spacing: 12) {
            // Avatar with wine gradient
            Circle()
                .fill(WineGradients.primary)
                .frame(width: 44, height: 44)
                .overlay {
                    Text(authorInitials)
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                }
                .shadow(color: Color.wineRed.opacity(0.3), radius: 4)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(authorName)
                    .font(.subheadline.bold())
                
                Text(post.createdAt.timeAgoDisplay())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Score Badge with champagne gold
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .foregroundStyle(Color.champagneGold)
                Text("\(post.subjectiveScore)")
                    .fontWeight(.semibold)
            }
            .font(.subheadline)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.champagneGold.opacity(0.15))
            .clipShape(Capsule())
        }
    }
    
    // MARK: - Photo Carousel
    
    private var photoCarousel: some View {
        VStack(spacing: 8) {
            TabView(selection: $currentImageIndex) {
                ForEach(0..<3, id: \.self) { index in
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(placeholderColors[index])
                        
                        VStack(spacing: 8) {
                            Image(systemName: "wineglass.fill")
                                .font(.system(size: 50))
                                .foregroundStyle(.white.opacity(0.8))
                            
                            Text(post.wineName)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 280)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Page Indicator with wine colors
            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(index == currentImageIndex ? Color.wineRed : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .scaleEffect(index == currentImageIndex ? 1.2 : 1.0)
                        .animation(.spring(response: 0.3), value: currentImageIndex)
                }
            }
        }
    }
    
    // MARK: - Wine Info
    
    private var wineInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(post.wineName)
                .font(.headline)
            
            Text("\(post.producer) • \(post.vintage)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            HStack {
                Label(post.region, systemImage: "mappin")
                Spacer()
                Label(post.wineType.rawValue, systemImage: post.wineType.iconName)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Attributes Preview
    
    private var attributesPreview: some View {
        HStack(spacing: 12) {
            AttributeMiniBar(label: "Acidity", value: post.attributes.acidity)
            AttributeMiniBar(label: "Body", value: post.attributes.body)
            if post.wineType == .red {
                AttributeMiniBar(label: "Tannin", value: post.attributes.tannin)
            } else {
                AttributeMiniBar(label: "Sweet", value: post.attributes.sweetness)
            }
        }
    }
    
    // MARK: - Engagement Bar
    
    private var engagementBar: some View {
        HStack(spacing: 20) {
            // Animated Heart Button
            Button {
                withAnimation(WineAnimations.heartPulse) {
                    isLiked.toggle()
                    animateHeart = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    animateHeart = false
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .foregroundStyle(isLiked ? Color.wineRed : .secondary)
                        .scaleEffect(animateHeart ? 1.4 : 1.0)
                    Text("\(post.likeCount + (isLiked ? 1 : 0))")
                        .foregroundStyle(isLiked ? Color.wineRed : .secondary)
                }
            }
            .buttonStyle(.plain)
            
            Button {
                onCommentTap()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "bubble.left")
                    Text("\(post.commentCount)")
                }
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            
            Spacer()
            
            Button {
                // Share action
            } label: {
                Image(systemName: "square.and.arrow.up")
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .font(.subheadline)
    }
}

// MARK: - Attribute Mini Bar

struct AttributeMiniBar: View {
    let label: String
    let value: Double
    
    @State private var animatedValue: Double = 0
    
    var body: some View {
        VStack(spacing: 4) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.gray.opacity(0.2))
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [Color.wineRed, .roseGold],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * animatedValue)
                }
            }
            .frame(height: 6)
            
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .onAppear {
            withAnimation(WineAnimations.ringFill.delay(0.3)) {
                animatedValue = value
            }
        }
    }
}

#Preview {
    FeedView()
}

