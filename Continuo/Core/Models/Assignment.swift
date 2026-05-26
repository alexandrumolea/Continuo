import Foundation
import SwiftUI
import FirebaseFirestore

// MARK: - Thread message (coach ↔ client conversation)
struct ThreadMessage: Identifiable, Codable {
    var id: String
    var role: String        // "coach" | "client"
    var text: String
    var sentAt: Timestamp   // Firestore Timestamp — avoids Date/Timestamp conversion issues in arrays

    var date: Date { sentAt.dateValue() }

    enum CodingKeys: String, CodingKey {
        case id, role, text, sentAt
    }
}

enum AssignmentStatus: String, Codable {
    case active   = "active"
    case finished = "finished"
    case paused   = "paused"
}

struct Assignment: Identifiable, Codable {
    @DocumentID var id: String?
    var coachId: String
    var clientId: String
    var title: String
    var description: String
    var emoji: String?          // nil in legacy documents → falls back to "🎯"
    var status: AssignmentStatus
    var gpReward: Int
    var expiresAt: Date?
    var lastCompletedAt: Date?
    var completionCount: Int
    var createdAt: Date
    var competencyId: String?  // optional link to a Competency

    // MARK: - Computed (not persisted)
    var isDueNow: Bool {
        guard status == .active else { return false }
        return lastCompletedAt == nil
    }

    var isExpired: Bool {
        guard let exp = expiresAt else { return false }
        return Date() > exp
    }

    enum CodingKeys: String, CodingKey {
        case id, coachId, clientId, title, description, emoji, status,
             gpReward, expiresAt, lastCompletedAt, completionCount, createdAt, competencyId
    }
}

struct AssignmentCompletion: Identifiable, Codable {
    @DocumentID var id: String?
    var assignmentId: String
    var assignmentTitle: String
    var clientId: String
    var coachId: String
    var response: String
    var completedAt: Date
    var isLiked: Bool = false
    var coachReply: String? = nil   // legacy — kept for backward compat display
    var clientReply: String? = nil  // legacy — kept for backward compat display
    var messages: [ThreadMessage] = []

    enum CodingKeys: String, CodingKey {
        case id, assignmentId, assignmentTitle, clientId, coachId,
             response, completedAt, isLiked, coachReply, clientReply, messages
    }
}
