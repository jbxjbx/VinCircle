// MARK: - Comment.swift
// VinCircle - iOS Social Wine App
// Model for post comments

import Foundation

struct Comment: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let postId: UUID
    let authorId: UUID
    let authorName: String
    let text: String
    let createdAt: Date
    
    init(
        id: UUID = UUID(),
        postId: UUID,
        authorId: UUID,
        authorName: String,
        text: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.postId = postId
        self.authorId = authorId
        self.authorName = authorName
        self.text = text
        self.createdAt = createdAt
    }
}
