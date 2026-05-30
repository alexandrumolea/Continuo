import Foundation
import FirebaseFirestore

enum UserRole: String, Codable, CaseIterable {
    case client = "client"
    case coach  = "coach"

    var displayName: String {
        switch self {
        case .client: return "Client"
        case .coach:  return "Coach"
        }
    }
    var icon: String {
        switch self {
        case .client: return "person.fill"
        case .coach:  return "person.2.fill"
        }
    }
}

struct ContinuoUser: Identifiable, Codable {
    @DocumentID var id: String?
    var displayName: String
    var email: String
    var role: UserRole
    var coachId: String?
    var totalGP: Int
    /// `false` for social-auth users until they finish the welcome flow (pick name + role).
    /// `nil` for legacy profiles created before this field existed — treated as "complete".
    var setupCompleted: Bool? = nil

    enum CodingKeys: String, CodingKey {
        case id, displayName, email, role, coachId, totalGP, setupCompleted
    }
}
