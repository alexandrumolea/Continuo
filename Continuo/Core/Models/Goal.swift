import SwiftUI
import FirebaseFirestore

enum GoalType: String, Codable, CaseIterable {
    case general    = "general"
    case competence = "competence"

    var label: String {
        switch self {
        case .general:    return "General"
        case .competence: return "Competence"
        }
    }
    var emoji: String {
        switch self {
        case .general:    return "🌱"
        case .competence: return "🧠"
        }
    }
    var color: Color {
        switch self {
        case .general:    return Color(hex: "4E7A52")
        case .competence: return Color(hex: "4A5FA3")
        }
    }
    var cardColor: Color {
        switch self {
        case .general:    return Color(hex: "ECF3ED")
        case .competence: return Color(hex: "ECEEF8")
        }
    }
}

struct Goal: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var title: String
    var type: GoalType
    var emoji: String?         // custom emoji; nil → falls back to type.emoji
    var progress: Double       // 0.0 – 1.0
    var createdAt: Date
    var successMeasure: String? = nil
    var order: Int = 0         // display order in In Focus
    /// When true, the client's connected coach can read this goal + its reflections.
    /// Optional for backward compat — nil/false both mean private.
    var sharedWithCoach: Bool? = nil
    /// Set to true when the goal was created by the coach and sent to the client.
    var createdByCoach: Bool? = nil
    /// The coachId who created this goal (only set when createdByCoach == true).
    var coachId: String? = nil

    var isSharedWithCoach: Bool { sharedWithCoach == true }
    var isFromCoach: Bool { createdByCoach == true }

    enum CodingKeys: String, CodingKey {
        case id, userId, title, type, emoji, progress, createdAt, successMeasure, order, sharedWithCoach, createdByCoach, coachId
    }
}

struct GoalReflection: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var goalId: String
    var userId: String
    var text: String
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, goalId, userId, text, createdAt
    }
}
