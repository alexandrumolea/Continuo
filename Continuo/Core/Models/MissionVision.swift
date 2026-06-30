import Foundation
import FirebaseFirestore

/// A user's mission & vision statement. Stored as a single document per user
/// (document ID == userId), unlike the list-based Core items (values, strengths…).
struct MissionVision: Codable {
    var userId: String
    var mission: String
    var vision: String
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case userId, mission, vision, updatedAt
    }

    var isEmpty: Bool {
        mission.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        vision.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
