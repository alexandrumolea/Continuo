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

enum AssignmentType: String, Codable, CaseIterable {
    case reflection = "reflection"
    case task       = "task"
    case reading    = "reading"
    case exercise   = "exercise"

    var label: String {
        switch self {
        case .reflection: return "Reflection"
        case .task:       return "Task"
        case .reading:    return "Reading"
        case .exercise:   return "Exercise"
        }
    }
    var emoji: String {
        switch self {
        case .reflection: return "🪞"
        case .task:       return "✅"
        case .reading:    return "📚"
        case .exercise:   return "🧘"
        }
    }
    var color: Color {
        switch self {
        case .reflection: return Color(hex: "7A3F38")
        case .task:       return Color(hex: "6E7E3F")
        case .reading:    return Color(hex: "5C6FBE")
        case .exercise:   return Color(hex: "C07B2A")
        }
    }
    var needsTextResponse: Bool {
        self == .reflection
    }
}

enum RecurrenceType: String, Codable, CaseIterable {
    case none    = "none"
    case daily   = "daily"
    case weekly  = "weekly"
    case monthly = "monthly"

    var label: String {
        switch self {
        case .none:    return "One-time"
        case .daily:   return "Daily"
        case .weekly:  return "Weekly"
        case .monthly: return "Monthly"
        }
    }
    var icon: String {
        switch self {
        case .none:    return "1.circle"
        case .daily:   return "sun.max"
        case .weekly:  return "calendar.badge.clock"
        case .monthly: return "moon.stars"
        }
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
    var type: AssignmentType
    var status: AssignmentStatus
    var recurrence: RecurrenceType
    var gpReward: Int
    var expiresAt: Date?
    var lastCompletedAt: Date?
    var completionCount: Int
    var createdAt: Date

    // MARK: - Computed (not persisted)
    var isDueNow: Bool {
        guard status == .active else { return false }
        guard let last = lastCompletedAt else { return true }
        switch recurrence {
        case .none:
            return false
        case .daily:
            return !Calendar.current.isDateInToday(last)
        case .weekly:
            let days = Calendar.current.dateComponents([.day], from: last, to: Date()).day ?? 0
            return days >= 7
        case .monthly:
            let days = Calendar.current.dateComponents([.day], from: last, to: Date()).day ?? 0
            return days >= 30
        }
    }

    var isExpired: Bool {
        guard let exp = expiresAt else { return false }
        return Date() > exp
    }

    enum CodingKeys: String, CodingKey {
        case id, coachId, clientId, title, description, type, status,
             recurrence, gpReward, expiresAt, lastCompletedAt, completionCount, createdAt
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
