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

// MARK: - Assignment frequency

enum AssignmentFrequency: String, Codable {
    case once   = "once"    // default — complete once, then done
    case daily  = "daily"   // one completion per calendar day
    case weekly = "weekly"  // one completion per calendar week
    case open   = "open"    // unlimited, no cooldown

    var label: String {
        switch self {
        case .once:   return "Once"
        case .daily:  return "Daily"
        case .weekly: return "Weekly"
        case .open:   return "Anytime"
        }
    }

    var icon: String {
        switch self {
        case .once:   return "1.circle"
        case .daily:  return "sun.max"
        case .weekly: return "calendar"
        case .open:   return "infinity"
        }
    }
}

// MARK: - Assignment status

enum AssignmentStatus: String, Codable {
    case active   = "active"
    case finished = "finished"
    case paused   = "paused"
}

// MARK: - Assignment

struct Assignment: Identifiable, Codable {
    @DocumentID var id: String?
    var coachId: String
    var clientId: String
    var title: String
    var description: String
    var emoji: String?
    var status: AssignmentStatus
    var gpReward: Int
    var expiresAt: Date?
    var lastCompletedAt: Date?
    var completionCount: Int
    var createdAt: Date
    var competencyId: String?
    var frequency: AssignmentFrequency?  // nil → .once (backward compat with legacy docs)

    // MARK: - Computed helpers

    /// Resolved frequency — nil stored value means legacy "once" behaviour.
    var effectiveFrequency: AssignmentFrequency { frequency ?? .once }

    /// True when the client can submit a new completion right now.
    var isDueNow: Bool {
        guard status == .active else { return false }
        guard let last = lastCompletedAt else { return true }  // never completed
        switch effectiveFrequency {
        case .once:
            return false
        case .daily:
            return !Calendar.current.isDateInToday(last)
        case .weekly:
            return !Calendar.current.isDate(last, equalTo: Date(), toGranularity: .weekOfYear)
        case .open:
            return true
        }
    }

    /// Date from which the next completion becomes available (nil when always/never due).
    var nextAvailableDate: Date? {
        guard let last = lastCompletedAt else { return nil }
        switch effectiveFrequency {
        case .once, .open:
            return nil
        case .daily:
            return Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: last))
        case .weekly:
            return Calendar.current.date(byAdding: .weekOfYear, value: 1, to: last)
        }
    }

    var isExpired: Bool {
        guard let exp = expiresAt else { return false }
        return Date() > exp
    }

    enum CodingKeys: String, CodingKey {
        case id, coachId, clientId, title, description, emoji, status,
             gpReward, expiresAt, lastCompletedAt, completionCount, createdAt,
             competencyId, frequency
    }
}

// MARK: - Assignment completion

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
