import Foundation
import SwiftUI
import FirebaseFirestore

enum JourneyEventType: String, Codable {
    case habitCompleted          = "habit_completed"
    case sessionLogged           = "session_logged"
    case skillLevelUp            = "skill_level_up"
    case objectiveUpdated        = "objective_updated"
    case reflectionLogged        = "reflection_logged"
    case gpEarned                = "gp_earned"
    case dailyPracticeCompleted  = "daily_practice_completed"
}

struct JourneyEvent: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var type: JourneyEventType
    var title: String
    var subtitle: String
    var gpEarned: Int
    var createdAt: Date
    // Optional — only set for dailyPracticeCompleted events
    var practiceId: String? = nil
    var responses: [String]? = nil

    // Computed helpers — not persisted
    var systemIcon: String {
        switch type {
        case .habitCompleted:         return "checkmark.circle.fill"
        case .sessionLogged:          return "person.2.fill"
        case .skillLevelUp:           return "arrow.up.circle.fill"
        case .objectiveUpdated:       return "target"
        case .reflectionLogged:       return "heart.fill"
        case .gpEarned:               return "star.fill"
        case .dailyPracticeCompleted: return "sun.max.fill"
        }
    }

    var iconColor: Color {
        switch type {
        case .habitCompleted:         return Color(hex: "7E8F4B")
        case .sessionLogged:          return Color(hex: "6E443C")
        case .skillLevelUp:           return Color(hex: "FFAF2E")
        case .objectiveUpdated:       return Color(hex: "7E8F4B")
        case .reflectionLogged:       return .pink
        case .gpEarned:               return Color(hex: "FFAF2E")
        case .dailyPracticeCompleted: return Color(hex: "F5C23A")
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, userId, type, title, subtitle, gpEarned, createdAt, practiceId, responses
    }
}
