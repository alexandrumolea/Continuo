import Foundation
import FirebaseFirestore

struct CoachingSession: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var sessionDate: Date
    var conclusions: String   // optional — may be empty
    var actions: String       // optional — may be empty
    var gpEarned: Int
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, userId, sessionDate, conclusions, actions, gpEarned, createdAt
    }
}
