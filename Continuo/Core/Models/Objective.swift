import Foundation
import FirebaseFirestore

enum ObjectiveCategory: String, Codable, CaseIterable {
    case career        = "Career"
    case personal      = "Personal"
    case health        = "Health"
    case relationships = "Relationships"

    var emoji: String {
        switch self {
        case .career:        return "💼"
        case .personal:      return "🌱"
        case .health:        return "💪"
        case .relationships: return "❤️"
        }
    }

    var color: String {
        switch self {
        case .career:        return "FFAF2E"
        case .personal:      return "7E8F4B"
        case .health:        return "6E443C"
        case .relationships: return "E07B7B"
        }
    }
}

struct Objective: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var title: String
    var category: ObjectiveCategory
    var progress: Double     // 0.0 → 1.0
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, userId, title, category, progress, createdAt
    }
}
