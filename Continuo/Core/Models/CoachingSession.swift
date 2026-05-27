import Foundation
import FirebaseFirestore

struct CoachingSession: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String          // client uid
    var coachId: String?        // nil = client-logged; non-nil = coach-logged
    var sessionDate: Date
    var summary: String?        // optional → backward compat with old docs
    var conclusions: String
    var actions: String
    var gpEarned: Int
    var createdAt: Date

    /// True when a coach created this entry on behalf of the client.
    var isCoachLogged: Bool { coachId != nil }
    /// Safe accessor — never nil at display time.
    var summaryText: String { summary ?? "" }

    enum CodingKeys: String, CodingKey {
        case id, userId, coachId, sessionDate, summary, conclusions, actions, gpEarned, createdAt
    }
}
