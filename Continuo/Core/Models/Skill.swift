import Foundation
import SwiftUI
import FirebaseFirestore

enum SkillTier: String, Equatable {
    case beginner     = "Beginner"
    case intermediate = "Intermediate"
    case advanced     = "Advanced"
    case master       = "Master"

    var color: Color {
        switch self {
        case .beginner:     return Color(hex: "7E8F4B")
        case .intermediate: return Color(hex: "FFAF2E")
        case .advanced:     return Color(hex: "6E443C")
        case .master:       return Color(hex: "3C3730")
        }
    }

    var icon: String {
        switch self {
        case .beginner:     return "leaf.fill"
        case .intermediate: return "flame.fill"
        case .advanced:     return "bolt.fill"
        case .master:       return "star.fill"
        }
    }

    var gpBonus: Int {
        switch self {
        case .beginner:     return 0
        case .intermediate: return 15
        case .advanced:     return 25
        case .master:       return 50
        }
    }
}

struct Skill: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var name: String
    var progress: Double   // 0.0 → 1.0
    var createdAt: Date

    // Computed — not persisted in Firestore
    var tier: SkillTier {
        switch progress {
        case 0.90...: return .master
        case 0.70...: return .advanced
        case 0.40...: return .intermediate
        default:      return .beginner
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, userId, name, progress, createdAt
    }
}
