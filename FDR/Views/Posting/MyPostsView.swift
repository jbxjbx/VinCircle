// MARK: - MyPostsView.swift
// VinCircle - iOS Social Wine App
// Personal feed management view

import SwiftUI

struct MyPostsView: View {
    @EnvironmentObject private var mockData: MockDataService
    @State private var showingAddTasting = false
    @State private var selectedPostForComments: WinePost?
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                // Main List
                List {
                    if myPosts.isEmpty {
                        ContentUnavailableView(
                            "No Tastings Yet",
                            systemImage: "wineglass",
                            description: Text("Start your wine journey by tapping the + button")
                        )
                        .listRowSeparator(.hidden)
                    } else {
                        ForEach(myPosts) { post in
                            MyPostRow(post: post) {
                                selectedPostForComments = post
                            }
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets())
                            .padding(.vertical, 8)
                        }
                        .onDelete(perform: deletePost)
                    }
                }
                .listStyle(.plain)
                
                // Floating Action Button
                Button {
                    showingAddTasting = true
                } label: {
                    Image(systemName: "plus")
                        .font(.title.bold())
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(Color.wineRed)
                        .clipShape(Circle())
                        .shadow(radius: 4, y: 4)
                }
                .padding()
            }
            .navigationTitle("My Cellar")
            .sheet(isPresented: $showingAddTasting) {
                // Wrapper to present the posting flow
                StructuredPostingView()
            }
            .sheet(item: $selectedPostForComments) { post in
                CommentsSheet(post: post)
            }
        }
    }
    
    private var myPosts: [WinePost] {
        mockData.posts
            .filter { $0.authorId == mockData.currentUser.id }
            .sorted { $0.createdAt > $1.createdAt }
    }
    
    private func deletePost(at offsets: IndexSet) {
        for index in offsets {
            let post = myPosts[index]
            mockData.deletePost(id: post.id)
        }
    }
}

// MARK: - My Post Row (Simplified Feed Item)
struct MyPostRow: View {
    let post: WinePost
    let onCommentTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.wineName)
                        .font(.headline)
                        .foregroundStyle(Color.wineRed)
                    
                    Text("\(post.producer) • \(post.vintage)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Score Badge
                ZStack {
                    Circle()
                        .stroke(Color.wineRed, lineWidth: 2)
                        .frame(width: 40, height: 40)
                    
                    Text("\(post.subjectiveScore)")
                        .font(.caption.bold())
                        .foregroundStyle(Color.wineRed)
                }
            }
            
            // Image Preview (if available)
            if !post.imageURLs.isEmpty {
                // Placeholder since we don't have async image loaders setup in this block
                // In real app, perform actual loading.
                // For now, just a styled rectangle indicating image
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 200)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            // Footer (Time & Comments)
            HStack {
                Text(post.createdAt.timeAgoDisplay())
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Button(action: onCommentTap) {
                    Label("\(post.commentCount)", systemImage: "bubble.right")
                        .font(.subheadline)
                        .foregroundStyle(Color.wineRed)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
}
