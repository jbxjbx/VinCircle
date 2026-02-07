// MARK: - CommentsSheet.swift
// VinCircle - iOS Social Wine App
// Comments view with Tier 1 restriction

import SwiftUI
import Combine

struct CommentsSheet: View {
    let post: WinePost
    @StateObject private var viewModel = CommentsViewModel()
    @EnvironmentObject private var mockData: MockDataService
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                // Comments List
                if viewModel.comments.isEmpty {
                    ContentUnavailableView(
                        "No Comments",
                        systemImage: "bubble.left.and.bubble.right",
                        description: Text("Be the first to share your thoughts!")
                    )
                } else {
                    List(viewModel.comments) { comment in
                        CommentRow(comment: comment)
                            .listRowSeparator(.hidden)
                    }
                    .listStyle(.plain)
                }
                
                Divider()
                
                // Input Area
                if canComment {
                    HStack {
                        TextField("Add a comment...", text: $viewModel.newCommentText)
                            .textFieldStyle(.roundedBorder)
                        
                        Button {
                            submitComment()
                        } label: {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.title2)
                                .foregroundStyle(viewModel.newCommentText.isEmpty ? .gray : Color.wineRed)
                        }
                        .disabled(viewModel.newCommentText.isEmpty)
                    }
                    .padding()
                } else {
                    Text("Only Inner Circle friends can comment on this post.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.1))
                }
            }
            .navigationTitle("Comments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                    .tint(Color.wineRed)
                }
            }
            .onAppear {
                viewModel.loadComments(for: post.id, mockData: mockData)
            }
        }
    }
    
    private var canComment: Bool {
        // Allow if current user is author OR is a Tier 1 friend of the author
        mockData.currentUser.id == post.authorId || 
        mockData.isTier1Friend(userId: post.authorId)
    }
    
    private func submitComment() {
        guard !viewModel.newCommentText.isEmpty else { return }
        
        mockData.addComment(
            postId: post.id,
            text: viewModel.newCommentText,
            authorId: mockData.currentUser.id
        )
        
        viewModel.newCommentText = ""
        viewModel.loadComments(for: post.id, mockData: mockData)
    }
}

// MARK: - View Model
@MainActor
class CommentsViewModel: ObservableObject {
    @Published var comments: [Comment] = []
    @Published var newCommentText = ""
    
    func loadComments(for postId: UUID, mockData: MockDataService) {
        self.comments = mockData.getComments(for: postId)
    }
}

// MARK: - Comment Row
struct CommentRow: View {
    let comment: Comment
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 32, height: 32)
                .overlay {
                    Text(comment.authorName.prefix(1).uppercased())
                        .font(.caption.bold())
                        .foregroundStyle(Color.wineRed)
                }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(comment.authorName)
                        .font(.subheadline.bold())
                    
                    Spacer()
                    
                    Text(comment.createdAt.timeAgoDisplay())
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                Text(comment.text)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            }
        }
        .padding(.vertical, 4)
    }
}
