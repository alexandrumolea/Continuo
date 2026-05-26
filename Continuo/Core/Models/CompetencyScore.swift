import Foundation
import FirebaseFirestore

struct CompetencyScore: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var competencyId: String
    var points: Int          // already-decayed value at time of last write
    var lastActivityDate: Date

    enum CodingKeys: String, CodingKey {
        case id, userId, competencyId, points, lastActivityDate
    }

    /// Applies 1-point/day decay since last activity. Never goes below 0.
    var effectivePoints: Int {
        let days = Calendar.current.dateComponents([.day], from: lastActivityDate, to: Date()).day ?? 0
        return max(0, points - days)
    }
}
